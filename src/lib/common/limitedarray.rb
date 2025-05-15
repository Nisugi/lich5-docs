# A module containing core Lich functionality
# @author Lich5 Documentation Generator
module Lich

  # Common utilities and classes used throughout Lich
  module Common

    # An Array subclass that automatically limits its size by removing oldest elements
    # when maximum size is reached
    #
    # @author Lich5 Documentation Generator
    class LimitedArray < Array
      # Maximum number of elements allowed in the array
      # @return [Integer] The maximum size limit
      attr_accessor :max_size

      # Creates a new LimitedArray with specified size and default object
      #
      # @param size [Integer] Initial size of the array (default: 0)
      # @param obj [Object] Default object to fill array with (default: nil)
      # @return [LimitedArray] A new limited array instance
      # @example
      #   arr = LimitedArray.new(5)
      #   arr = LimitedArray.new(3, "default")
      #
      # @note Always sets max_size to 200 regardless of initial size parameter
      def initialize(size = 0, obj = nil)
        @max_size = 200
        super
      end

      # Adds an element to the end of the array, removing oldest elements if max_size reached
      #
      # @param line [Object] The element to add to the array
      # @return [LimitedArray] The array with the new element added
      # @example
      #   arr = LimitedArray.new
      #   arr.push("new element") 
      #
      # @note Will remove elements from the beginning of the array if max_size would be exceeded
      def push(line)
        self.shift while self.length >= @max_size
        super
      end

      # Alias for push - adds an element while maintaining size limit
      #
      # @param line [Object] The element to add to the array
      # @return [LimitedArray] The array with the new element added
      # @example
      #   arr = LimitedArray.new
      #   arr.shove("new element")
      #
      # @note Functionally identical to push method
      def shove(line)
        push(line)
      end

      # Returns an empty array (placeholder method)
      #
      # @return [Array] An empty array
      # @example
      #   arr = LimitedArray.new
      #   arr.history #=> []
      #
      # @note This appears to be a placeholder method that always returns an empty array
      def history
        Array.new
      end
    end
  end
end