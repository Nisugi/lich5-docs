# frozen_string_literal: true

# Replacement for the venerable infomon.lic script used in Lich4 and Lich5 (03/01/23)
# Supports Ruby 3.X builds
#
#     maintainer: elanthia-online
#   contributors: Tillmen, Shaelun, Athias
#           game: Gemstone
#           tags: core
#       required: Lich > 5.6.2
#        version: 2.0
#         Source: https://github.com/elanthia-online/scripts

require 'sequel'
require 'tmpdir'
require 'logger'
require_relative 'infomon/cache'

# A core module for managing persistent character information and stats in the Gemstone game.
# Provides a SQLite-backed key-value store with caching capabilities.
#
# @author elanthia-online
# @since 2.0
module Lich
  module Gemstone
    module Infomon
      # @return [Boolean] Debug mode flag
      $infomon_debug = ENV["DEBUG"]
      # use temp dir in ci context
      @root = defined?(DATA_DIR) ? DATA_DIR : Dir.tmpdir
      @file = File.join(@root, "infomon.db")
      @db   = Sequel.sqlite(@file)
      @cache ||= Infomon::Cache.new
      @cache_loaded = false
      @db.loggers << Logger.new($stdout) if ENV["DEBUG"]
      @sql_queue ||= Queue.new
      @sql_mutex ||= Mutex.new

      # Returns the cache instance
      #
      # @return [Infomon::Cache] The cache object used for storing key-value pairs
      # @example
      #   Infomon.cache.get("strength")
      def self.cache
        @cache
      end

      # Returns the database file path
      #
      # @return [String] Path to the SQLite database file
      def self.file
        @file
      end

      # Returns the Sequel database connection
      #
      # @return [Sequel::Database] The SQLite database connection
      def self.db
        @db
      end

      # Returns the mutex used for thread synchronization
      #
      # @return [Mutex] The mutex object
      def self.mutex
        @sql_mutex
      end

      # Acquires the mutex lock for thread-safe operations
      #
      # @raise [StandardError] If mutex acquisition fails
      # @note Logs errors to Lich's error log
      def self.mutex_lock
        begin
          self.mutex.lock unless self.mutex.owned?
        rescue StandardError
          respond "--- Lich: error: Infomon.mutex_lock: #{$!}"
          Lich.log "error: Infomon.mutex_lock: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end

      # Releases the mutex lock
      #
      # @raise [StandardError] If mutex release fails
      # @note Logs errors to Lich's error log
      def self.mutex_unlock
        begin
          self.mutex.unlock if self.mutex.owned?
        rescue StandardError
          respond "--- Lich: error: Infomon.mutex_unlock: #{$!}"
          Lich.log "error: Infomon.mutex_unlock: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end

      # Returns the SQL command queue
      #
      # @return [Queue] Queue containing pending SQL operations
      def self.queue
        @sql_queue
      end

      # Validates the current context requires XMLData.name to be present
      #
      # @raise [RuntimeError] If XMLData.name is empty or nil
      # @note Essential for maintaining data integrity per character
      def self.context!
        return unless XMLData.name.empty? or XMLData.name.nil?
        puts Exception.new.backtrace
        fail "cannot access Infomon before XMLData.name is loaded"
      end

      # Generates the table name for the current character
      #
      # @return [Symbol] Table name in format "game_charactername"
      # @raise [RuntimeError] If XMLData.name is not available
      def self.table_name
        self.context!
        ("%s_%s" % [XMLData.game, XMLData.name]).to_sym
      end

      # Resets the database table and cache for the current character
      #
      # @note This is a destructive operation that clears all stored data
      def self.reset!
        self.mutex_lock
        Infomon.db.drop_table?(self.table_name)
        self.cache.clear
        @cache_loaded = false
        Infomon.setup!
      end

      # Returns or creates the database table for the current character
      #
      # @return [Sequel::Dataset] The database table object
      def self.table
        @_table ||= self.setup!
      end

      def self.setup!
        self.mutex_lock
        @db.create_table?(self.table_name) do
          text :key, primary_key: true
          any :value
        end
        self.mutex_unlock
        @_table = @db[self.table_name]
      end

      # Loads the cache from the database
      #
      # @note Waits for XMLData.name to be available
      # @note Sets @cache_loaded flag when complete
      def self.cache_load
        sleep(0.01) if XMLData.name.empty?
        dataset = Infomon.table
        h = Hash[dataset.map(:key).zip(dataset.map(:value))]
        self.cache.merge!(h)
        @cache_loaded = true
      end

      # Normalizes keys for consistent storage
      #
      # @param key [String, Symbol] The key to normalize
      # @return [String] Normalized key with spaces/hyphens converted to underscores
      # @example
      #   Infomon._key("Max-Health") #=> "max_health"
      def self._key(key)
        key = key.to_s.downcase
        key.tr!(' ', '_').gsub!('_-_', '_').tr!('-', '_') if /\s|-/.match?(key)
        return key
      end

      # Normalizes values for storage
      #
      # @param val [Object] Value to normalize
      # @return [Object] Normalized value with special handling for boolean strings
      # @example
      #   Infomon._value("true") #=> true
      def self._value(val)
        return true if val.to_s == "true"
        return false if val.to_s == "false"
        return val
      end

      # Validates value types for storage
      #
      # @param key [String] The key being stored
      # @param value [Object] The value to validate
      # @return [Object] The validated value
      # @raise [RuntimeError] If value type is not allowed
      # @note Allowed types are Integer, String, NilClass, FalseClass, TrueClass
      AllowedTypes = [Integer, String, NilClass, FalseClass, TrueClass]
      def self._validate!(key, value)
        return self._value(value) if AllowedTypes.include?(value.class)
        raise "infomon:insert(%s) was called with %s\nmust be %s\nvalue=%s" % [key, value.class, AllowedTypes.map(&:name).join("|"), value]
      end

      # Retrieves a value from the cache/database
      #
      # @param key [String, Symbol] The key to look up
      # @return [Object, nil] The stored value or nil if not found
      # @example
      #   Infomon.get("strength") #=> 100
      def self.get(key)
        self.cache_load if !@cache_loaded
        key = self._key(key)
        val = self.cache.get(key) {
          sleep 0.01 until self.queue.empty?
          begin
            self.mutex.synchronize do
              begin
                db_result = self.table[key: key]
                if db_result
                  db_result[:value]
                else
                  nil
                end
              rescue => exception
                pp(exception)
                nil
              end
            end
          rescue StandardError
            respond "--- Lich: error: Infomon.get(#{key}): #{$!}"
            Lich.log "error: Infomon.get(#{key}): #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          end
        }
        return self._value(val)
      end

      # Retrieves a boolean value with type conversion
      #
      # @param key [String, Symbol] The key to look up
      # @return [Boolean] The stored value converted to boolean
      # @example
      #   Infomon.get_bool("is_standing") #=> true
      def self.get_bool(key)
        value = Infomon.get(key)
        if value.is_a?(TrueClass) || value.is_a?(FalseClass)
          return value
        elsif value == 1
          return true
        else
          return false
        end
      end

      def self.upsert(*args)
        self.table
            .insert_conflict(:replace)
            .insert(*args)
      end

      # Sets a key-value pair in the cache and queues database update
      #
      # @param key [String, Symbol] The key to store
      # @param value [Object] The value to store
      # @return [Symbol] :noop if value unchanged, nil otherwise
      # @raise [RuntimeError] If value type is invalid
      # @example
      #   Infomon.set("strength", 100)
      def self.set(key, value)
        key = self._key(key)
        value = self._validate!(key, value)
        return :noop if self.cache.get(key) == value
        self.cache.put(key, value)
        self.queue << "INSERT OR REPLACE INTO %s (`key`, `value`) VALUES (%s, %s)
      on conflict(`key`) do update set value = excluded.value;" % [self.db.literal(self.table_name), self.db.literal(key), self.db.literal(value)]
      end

      # Deletes a key-value pair from cache and database
      #
      # @param key [String, Symbol] The key to delete
      # @example
      #   Infomon.delete!("temporary_stat")
      def self.delete!(key)
        key = self._key(key)
        self.cache.delete(key)
        self.queue << "DELETE FROM %s WHERE key = (%s);" % [self.db.literal(self.table_name), self.db.literal(key)]
      end

      # Batch updates multiple key-value pairs
      #
      # @param blob [Array<Hash>] Array of key-value pair hashes to update
      # @return [Symbol] :noop if no changes needed
      # @raise [RuntimeError] If value types are invalid
      # @note Only works with Integer and String values
      # @example
      #   Infomon.upsert_batch({strength: 100, dexterity: 90})
      def self.upsert_batch(*blob)
        updated = (blob.first.map { |k, v| [self._key(k), self._validate!(k, v)] } - self.cache.to_a)
        return :noop if updated.empty?
        pairs = updated.map { |key, value|
          (value.is_a?(Integer) or value.is_a?(String)) or fail "upsert_batch only works with Integer or String types"
          # add the value to the cache
          self.cache.put(key, value)
          %[(%s, %s)] % [self.db.literal(key), self.db.literal(value)]
        }.join(", ")
        # queue sql statement to run async
        self.queue << "INSERT OR REPLACE INTO %s (`key`, `value`) VALUES %s
      on conflict(`key`) do update set value = excluded.value;" % [self.db.literal(self.table_name), pairs]
      end

      Thread.new do
        loop do
          sql_statement = Infomon.queue.pop
          begin
            Infomon.mutex.synchronize do
              begin
                Infomon.db.run(sql_statement)
              rescue StandardError => e
                pp(e)
              end
            end
          rescue StandardError
            respond "--- Lich: error: Infomon ThreadQueue: #{$!}"
            Lich.log "error: Infomon ThreadQueue: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          end
        end
      end

      require_relative 'infomon/parser'
      require_relative 'infomon/xmlparser'
      require_relative 'infomon/cli'
    end
  end
end