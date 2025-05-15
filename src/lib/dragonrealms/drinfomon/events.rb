# A module containing DragonRealms game-specific functionality
# @author Lich5 Documentation Generator
module Lich

  # Contains DragonRealms-specific game functionality and utilities
  module DragonRealms

    # Manages boolean flags and their associated pattern matchers
    # Used for tracking game state and conditions based on text patterns
    class Flags
      @@flags = {}
      @@matchers = {}

      # Gets the value of a flag
      #
      # @param key [Symbol, String] The flag identifier
      # @return [Boolean] The current value of the flag
      # @example
      #   Flags[:stunned] #=> false
      def self.[](key)
        @@flags[key]
      end

      # Sets the value of a flag
      #
      # @param key [Symbol, String] The flag identifier
      # @param value [Boolean] The value to set
      # @return [Boolean] The new value
      # @example
      #   Flags[:stunned] = true
      def self.[]=(key, value)
        @@flags[key] = value
      end

      # Adds a new flag with associated pattern matchers
      #
      # @param key [Symbol, String] The flag identifier
      # @param matchers [Array<String, Regexp>] One or more patterns to match
      # @return [Array<Regexp>] The compiled matchers
      # @example
      #   Flags.add(:stunned, "You are stunned", /You feel dizzy/)
      #
      # @note String matchers are converted to case-insensitive regexps
      def self.add(key, *matchers)
        @@flags[key] = false
        @@matchers[key] = matchers.map { |item| item.is_a?(Regexp) ? item : /#{item}/i }
      end

      # Resets a flag to false
      #
      # @param key [Symbol, String] The flag identifier
      # @return [Boolean] Always returns false
      # @example
      #   Flags.reset(:stunned)
      def self.reset(key)
        @@flags[key] = false
      end

      # Removes a flag and its matchers
      #
      # @param key [Symbol, String] The flag identifier
      # @return [nil]
      # @example
      #   Flags.delete(:stunned)
      def self.delete(key)
        @@matchers.delete key
        @@flags.delete key
      end

      # Gets the hash of all flags and their values
      #
      # @return [Hash{Symbol => Boolean}] Hash of flag names to boolean values
      # @example
      #   Flags.flags #=> {:stunned => false, :webbed => true}
      def self.flags
        @@flags
      end

      # Gets the hash of all flags and their pattern matchers
      #
      # @return [Hash{Symbol => Array<Regexp>}] Hash of flag names to arrays of matchers
      # @example
      #   Flags.matchers #=> {:stunned => [/You are stunned/i]}
      def self.matchers
        @@matchers
      end
    end
  end
end