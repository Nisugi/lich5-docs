# Module for the Lich game automation system
#
# @author Lich5 Documentation Generator
module Lich

  # Module containing DragonRealms specific functionality
  module DragonRealms

    # Manages spell-related information and state for DragonRealms characters
    #
    # This module tracks active spells, known spells, feats, and related magical abilities.
    # It provides methods to access spell states and manage spell book parsing.
    module DRSpells
      @@known_spells = {}
      @@known_feats = {}
      @@spellbook_format = nil # 'column-formatted' or 'non-column'

      @@grabbing_known_spells = false
      @@grabbing_known_barbarian_abilities = false
      @@grabbing_known_khri = false

      # Returns a list of currently active spells on the character
      #
      # @return [Array<String>] List of active spell names
      # @example
      #   DRSpells.active_spells #=> ["Shield", "Strength", "Bless"]
      def self.active_spells
        XMLData.dr_active_spells
      end

      # Returns a hash of all spells known by the character
      #
      # @return [Hash] Known spells with their properties
      # @example
      #   DRSpells.known_spells #=> {"Shield" => {...}, "Bless" => {...}}
      def self.known_spells
        @@known_spells
      end

      # Returns known feats and special abilities
      #
      # @return [Hash] Known feats with their properties
      # @example
      #   DRSpells.known_feats #=> {"Surge" => {...}, "Whirlwind" => {...}}
      def self.known_feats
        @@known_feats
      end

      # Returns current slivers count for active spells
      #
      # @return [Integer] Number of active spell slivers
      # @example
      #   DRSpells.slivers #=> 3
      def self.slivers
        XMLData.dr_active_spells_slivers
      end

      # Returns the stellar magic percentage
      #
      # @return [Integer] Current stellar magic percentage (0-100)
      # @example
      #   DRSpells.stellar_percentage #=> 75
      def self.stellar_percentage
        XMLData.dr_active_spells_stellar_percentage
      end

      # Indicates if the system is currently parsing known spells
      #
      # @return [Boolean] True if currently grabbing spell information
      # @example
      #   DRSpells.grabbing_known_spells #=> false
      def self.grabbing_known_spells
        @@grabbing_known_spells
      end

      # Sets the spell grabbing state
      #
      # @param val [Boolean] Whether spell grabbing is active
      # @return [Boolean] The new state
      # @example
      #   DRSpells.grabbing_known_spells = true
      def self.grabbing_known_spells=(val)
        @@grabbing_known_spells = val
      end

      # Checks if parsing barbarian abilities is active
      #
      # @return [Boolean] True if checking barbarian abilities
      # @example
      #   DRSpells.check_known_barbarian_abilities #=> false
      def self.check_known_barbarian_abilities
        @@grabbing_known_barbarian_abilities
      end

      # Sets the barbarian ability checking state
      #
      # @param val [Boolean] Whether ability checking is active
      # @return [Boolean] The new state
      # @example
      #   DRSpells.check_known_barbarian_abilities = true
      def self.check_known_barbarian_abilities=(val)
        @@grabbing_known_barbarian_abilities = val
      end

      # Indicates if the system is parsing Khri abilities
      #
      # @return [Boolean] True if grabbing Khri information
      # @example
      #   DRSpells.grabbing_known_khri #=> false
      def self.grabbing_known_khri
        @@grabbing_known_khri
      end

      # Sets the Khri grabbing state
      #
      # @param val [Boolean] Whether Khri grabbing is active
      # @return [Boolean] The new state
      # @example
      #   DRSpells.grabbing_known_khri = true
      def self.grabbing_known_khri=(val)
        @@grabbing_known_khri = val
      end

      # Gets the current spellbook format
      #
      # @return [String, nil] Either 'column-formatted', 'non-column', or nil
      # @example
      #   DRSpells.spellbook_format #=> 'column-formatted'
      def self.spellbook_format
        @@spellbook_format
      end

      # Sets the spellbook format
      #
      # @param val [String] The format type ('column-formatted' or 'non-column')
      # @return [String] The new format
      # @example
      #   DRSpells.spellbook_format = 'column-formatted'
      # @note Valid values are 'column-formatted' or 'non-column'
      def self.spellbook_format=(val)
        @@spellbook_format = val
      end
    end
  end
end