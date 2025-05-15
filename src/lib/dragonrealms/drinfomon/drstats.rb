# Module for managing DragonRealms character statistics and attributes
# Provides access to character stats, guild information, and vital statistics
#
# @author Lich5 Documentation Generator
module Lich
  module DragonRealms
    module DRStats
      @@race = nil
      @@guild = nil 
      @@gender = nil
      @@age ||= 0
      @@circle ||= 0
      @@strength ||= 0
      @@stamina ||= 0
      @@reflex ||= 0
      @@agility ||= 0
      @@intelligence ||= 0
      @@wisdom ||= 0
      @@discipline ||= 0
      @@charisma ||= 0
      @@favors ||= 0
      @@tdps ||= 0
      @@encumbrance = nil
      @@balance ||= 8
      @@luck ||= 0

      # Gets the character's race
      # @return [String, nil] The character's race or nil if not set
      #
      # @example
      #   DRStats.race # => "Elf"
      def self.race
        @@race
      end

      # Sets the character's race
      # @param val [String] The race to set
      # @return [String] The new race value
      #
      # @example
      #   DRStats.race = "Dwarf"
      def self.race=(val)
        @@race = val
      end

      # Gets the character's guild/profession
      # @return [String, nil] The character's guild or nil if not set
      #
      # @example
      #   DRStats.guild # => "Warrior Mage"
      def self.guild
        @@guild
      end

      # Sets the character's guild
      # @param val [String] The guild to set
      # @return [String] The new guild value
      #
      # @example
      #   DRStats.guild = "Cleric"
      def self.guild=(val)
        @@guild = val
      end

      # Gets the character's gender
      # @return [String, nil] The character's gender or nil if not set
      #
      # @example
      #   DRStats.gender # => "Male"
      def self.gender
        @@gender
      end

      # Sets the character's gender
      # @param val [String] The gender to set
      # @return [String] The new gender value
      #
      # @example
      #   DRStats.gender = "Female"
      def self.gender=(val)
        @@gender = val
      end

      # Gets the character's age
      # @return [Integer] The character's age (defaults to 0)
      #
      # @example
      #   DRStats.age # => 25
      def self.age
        @@age
      end

      # Sets the character's age
      # @param val [Integer] The age to set
      # @return [Integer] The new age value
      #
      # @example
      #   DRStats.age = 30
      def self.age=(val)
        @@age = val
      end

      # Gets the character's circle (level)
      # @return [Integer] The character's circle (defaults to 0)
      #
      # @example
      #   DRStats.circle # => 15
      def self.circle
        @@circle
      end

      # Sets the character's circle
      # @param val [Integer] The circle to set
      # @return [Integer] The new circle value
      #
      # @example
      #   DRStats.circle = 16
      def self.circle=(val)
        @@circle = val
      end

      # Gets the character's strength stat
      # @return [Integer] The character's strength value (defaults to 0)
      #
      # @example
      #   DRStats.strength # => 50
      def self.strength
        @@strength
      end

      # Sets the character's strength stat
      # @param val [Integer] The strength value to set
      # @return [Integer] The new strength value
      #
      # @example
      #   DRStats.strength = 55
      def self.strength=(val)
        @@strength = val
      end

      # Gets the character's stamina stat
      # @return [Integer] The character's stamina value (defaults to 0)
      #
      # @example
      #   DRStats.stamina # => 45
      def self.stamina
        @@stamina
      end

      # Sets the character's stamina stat
      # @param val [Integer] The stamina value to set
      # @return [Integer] The new stamina value
      #
      # @example
      #   DRStats.stamina = 50
      def self.stamina=(val)
        @@stamina = val
      end

      # Gets the character's reflex stat
      # @return [Integer] The character's reflex value (defaults to 0)
      #
      # @example
      #   DRStats.reflex # => 40
      def self.reflex
        @@reflex
      end

      # Sets the character's reflex stat
      # @param val [Integer] The reflex value to set
      # @return [Integer] The new reflex value
      #
      # @example
      #   DRStats.reflex = 45
      def self.reflex=(val)
        @@reflex = val
      end

      # Gets the character's agility stat
      # @return [Integer] The character's agility value (defaults to 0)
      #
      # @example
      #   DRStats.agility # => 35
      def self.agility
        @@agility
      end

      # Sets the character's agility stat
      # @param val [Integer] The agility value to set
      # @return [Integer] The new agility value
      #
      # @example
      #   DRStats.agility = 40
      def self.agility=(val)
        @@agility = val
      end

      # Gets the character's intelligence stat
      # @return [Integer] The character's intelligence value (defaults to 0)
      #
      # @example
      #   DRStats.intelligence # => 60
      def self.intelligence
        @@intelligence
      end

      # Sets the character's intelligence stat
      # @param val [Integer] The intelligence value to set
      # @return [Integer] The new intelligence value
      #
      # @example
      #   DRStats.intelligence = 65
      def self.intelligence=(val)
        @@intelligence = val
      end

      # Gets the character's wisdom stat
      # @return [Integer] The character's wisdom value (defaults to 0)
      #
      # @example
      #   DRStats.wisdom # => 55
      def self.wisdom
        @@wisdom
      end

      # Sets the character's wisdom stat
      # @param val [Integer] The wisdom value to set
      # @return [Integer] The new wisdom value
      #
      # @example
      #   DRStats.wisdom = 60
      def self.wisdom=(val)
        @@wisdom = val
      end

      # Gets the character's discipline stat
      # @return [Integer] The character's discipline value (defaults to 0)
      #
      # @example
      #   DRStats.discipline # => 50
      def self.discipline
        @@discipline
      end

      # Sets the character's discipline stat
      # @param val [Integer] The discipline value to set
      # @return [Integer] The new discipline value
      #
      # @example
      #   DRStats.discipline = 55
      def self.discipline=(val)
        @@discipline = val
      end

      # Gets the character's charisma stat
      # @return [Integer] The character's charisma value (defaults to 0)
      #
      # @example
      #   DRStats.charisma # => 45
      def self.charisma
        @@charisma
      end

      # Sets the character's charisma stat
      # @param val [Integer] The charisma value to set
      # @return [Integer] The new charisma value
      #
      # @example
      #   DRStats.charisma = 50
      def self.charisma=(val)
        @@charisma = val
      end

      # Gets the character's favor points
      # @return [Integer] The character's favor points (defaults to 0)
      #
      # @example
      #   DRStats.favors # => 100
      def self.favors
        @@favors
      end

      # Sets the character's favor points
      # @param val [Integer] The favor points to set
      # @return [Integer] The new favor points value
      #
      # @example
      #   DRStats.favors = 150
      def self.favors=(val)
        @@favors = val
      end

      # Gets the character's TDPs (Training Point value)
      # @return [Integer] The character's TDPs (defaults to 0)
      #
      # @example
      #   DRStats.tdps # => 250
      def self.tdps
        @@tdps
      end

      # Sets the character's TDPs
      # @param val [Integer] The TDPs to set
      # @return [Integer] The new TDPs value
      #
      # @example
      #   DRStats.tdps = 300
      def self.tdps=(val)
        @@tdps = val
      end

      # Gets the character's luck stat
      # @return [Integer] The character's luck value (defaults to 0)
      #
      # @example
      #   DRStats.luck # => 20
      def self.luck
        @@luck
      end

      # Sets the character's luck stat
      # @param val [Integer] The luck value to set
      # @return [Integer] The new luck value
      #
      # @example
      #   DRStats.luck = 25
      def self.luck=(val)
        @@luck = val
      end

      # Gets the character's balance value
      # @return [Integer] The character's balance value (defaults to 8)
      #
      # @example
      #   DRStats.balance # => 8
      def self.balance
        @@balance
      end

      # Sets the character's balance value
      # @param val [Integer] The balance value to set
      # @return [Integer] The new balance value
      #
      # @example
      #   DRStats.balance = 10
      def self.balance=(val)
        @@balance = val
      end

      # Gets the character's encumbrance status
      # @return [String, nil] The character's encumbrance level or nil if not set
      #
      # @example
      #   DRStats.encumbrance # => "burdened"
      def self.encumbrance
        @@encumbrance
      end

      # Sets the character's encumbrance status
      # @param val [String] The encumbrance level to set
      # @return [String] The new encumbrance value
      #
      # @example
      #   DRStats.encumbrance = "heavily burdened"
      def self.encumbrance=(val)
        @@encumbrance = val
      end

      # Gets the character's name from XML data
      # @return [String] The character's name
      #
      # @example
      #   DRStats.name # => "Adventurer"
      def self.name
        XMLData.name
      end

      # Gets the character's current health from XML data
      # @return [Integer] The character's current health value
      #
      # @example
      #   DRStats.health # => 100
      def self.health
        XMLData.health
      end

      # Gets the character's current mana from XML data
      # @return [Integer] The character's current mana value
      #
      # @example
      #   DRStats.mana # => 100
      def self.mana
        XMLData.mana
      end

      # Gets the character's current fatigue from XML data
      # @return [Integer] The character's current fatigue value
      #
      # @example
      #   DRStats.fatigue # => 100
      def self.fatigue
        XMLData.stamina
      end

      # Gets the character's current spirit from XML data
      # @return [Integer] The character's current spirit value
      #
      # @example
      #   DRStats.spirit # => 100
      def self.spirit
        XMLData.spirit
      end

      # Gets the character's current concentration from XML data
      # @return [Integer] The character's current concentration value
      #
      # @example
      #   DRStats.concentration # => 100
      def self.concentration
        XMLData.concentration
      end

      # Gets the character's native mana type based on their guild
      # @return [String, nil] The type of mana ('arcane', 'lunar', 'elemental', 'holy', 'life') or nil for non-magic users
      #
      # @example
      #   DRStats.native_mana # => "elemental" for Warrior Mages
      def self.native_mana
        case DRStats.guild
        when 'Necromancer'
          'arcane'
        when 'Barbarian', 'Thief'
          nil
        when 'Moon Mage', 'Trader'
          'lunar'
        when 'Warrior Mage', 'Bard'
          'elemental'
        when 'Cleric', 'Paladin'
          'holy'
        when 'Empath', 'Ranger'
          'life'
        end
      end

      # Serializes the character's stats into an array
      # @return [Array] Array containing all character stats in a specific order
      #
      # @example
      #   DRStats.serialize # => ["Elf", "Warrior Mage", "Male", 25, 15, ...]
      def self.serialize
        [@@race, @@guild, @@gender, @@age, @@circle, @@strength, @@stamina, @@reflex, @@agility, @@intelligence, @@wisdom, @@discipline, @@charisma, @@favors, @@tdps, @@luck, @@encumbrance]
      end

      # Loads serialized stats from an array
      # @param array [Array] Array of stats to load
      # @return [Array] The loaded stats array
      #
      # @example
      #   DRStats.load_serialized = ["Elf", "Warrior Mage", "Male", 25, ...]
      def self.load_serialized=(array)
        @@race, @@guild, @@gender, @@age = array[0..3]
        @@circle, @@strength, @@stamina, @@reflex, @@agility, @@intelligence, @@wisdom, @@discipline, @@charisma, @@favors, @@tdps, @@luck, @@encumbrance = array[5..12]
      end

      # Checks if character is a Barbarian
      # @return [Boolean] true if character belongs to the Barbarian guild
      def self.barbarian?
        @@guild == 'Barbarian'
      end

      # Checks if character is a Bard
      # @return [Boolean] true if character belongs to the Bard guild
      def self.bard?
        @@guild == 'Bard'
      end

      # Checks if character is a Cleric
      # @return [Boolean] true if character belongs to the Cleric guild
      def self.cleric?
        @@guild == 'Cleric'
      end

      # Checks if character is a Commoner
      # @return [Boolean] true if character belongs to the Commoner guild
      def self.commoner?
        @@guild == 'Commoner'
      end

      # Checks if character is an Empath
      # @return [Boolean] true if character belongs to the Empath guild
      def self.empath?
        @@guild == 'Empath'
      end

      # Checks if character is a Moon Mage
      # @return [Boolean] true if character belongs to the Moon Mage guild
      def self.moon_mage?
        @@guild == 'Moon Mage'
      end

      # Checks if character is a Necromancer
      # @return [Boolean] true if character belongs to the Necromancer guild
      def self.necromancer?
        @@guild == 'Necromancer'
      end

      # Checks if character is a Paladin
      # @return [Boolean] true if character belongs to the Paladin guild
      def self.paladin?
        @@guild == 'Paladin'
      end

      # Checks if character is a Ranger
      # @return [Boolean] true if character belongs to the Ranger guild
      def self.ranger?
        @@guild == 'Ranger'
      end

      # Checks if character is a Thief
      # @return [Boolean] true if character belongs to the Thief guild
      def self.thief?
        @@guild == 'Thief'
      end

      # Checks if character is a Trader
      # @return [Boolean] true if character belongs to the Trader guild
      def self.trader?
        @@guild == 'Trader'
      end

      # Checks if character is a Warrior Mage
      # @return [Boolean] true if character belongs to the Warrior Mage guild
      def self.warrior_mage?
        @@guild == 'Warrior Mage'
      end
    end
  end
end