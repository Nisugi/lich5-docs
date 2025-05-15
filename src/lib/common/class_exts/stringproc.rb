# The Lich module serves as the main namespace for the Lich game scripting system
# @author Lich5 Documentation Generator
module Lich

  # Common module containing shared functionality
  module Common

    # StringProc provides a way to store and evaluate Ruby code stored as strings.
    # It mimics the behavior of Proc objects while allowing serialization of the code.
    #
    # @author Lich5 Documentation Generator
    class StringProc

      # Creates a new StringProc instance that wraps the given Ruby code string
      #
      # @param string [String] Ruby code to be stored and evaluated later
      # @return [StringProc] New StringProc instance
      # @example
      #   proc = StringProc.new("2 + 2")
      def initialize(string)
        @string = string
      end

      # Checks if this StringProc is a kind of the specified type
      # Always delegates to Proc's kind_of? to maintain compatibility
      #
      # @param type [Class] The type to check against
      # @return [Boolean] true if compatible with the type
      # @example
      #   proc = StringProc.new("puts 'hello'")
      #   proc.kind_of?(Proc) #=> true
      def kind_of?(type)
        Proc.new {}.kind_of? type
      end

      # Returns the class of this object
      # Always returns Proc to maintain compatibility
      #
      # @return [Class] Returns Proc
      # @example
      #   proc = StringProc.new("puts 'hello'")
      #   proc.class #=> Proc
      def class
        Proc
      end

      # Evaluates the stored Ruby code string
      #
      # @param _a [Array] Ignored arguments for compatibility with Proc#call
      # @return [Object] Result of evaluating the stored code
      # @raise [StandardError] If the stored code raises an error during evaluation
      # @example
      #   proc = StringProc.new("2 + 2")
      #   proc.call #=> 4
      def call(*_a)
        proc { eval(@string) }.call
      end

      # Serializes the StringProc by returning the stored code string
      #
      # @param _d [Object] Ignored parameter for Marshal compatibility
      # @return [String] The stored Ruby code string
      # @example
      #   proc = StringProc.new("puts 'hello'")
      #   proc._dump #=> "puts 'hello'"
      def _dump(_d = nil)
        @string
      end

      # Returns a string representation of the StringProc
      #
      # @return [String] String showing the StringProc construction
      # @example
      #   proc = StringProc.new("2 + 2")
      #   proc.inspect #=> "StringProc.new(\"2 + 2\")"
      def inspect
        "StringProc.new(#{@string.inspect})"
      end

      # Converts the StringProc to JSON format
      # Prepends ";e " to the stored code for compatibility
      #
      # @param args [Array] Arguments passed to to_json
      # @return [String] JSON representation
      # @example
      #   proc = StringProc.new("2 + 2")
      #   proc.to_json #=> "\";e 2 + 2\""
      def to_json(*args)
        ";e #{_dump}".to_json(args)
      end

      # Deserializes a StringProc from a string
      #
      # @param string [String] Previously dumped Ruby code string
      # @return [StringProc] New StringProc instance with the loaded code
      # @example
      #   proc = StringProc._load("puts 'hello'")
      def StringProc._load(string)
        StringProc.new(string)
      end
    end
  end
end