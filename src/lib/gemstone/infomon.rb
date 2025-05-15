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

module Lich
  module Gemstone
    module Infomon
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

      # Returns the cache object used by Infomon.
      #
      # @return [Infomon::Cache] the cache object
      def self.cache
        @cache
      end

      # Returns the file path for the database.
      #
      # @return [String] the file path for the database
      def self.file
        @file
      end

      # Returns the database connection.
      #
      # @return [Sequel::Database] the database connection
      def self.db
        @db
      end

      # Returns the mutex used for SQL operations.
      #
      # @return [Mutex] the mutex for SQL operations
      def self.mutex
        @sql_mutex
      end

      # Locks the mutex for thread-safe operations.
      #
      # @raise [StandardError] if an error occurs while locking
      def self.mutex_lock
        begin
          self.mutex.lock unless self.mutex.owned?
        rescue StandardError
          respond "--- Lich: error: Infomon.mutex_lock: #{$!}"
          Lich.log "error: Infomon.mutex_lock: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end

      # Unlocks the mutex for thread-safe operations.
      #
      # @raise [StandardError] if an error occurs while unlocking
      def self.mutex_unlock
        begin
          self.mutex.unlock if self.mutex.owned?
        rescue StandardError
          respond "--- Lich: error: Infomon.mutex_unlock: #{$!}"
          Lich.log "error: Infomon.mutex_unlock: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end

      # Returns the SQL queue for pending operations.
      #
      # @return [Queue] the SQL queue
      def self.queue
        @sql_queue
      end

      # Ensures that the context is valid before accessing Infomon.
      #
      # @raise [RuntimeError] if XMLData.name is not loaded
      def self.context!
        return unless XMLData.name.empty? or XMLData.name.nil?
        puts Exception.new.backtrace
        fail "cannot access Infomon before XMLData.name is loaded"
      end

      # Returns the table name based on the game and XMLData name.
      #
      # @return [Symbol] the table name
      def self.table_name
        self.context!
        ("%s_%s" % [XMLData.game, XMLData.name]).to_sym
      end

      # Resets the Infomon state by dropping the table and clearing the cache.
      #
      # @return [void]
      def self.reset!
        self.mutex_lock
        Infomon.db.drop_table?(self.table_name)
        self.cache.clear
        @cache_loaded = false
        Infomon.setup!
      end

      # Returns the table object for the Infomon database.
      #
      # @return [Sequel::Dataset] the table object
      def self.table
        @_table ||= self.setup!
      end

      # Sets up the Infomon table in the database.
      #
      # @return [Sequel::Dataset] the created table object
      def self.setup!
        self.mutex_lock
        @db.create_table?(self.table_name) do
          text :key, primary_key: true
          any :value
        end
        self.mutex_unlock
        @_table = @db[self.table_name]
      end

      # Loads the cache from the database.
      #
      # @return [void]
      # @note This method will sleep for a short duration if XMLData.name is not loaded.
      def self.cache_load
        sleep(0.01) if XMLData.name.empty?
        dataset = Infomon.table
        h = Hash[dataset.map(:key).zip(dataset.map(:value))]
        self.cache.merge!(h)
        @cache_loaded = true
      end

      # Normalizes the key by converting it to a string and formatting it.
      #
      # @param key [Object] the key to normalize
      # @return [String] the normalized key
      def self._key(key)
        key = key.to_s.downcase
        key.tr!(' ', '_').gsub!('_-_', '_').tr!('-', '_') if /\s|-/.match?(key)
        return key
      end

      # Normalizes the value to a boolean or returns the original value.
      #
      # @param val [Object] the value to normalize
      # @return [Boolean, Object] the normalized value
      def self._value(val)
        return true if val.to_s == "true"
        return false if val.to_s == "false"
        return val
      end

      AllowedTypes = [Integer, String, NilClass, FalseClass, TrueClass]
      # Validates the key and value types for insertion.
      #
      # @param key [String] the key to validate
      # @param value [Object] the value to validate
      # @return [Object] the validated value
      # @raise [RuntimeError] if the value type is not allowed
      def self._validate!(key, value)
        return self._value(value) if AllowedTypes.include?(value.class)
        raise "infomon:insert(%s) was called with %s\nmust be %s\nvalue=%s" % [key, value.class, AllowedTypes.map(&:name).join("|"), value]
      end

      # Retrieves a value from the cache or database.
      #
      # @param key [Object] the key to retrieve
      # @return [Boolean, Integer, String, NilClass] the retrieved value
      # @raise [StandardError] if an error occurs during retrieval
      # @example
      #   value = Infomon.get("some_key")
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

      # Retrieves a boolean value from the cache or database.
      #
      # @param key [Object] the key to retrieve
      # @return [Boolean] the retrieved boolean value
      # @example
      #   is_enabled = Infomon.get_bool("feature_enabled")
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

      # Inserts or updates a record in the database.
      #
      # @param args [Array] the arguments for the insert operation
      # @return [void]
      def self.upsert(*args)
        self.table
            .insert_conflict(:replace)
            .insert(*args)
      end

      # Sets a key-value pair in the cache and database.
      #
      # @param key [Object] the key to set
      # @param value [Object] the value to set
      # @return [Symbol] :noop if the value is unchanged, otherwise performs the operation
      # @raise [RuntimeError] if the value type is not valid
      # @example
      #   Infomon.set("some_key", "some_value")
      def self.set(key, value)
        key = self._key(key)
        value = self._validate!(key, value)
        return :noop if self.cache.get(key) == value
        self.cache.put(key, value)
        self.queue << "INSERT OR REPLACE INTO %s (`key`, `value`) VALUES (%s, %s)
      on conflict(`key`) do update set value = excluded.value;" % [self.db.literal(self.table_name), self.db.literal(key), self.db.literal(value)]
      end

      # Deletes a key from the cache and database.
      #
      # @param key [Object] the key to delete
      # @return [void]
      # @example
      #   Infomon.delete!("some_key")
      def self.delete!(key)
        key = self._key(key)
        self.cache.delete(key)
        self.queue << "DELETE FROM %s WHERE key = (%s);" % [self.db.literal(self.table_name), self.db.literal(key)]
      end

      # Inserts or updates multiple records in the database.
      #
      # @param blob [Array] an array of key-value pairs to upsert
      # @return [Symbol] :noop if no updates are made
      # @raise [RuntimeError] if the value type is not valid
      # @example
      #   Infomon.upsert_batch([["key1", "value1"], ["key2", "value2"]])
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