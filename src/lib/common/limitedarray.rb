# Carve out from lich.rbw
# class LimitedArray 2024-06-13

module Lich
  module Common
    # A class that extends the functionality of an Array to limit its size.
    # When the maximum size is reached, the oldest elements are removed.
    class LimitedArray < Array
      attr_accessor :max_size

      # Initializes a new LimitedArray with a specified maximum size.
      #
      # @param size [Integer] the initial size of the array (default is 0)
      # @param obj [Object] the object to initialize the array with (default is nil)
      # @return [LimitedArray] a new instance of LimitedArray
      # @raise [ArgumentError] if size is negative
      # @example
      #   limited_array = Lich::Common::LimitedArray.new(5)
      def initialize(size = 0, obj = nil)
        @max_size = 200
        super
      end

      # Adds an element to the end of the array, removing the oldest elements
      # if the maximum size is exceeded.
      #
      # @param line [Object] the element to be added to the array
      # @return [Object] the element that was added
      # @note This method modifies the array in place.
      # @example
      #   limited_array.push("new item")
      def push(line)
        self.shift while self.length >= @max_size
        super
      end

      # An alias for the push method.
      #
      # @param line [Object] the element to be added to the array
      # @return [Object] the element that was added
      # @example
      #   limited_array.shove("another item")
      def shove(line)
        push(line)
      end

      # Returns an empty array representing the history of elements.
      #
      # @return [Array] an empty array
      # @example
      #   history = limited_array.history
      def history
        Array.new
      end
    end
  end
end
