# Module namespace for the Lich game automation system
module Lich
  # Module namespace for Gemstone-specific functionality 
  module Gemstone
    # Manages and tracks container assignments for different item types in the game
    # This class maintains a registry of containers used for storing various categories of items
    #
    # @author Lich5 Documentation Generator
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

      # Dynamic accessor methods for each container type
      # Generated for: box, gem, herb, skin, wand, scroll, potion, trinket,
      # reagent, lockpick, treasure, forageable, collectible, default
      #
      # @example
      #   StowList.gem #=> Returns gem container
      #   StowList.gem = container #=> Assigns gem container
      #
      # @note These methods are dynamically generated for each container type
      @stow_list.each_key do |type|
        define_singleton_method(type) { @stow_list[type] }
        define_singleton_method("#{type}=") { |value| @stow_list[type] = value }
      end

      class << self
        # Returns the complete stow list hash containing all container assignments
        #
        # @return [Hash<Symbol, Object>] Hash mapping item types to their assigned containers
        # @example
        #   StowList.stow_list #=> {:box => container1, :gem => container2, ...}
        #
        # @note This method provides direct access to the internal stow list structure
        def stow_list
          @stow_list
        end

        # Checks if the stow list has been verified
        #
        # @return [Boolean] true if the stow list has been checked, false otherwise
        # @example
        #   StowList.checked? #=> false
        #   StowList.check
        #   StowList.checked? #=> true
        def checked?
          @checked
        end

        # Sets the checked status of the stow list
        #
        # @param value [Boolean] the new checked status
        # @return [Boolean] the new checked status
        # @example
        #   StowList.checked = true
        def checked=(value)
          @checked = value
        end

        # Validates all container assignments in the stow list
        #
        # @return [Boolean] true if all assigned containers exist in inventory, false otherwise
        # @note Requires the stow list to have been checked first
        # @example
        #   StowList.valid? #=> true
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

        # Resets the stow list to its initial empty state
        # Clears all container assignments and sets checked status to false
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

        # Checks and updates the stow list by querying the game
        #
        # @param silent [Boolean] if true, suppresses command echo
        # @param quiet [Boolean] if true, uses alternate output pattern matching
        # @return [void]
        # @example
        #   StowList.check
        #   StowList.check(silent: true)
        #   StowList.check(quiet: true)
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