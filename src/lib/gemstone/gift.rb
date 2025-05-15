# frozen_string_literal: true

# Lich is the main namespace module for the Lich game scripting system
#
# @author Lich5 Documentation Generator
module Lich

  # Gemstone module contains classes specific to the Gemstone IV game
  module Gemstone

    # Gift class tracks and manages gift box status and timing
    # Used to monitor the gift box feature which pulses every minute up to 360 times
    class Gift
      class << self
        # Gets the timestamp when the gift box tracking started
        #
        # @return [Time] The time when the gift box was started
        attr_reader :gift_start

        # Gets the current count of gift box pulses
        #
        # @return [Integer] Number of pulses that have occurred
        attr_reader :pulse_count

        # Initializes the gift box tracking with a start time and zero pulse count
        #
        # @return [void]
        # @example
        #   Gift.init_gift
        def init_gift
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Marks the start of gift box tracking by setting start time and resetting pulse count
        #
        # @return [void]
        # @example
        #   Gift.started
        def started
          @gift_start = Time.now
          @pulse_count = 0
        end

        # Increments the pulse counter by 1
        #
        # @return [Integer] The new pulse count after incrementing
        # @example
        #   Gift.pulse
        def pulse
          @pulse_count += 1
        end

        # Calculates remaining time in seconds before gift box expires
        #
        # @return [Float] Seconds remaining before expiration (max 21600, min 0)
        # @example
        #   remaining = Gift.remaining # => 12360.0
        def remaining
          ([360 - @pulse_count, 0].max * 60).to_f
        end

        # Calculates when the gift box will restart
        # Gift boxes restart after 165 hours (594000 seconds)
        #
        # @return [Time] Timestamp when the gift box will be available again
        # @example
        #   next_start = Gift.restarts_on
        def restarts_on
          @gift_start + 594000
        end

        # Serializes the gift box state for persistence
        #
        # @return [Array<Time, Integer>] Array containing start time and pulse count
        # @example
        #   state = Gift.serialize
        def serialize
          [@gift_start, @pulse_count]
        end

        # Loads a previously serialized gift box state
        #
        # @param array [Array<Time, Integer>] Array containing start time and pulse count
        # @return [void]
        # @example
        #   Gift.load_serialized = [Time.now, 120]
        def load_serialized=(array)
          @gift_start = array[0]
          @pulse_count = array[1].to_i
        end

        # Marks the gift box as ended by setting pulse count to maximum
        #
        # @return [void]
        # @example
        #   Gift.ended
        def ended
          @pulse_count = 360
        end

        # Placeholder method for stopwatch functionality
        #
        # @return [nil] Always returns nil
        # @note This appears to be a stub method for future implementation
        def stopwatch
          nil
        end
      end

      # Initialize the class
      init_gift
    end
  end
end