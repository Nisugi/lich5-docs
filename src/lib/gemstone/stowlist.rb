module Lich
  module Gemstone
    # Represents a list of items that can be stowed.
    class StowList
      @checked = false
      @stow_list = {
        box: nil,
        gem: nil,
        herb: nil,
        skin: nil,
        wand: nil,
        scroll: nil,
        potion: nil,
        trinket: nil,
        reagent: nil,
        lockpick: nil,
        treasure: nil,
        forageable: nil,
        collectible: nil,
        default: nil
      }

      # Define class-level accessors for stow list entries
      @stow_list.each_key do |type|
        # Retrieves the value of the specified stow list entry.
        #
        # @return [Object, nil] the value of the stow list entry or nil if not set.
        define_singleton_method(type) { @stow_list[type] }

        # Sets the value of the specified stow list entry.
        #
        # @param value [Object] the value to set for the stow list entry.
        # @return [Object] the value that was set.
        define_singleton_method("#{type}=") { |value| @stow_list[type] = value }
      end

      class << self
        # Returns the entire stow list.
        #
        # @return [Hash] the stow list containing all entries.
        def stow_list
          @stow_list
        end

        # Checks if the stow list has been checked.
        #
        # @return [Boolean] true if checked, false otherwise.
        def checked?
          @checked
        end

        # Sets the checked status of the stow list.
        #
        # @param value [Boolean] the new checked status.
        # @return [Boolean] the value that was set.
        def checked=(value)
          @checked = value
        end

        # Validates the stow list entries against the game inventory.
        #
        # @return [Boolean] true if all entries are valid, false otherwise.
        # @note This method will set @checked to false if any entry is invalid.
        def valid?
          # check if existing containers are valid or not
          return false unless checked?
          @stow_list.each_value do |value|
            unless value.nil? || GameObj.inv.map(&:id).include?(value.id)
              @checked = false
              return false
            end
          end
          return true
        end

        # Resets the stow list and its checked status.
        #
        # @return [void]
        # @example
        #   StowList.reset
        def reset
          @checked = false
          @stow_list.each_key do |key|
            @stow_list[key] = nil
          end
        end

        # Checks the stow list and issues a command to the game.
        #
        # @param silent [Boolean] whether to suppress output (default: false).
        # @param quiet [Boolean] whether to suppress the initial message (default: false).
        # @return [void]
        # @example
        #   StowList.check(silent: true)
        def check(silent: false, quiet: false)
          if quiet
            start_pattern = /<output class="mono"\/>/
          else
            start_pattern = /You have the following containers set as stow targets:/
          end
          Lich::Util.issue_command("stow list", start_pattern, silent: silent, quiet: quiet)
          @checked = true
        end
      end
    end
  end
end