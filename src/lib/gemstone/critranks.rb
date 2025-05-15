# frozen_string_literal: true

#
# module CritRanks used to resolve critical hits into their mechanical results
# queries against crit_tables files in lib/crit_tables/
# 20240625
#

#
# See generic_critical_table.rb for the general template used
#
module Lich
  module Gemstone
    module CritRanks
      @critical_table ||= {}
      @types           = []
      @locations       = []
      @ranks           = []

      #
      # Initializes the critical table by loading all critical table files.
      #
      # @return [void]
      # @note This method will only run if the critical table is empty.
      #
      # @example
      #   CritRanks.init
      #
      def self.init
        return unless @critical_table.empty?
        Dir.glob("#{File.join(LIB_DIR, "gemstone", "critranks", "*critical_table.rb")}").each do |file|
          require file
        end
        create_indices
      end

      #
      # Returns the current critical table.
      #
      # @return [Hash] the critical table containing critical hit data.
      #
      # @example
      #   table = CritRanks.table
      #
      def self.table
        @critical_table
      end

      #
      # Reloads the critical table by clearing the current data and reinitializing it.
      #
      # @return [void]
      #
      # @example
      #   CritRanks.reload!
      #
      def self.reload!
        @critical_table = {}
        init
      end

      #
      # Returns an array of types available in the critical table.
      #
      # @return [Array<String>] the types of critical hits.
      #
      # @example
      #   types = CritRanks.tables
      #
      def self.tables
        @tables = []
        @types.each do |type|
          @tables.push(type.to_s.gsub(':', ''))
        end
        @tables
      end

      #
      # Returns an array of types available in the critical table.
      #
      # @return [Array<Symbol>] the types of critical hits.
      #
      # @example
      #   types = CritRanks.types
      #
      def self.types
        @types
      end

      #
      # Returns an array of locations available in the critical table.
      #
      # @return [Array<Symbol>] the locations of critical hits.
      #
      # @example
      #   locations = CritRanks.locations
      #
      def self.locations
        @locations
      end

      #
      # Returns an array of ranks available in the critical table.
      #
      # @return [Array<Symbol>] the ranks of critical hits.
      #
      # @example
      #   ranks = CritRanks.ranks
      #
      def self.ranks
        @ranks
      end

      #
      # Cleans the provided key by converting it to a standardized format.
      #
      # @param key [Integer, Symbol, String] the key to clean.
      # @return [String, Integer] the cleaned key.
      #
      # @example
      #   cleaned_key = CritRanks.clean_key("Some Key - Example")
      #
      def self.clean_key(key)
        return key.to_i if key.is_a?(Integer) || key =~ (/^\d+$/)
        return key.downcase if key.is_a?(Symbol)

        key.strip.downcase.gsub(/[ -]/, '_')
      end

      #
      # Validates the provided key against a list of valid keys.
      #
      # @param key [String, Symbol] the key to validate.
      # @param valid [Array<String>] the list of valid keys.
      # @return [String] the cleaned key if valid.
      # @raise [RuntimeError] if the key is invalid.
      #
      # @example
      #   valid_key = CritRanks.validate(:some_key, CritRanks.types)
      #
      def self.validate(key, valid)
        clean = clean_key(key)
        raise "Invalid key '#{key}', expecting one of #{valid.join(',')}" unless valid.include?(clean)

        clean
      end

      #
      # Creates indices for types, locations, and ranks from the critical table.
      #
      # @return [void]
      #
      # @note This method is called internally during initialization.
      #
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

      #
      # Parses a line to find matches against the critical table's regex patterns.
      #
      # @param line [String] the line to parse.
      # @return [Array] an array of matches found.
      #
      # @example
      #   matches = CritRanks.parse("Some input line")
      #
      def self.parse(line)
        @index_rx.filter do |rx, _data|
          rx =~ line.strip # need to strip spaces to support anchored regex in tables
        end
      end

      #
      # Fetches the critical hit data for a given type, location, and rank.
      #
      # @param type [String, Symbol] the type of critical hit.
      # @param location [String, Symbol] the location of the critical hit.
      # @param rank [String, Symbol] the rank of the critical hit.
      # @return [Hash, nil] the critical hit data or nil if not found.
      # @raise [RuntimeError] if any of the keys are invalid.
      #
      # @example
      #   data = CritRanks.fetch(:type, :location, :rank)
      #
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