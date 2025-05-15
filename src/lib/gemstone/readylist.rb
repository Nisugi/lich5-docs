module Lich
  module Gemstone
    # Represents a list of ready items in the game.
    class ReadyList
      @checked = false
      @ready_list = {
        shield: nil,
        weapon: nil,
        secondary_weapon: nil,
        ranged_weapon: nil,
        ammo_bundle: nil,
        ammo2_bundle: nil,
        sheath: nil,
        secondary_sheath: nil,
      }

      # Define class-level accessors for ready list entries
      # @note This dynamically creates getter and setter methods for each item in the ready list.
      @ready_list.each_key do |type|
        define_singleton_method(type) { @ready_list[type] }
        define_singleton_method("#{type}=") { |value| @ready_list[type] = value }
      end

      class << self
        # Returns the current ready list.
        # @return [Hash] the current state of the ready list.
        # @example
        #   Lich::Gemstone::ReadyList.ready_list
        def ready_list
          @ready_list
        end

        # Checks if the ready list has been validated.
        # @return [Boolean] true if the ready list has been checked, false otherwise.
        # @example
        #   Lich::Gemstone::ReadyList.checked?
        def checked?
          @checked
        end

        # Sets the checked state of the ready list.
        # @param value [Boolean] the new checked state.
        # @return [Boolean] the new checked state.
        # @example
        #   Lich::Gemstone::ReadyList.checked = true
        def checked=(value)
          @checked = value
        end

        # Validates the items in the ready list.
        # @return [Boolean] true if all items are valid, false otherwise.
        # @note If any item is invalid, the checked state will be reset to false.
        # @example
        #   Lich::Gemstone::ReadyList.valid?
        def valid?
          # check if existing ready items are valid or not
          return false unless checked?
          @ready_list.each_value do |value|
            unless value.nil? || GameObj.inv.map(&:id).include?(value.id) || GameObj.containers.values.flatten.map(&:id).include?(value.id)
              @checked = false
              return false
            end
          end
          return true
        end

        # Resets the ready list and its checked state.
        # @return [void]
        # @example
        #   Lich::Gemstone::ReadyList.reset
        def reset
          @checked = false
          @ready_list.each_key do |key|
            @ready_list[key] = nil
          end
        end

        # Checks the current settings of the ready list.
        # @param silent [Boolean] whether to suppress output (default: false).
        # @param quiet [Boolean] whether to suppress output and use a different start pattern (default: false).
        # @return [void]
        # @example
        #   Lich::Gemstone::ReadyList.check(silent: true)
        def check(silent: false, quiet: false)
          if quiet
            start_pattern = /<output class="mono"\/>/
          else
            start_pattern = /Your current settings are:/
          end
          Lich::Util.issue_command("ready list", start_pattern, silent: silent, quiet: quiet)
          @checked = true
        end
      end
    end
  end
end