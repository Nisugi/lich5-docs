# A module namespace for the Lich game automation system
module Lich
  # A module namespace for Gemstone-specific functionality 
  module Gemstone
    # Manages the ready list system for equipped items and weapons in GemStone
    # Tracks various equipment slots including weapons, shields, sheaths, and ammunition
    #
    # @author Lich5 Documentation Generator
    class ReadyList
      @checked = false
      
      # Hash containing the ready list slot assignments
      # @return [Hash<Symbol, Object>] The ready list configuration
      #
      # @note Ready list slots include :shield, :weapon, :secondary_weapon, :ranged_weapon,
      #   :ammo_bundle, :ammo2_bundle, :sheath, and :secondary_sheath
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

      # Dynamically generated accessor methods for each ready list slot:
      #
      # @method shield
      # @return [Object] the item in the shield slot
      #
      # @method weapon
      # @return [Object] the item in the primary weapon slot
      #
      # @method secondary_weapon  
      # @return [Object] the item in the secondary weapon slot
      #
      # @method ranged_weapon
      # @return [Object] the item in the ranged weapon slot
      #
      # @method ammo_bundle
      # @return [Object] the item in the primary ammo slot
      #
      # @method ammo2_bundle
      # @return [Object] the item in the secondary ammo slot
      #
      # @method sheath
      # @return [Object] the item in the primary sheath slot
      #
      # @method secondary_sheath
      # @return [Object] the item in the secondary sheath slot
      #
      # Each slot also has a corresponding setter method (e.g. shield=)
      @ready_list.each_key do |type|
        define_singleton_method(type) { @ready_list[type] }
        define_singleton_method("#{type}=") { |value| @ready_list[type] = value }
      end

      class << self
        def ready_list
          @ready_list
        end

        # Checks if the ready list has been verified
        #
        # @return [Boolean] true if the ready list has been checked, false otherwise
        #
        # @example
        #   Lich::Gemstone::ReadyList.checked? #=> false
        #   Lich::Gemstone::ReadyList.check
        #   Lich::Gemstone::ReadyList.checked? #=> true
        def checked?
          @checked
        end

        # Sets the checked status of the ready list
        #
        # @param value [Boolean] the new checked status
        # @return [Boolean] the new checked status
        #
        # @example
        #   Lich::Gemstone::ReadyList.checked = true
        def checked=(value)
          @checked = value
        end

        # Validates that all items in the ready list still exist in inventory or containers
        #
        # @return [Boolean] true if all ready items are valid, false otherwise
        #
        # @note This method requires the ready list to have been checked first
        #
        # @example
        #   Lich::Gemstone::ReadyList.valid? #=> true
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

        # Resets the ready list to empty state
        # Clears all slot assignments and sets checked status to false
        #
        # @return [void]
        #
        # @example
        #   Lich::Gemstone::ReadyList.reset
        def reset
          @checked = false
          @ready_list.each_key do |key|
            @ready_list[key] = nil
          end
        end

        # Checks the current ready list configuration in the game
        #
        # @param silent [Boolean] if true, suppresses command echo
        # @param quiet [Boolean] if true, uses alternate output pattern matching
        # @return [void]
        # @raise [RuntimeError] if unable to get ready list from game
        #
        # @example
        #   Lich::Gemstone::ReadyList.check
        #   Lich::Gemstone::ReadyList.check(silent: true)
        #   Lich::Gemstone::ReadyList.check(quiet: true)
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