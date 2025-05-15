# frozen_string_literal: true

module Lich
  module Gemstone
    # Gift class for tracking gift box status
    class Gift
      class << self
        # Returns the start time of the gift and the pulse count.
        #
        # @return [Time] the time when the gift was started
        # @return [Integer] the current pulse count, initialized to 0
        #
        # @example
        #   Gift.init_gift
        #   # => Initializes the gift with the current time and pulse count set to 0
        def init_gift
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Starts the gift timer and resets the pulse count.
        #
        # @return [Time] the time when the gift was started
        # @return [Integer] the pulse count, reset to 0
        #
        # @example
        #   Gift.started
        #   # => Starts the gift timer and resets pulse count
        def started
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Increments the pulse count by one.
        #
        # @return [Integer] the updated pulse count after increment
        #
        # @example
        #   Gift.pulse
        #   # => Increments the pulse count by 1
        def pulse
          @pulse_count += 1
        end

        # Calculates the remaining time in seconds based on the pulse count.
        #
        # @return [Float] the remaining time in seconds
        #
        # @example
        #   Gift.remaining
        #   # => Returns the remaining time in seconds based on pulse count
        def remaining
          ([360 - @pulse_count, 0].max * 60).to_f
        end

        # Calculates the time when the gift will restart.
        #
        # @return [Time] the time when the gift restarts
        #
        # @example
        #   Gift.restarts_on
        #   # => Returns the time when the gift will restart
        def restarts_on
          @gift_start + 594000
        end

        # Serializes the current state of the gift.
        #
        # @return [Array] an array containing the gift start time and pulse count
        #
        # @example
        #   Gift.serialize
        #   # => Returns an array with the gift start time and pulse count
        def serialize
          [@gift_start, @pulse_count]
        end

        # Loads the serialized state of the gift from an array.
        #
        # @param array [Array] an array containing the gift start time and pulse count
        # @return [void]
        #
        # @example
        #   Gift.load_serialized = [Time.now, 5]
        #   # => Loads the serialized state into the gift
        def load_serialized=(array)
          @gift_start = array[0]
          @pulse_count = array[1].to_i
        end

        # Ends the gift by setting the pulse count to 360.
        #
        # @return [Integer] the pulse count set to 360
        #
        # @example
        #   Gift.ended
        #   # => Ends the gift by setting pulse count to 360
        def ended
          @pulse_count = 360
        end

        # Placeholder for a stopwatch method.
        #
        # @return [nil] always returns nil
        #
        # @example
        #   Gift.stopwatch
        #   # => Returns nil
        def stopwatch
          nil
        end
      end

      # Initialize the class
      init_gift
    end
  end
end