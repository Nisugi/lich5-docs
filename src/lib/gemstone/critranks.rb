# frozen_string_literal: true

# Module for handling critical hit resolution in the Gemstone game system.
# Manages critical hit tables and provides lookup functionality for determining
# critical hit results based on type, location, and rank.
#
# @author Lich5 Documentation Generator
module Lich
  module Gemstone
    module CritRanks
      @critical_table ||= {}
      @types           = []
      @locations       = []
      @ranks          = []

      # Initializes the critical hit tables by loading all *critical_table.rb files
      # from the critranks directory and creating necessary indices.
      #
      # @return [void]
      # @note Only initializes if the critical table is empty
      def self.init
        return unless @critical_table.empty?
        Dir.glob("#{File.join(LIB_DIR, "gemstone", "critranks", "*critical_table.rb")}").each do |file|
          require file
        end
        create_indices
      end

      # Returns the current critical hit table hash
      #
      # @return [Hash] The complete critical hit table data structure
      def self.table
        @critical_table
      end

      # Reloads all critical hit tables by clearing existing data and reinitializing
      #
      # @return [void]
      def self.reload!
        @critical_table = {}
        init
      end

      # Returns a list of available critical hit table names
      #
      # @return [Array<String>] List of table names with colons removed
      # @example
      #   CritRanks.tables #=> ["crushing", "slashing", "piercing"]
      def self.tables
        @tables = []
        @types.each do |type|
          @tables.push(type.to_s.gsub(':', ''))
        end
        @tables
      end

      # Returns the list of valid critical hit types
      #
      # @return [Array<Symbol>] List of critical hit types
      def self.types
        @types
      end

      # Returns the list of valid hit locations
      #
      # @return [Array<Symbol>] List of body locations for critical hits
      def self.locations
        @locations
      end

      # Returns the list of valid critical hit ranks
      #
      # @return [Array<Symbol,Integer>] List of critical hit rank values
      def self.ranks
        @ranks
      end

      # Normalizes input keys by converting to proper format
      #
      # @param key [String,Symbol,Integer] The key to clean
      # @return [String,Integer] Normalized key value
      # @example
      #   CritRanks.clean_key("Head-Shot") #=> "head_shot"
      #   CritRanks.clean_key("123") #=> 123
      def self.clean_key(key)
        return key.to_i if key.is_a?(Integer) || key =~ (/^\d+$/)
        return key.downcase if key.is_a?(Symbol)

        key.strip.downcase.gsub(/[ -]/, '_')
      end

      # Validates that a given key exists in the valid options list
      #
      # @param key [String,Symbol,Integer] The key to validate
      # @param valid [Array] List of valid values
      # @return [String,Integer] The cleaned, validated key
      # @raise [RuntimeError] If key is not in valid list
      # @example
      #   CritRanks.validate("head", [:head, :torso]) #=> :head
      def self.validate(key, valid)
        clean = clean_key(key)
        raise "Invalid key '#{key}', expecting one of #{valid.join(',')}" unless valid.include?(clean)

        clean
      end

      # Creates lookup indices for critical hit records
      #
      # @return [void]
      # @note Builds @types, @locations, @ranks, and regex lookup tables
      def self.create_indices
        @index_rx ||= {}
        @critical_table.each do |type, typedata|
          @types.append(type)
          typedata.each do |loc, locdata|
            @locations.append(loc) unless @locations.include?(loc)
            locdata.each do |rank, record|
              @ranks.append(rank) unless @ranks.include?(rank)
              @index_rx[record[:regex]] = record
            end
          end
        end
      end

      # Parses a line of text to find matching critical hit results
      #
      # @param line [String] The text line to parse
      # @return [Hash] Matching critical hit records
      # @example
      #   CritRanks.parse("You score a solid hit to the head!")
      def self.parse(line)
        @index_rx.filter do |rx, _data|
          rx =~ line.strip # need to strip spaces to support anchored regex in tables
        end
      end

      # Retrieves a specific critical hit record
      #
      # @param type [String,Symbol] The critical hit type (crushing, slashing, etc)
      # @param location [String,Symbol] The hit location (head, torso, etc)
      # @param rank [String,Integer] The critical hit rank
      # @return [Hash,nil] The critical hit record if found
      # @raise [RuntimeError] If any parameter is invalid
      # @example
      #   CritRanks.fetch(:crushing, :head, 5)
      # @note Returns nil and logs error if lookup fails
      def self.fetch(type, location, rank)
        table.dig(
          validate(type, types),
          validate(location, locations),
          validate(rank, ranks)
        )
      rescue StandardError => e
        Lich::Messaging.msg('error', "Error! #{e}")
      end
      # startup
      init
    end
  end
end