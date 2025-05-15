# Carve out from lich.rbw
# extension to StringProc class 2024-06-13

module Lich
  module Common
    # A class that processes strings as Ruby code.
    class StringProc
      # Initializes a new StringProc instance with the given string.
      #
      # @param string [String] the string to be processed as Ruby code
      def initialize(string)
        @string = string
      end

      # Checks if the current object is of the specified type.
      #
      # @param type [Class] the class to check against
      # @return [Boolean] true if the object is of the specified type, false otherwise
      def kind_of?(type)
        Proc.new {}.kind_of? type
      end

      # Returns the class of the current object.
      #
      # @return [Class] the class of the object, which is Proc
      def class
        Proc
      end

      # Calls the stored string as Ruby code.
      #
      # @param _a [Array] optional arguments (not used)
      # @return [Object] the result of evaluating the string
      # @raise [SyntaxError] if the string contains invalid Ruby code
      # @example
      #   sp = StringProc.new("1 + 1")
      #   sp.call # => 2
      def call(*_a)
        proc { eval(@string) }.call
      end

      # Dumps the string representation of the object.
      #
      # @param _d [nil] optional parameter (not used)
      # @return [String] the string representation of the object
      def _dump(_d = nil)
        @string
      end

      # Returns a string representation of the StringProc object.
      #
      # @return [String] a string describing the StringProc instance
      def inspect
        "StringProc.new(#{@string.inspect})"
      end

      # Converts the StringProc object to JSON format.
      #
      # @param args [Array] optional arguments for JSON conversion
      # @return [String] the JSON representation of the object
      # @example
      #   sp = StringProc.new("1 + 1")
      #   sp.to_json # => ";e \"1 + 1\""
      def to_json(*args)
        ";e #{_dump}".to_json(args)
      end

      # Loads a StringProc object from a string.
      #
      # @param string [String] the string to load
      # @return [StringProc] a new StringProc instance initialized with the string
      # @example
      #   sp = StringProc._load("1 + 1")
      #   sp.call # => 2
      def StringProc._load(string)
        StringProc.new(string)
      end
    end
  end
end
