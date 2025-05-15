# Module namespace for the Lich game automation system
module Lich
  # Module containing Gemstone-specific functionality 
  module Gemstone
    # Handles bard spell song calculations and management including durations, costs, and bonuses
    #
    # @author Lich5 Documentation Generator
    class Spellsong
      @@renewed ||= 0.to_f
      @@song_duration ||= 120.to_f
      @@duration_calcs ||= []

      # Synchronizes the song timer with an active bard spell
      #
      # @return [String, nil] Error message if no active bard spells found
      # @example
      #   Spellsong.sync
      def self.sync
        timed_spell = Effects::Spells.to_h.keys.find { |k| k.to_s.match(/10[0-9][0-9]/) }
        return 'No active bard spells' if timed_spell.nil?
        @@renewed = Time.at(Time.now.to_f - self.timeleft.to_f + (Effects::Spells.time_left(timed_spell) * 60.to_f)) # duration
      end

      # Marks songs as renewed at the current time
      #
      # @return [Time] The current time
      # @example
      #   Spellsong.renewed
      def self.renewed
        @@renewed = Time.now
      end

      # Sets the renewal timestamp
      #
      # @param val [Time] The timestamp to set
      # @return [Time] The set timestamp
      # @example
      #   Spellsong.renewed = Time.now
      def self.renewed=(val)
        @@renewed = val
      end

      # Gets the last renewal timestamp
      #
      # @return [Time] When songs were last renewed
      # @example
      #   last_renewed = Spellsong.renewed_at
      def self.renewed_at
        @@renewed
      end

      # Calculates remaining song duration in minutes
      #
      # @return [Float] Minutes remaining on current songs
      # @note Returns 0.0 if character is not a Bard
      # @example
      #   mins_left = Spellsong.timeleft
      def self.timeleft
        return 0.0 if Stats.prof != 'Bard'
        (self.duration - ((Time.now.to_f - @@renewed.to_f) % self.duration)) / 60.to_f
      end

      # Serializes the spell song state
      #
      # @return [Float] The current timeleft value
      # @example
      #   state = Spellsong.serialize
      def self.serialize
        self.timeleft
      end

      # Calculates total song duration based on level and skills
      #
      # @return [Float] Total duration in seconds
      # @example
      #   duration = Spellsong.duration
      def self.duration
        return @@song_duration if @@duration_calcs == [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy]
        return @@song_duration if [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy].include?(nil)
        @@duration_calcs = [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy]
        total = self.duration_base_level(Stats.level)
        return (@@song_duration = total + Stats.log[1] + (Stats.inf[1] * 3) + (Skills.mltelepathy * 2))
      end

      # Calculates base song duration for a given level
      #
      # @param level [Integer] Character level (defaults to current level)
      # @return [Integer] Base duration in seconds
      # @example
      #   base_duration = Spellsong.duration_base_level(25)
      def self.duration_base_level(level = Stats.level)
        total = 120
        case level
        when (0..25)
          total += level * 4
        when (26..50)
          total += 100 + (level - 25) * 3
        when (51..75)
          total += 175 + (level - 50) * 2
        when (76..100)
          total += 225 + (level - 75)
        else
          Lich.log("unhandled case in Spellsong.duration level=#{level}")
        end
        return total
      end

      # Calculates total mana cost to renew active songs
      #
      # @return [Integer] Total mana cost
      # @note Considers songs 1003,1006,1009,1010,1012,1014,1018,1019,1025
      # @example
      #   cost = Spellsong.renew_cost
      def self.renew_cost
        # fixme: multi-spell penalty?
        total = num_active = 0
        [1003, 1006, 1009, 1010, 1012, 1014, 1018, 1019, 1025].each { |song_num|
          if (song = Spell[song_num])
            if song.active?
              total += song.renew_cost
              num_active += 1
            end
          else
            echo "self.renew_cost: warning: can't find song number #{song_num}"
          end
        }
        return total
      end

      # Calculates sonic armor durability
      #
      # @return [Integer] Durability value
      # @example
      #   durability = Spellsong.sonicarmordurability
      def self.sonicarmordurability
        210 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Calculates sonic blade durability
      #
      # @return [Integer] Durability value
      # @example
      #   durability = Spellsong.sonicbladedurability
      def self.sonicbladedurability
        160 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Alias for sonicbladedurability
      #
      # @return [Integer] Durability value
      def self.sonicweapondurability
        self.sonicbladedurability
      end

      # Calculates sonic shield durability
      #
      # @return [Integer] Durability value
      # @example
      #   durability = Spellsong.sonicshielddurability
      def self.sonicshielddurability
        125 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Calculates Tonis's Haste bonus
      #
      # @return [Integer] Speed bonus (negative value)
      # @example
      #   bonus = Spellsong.tonishastebonus
      def self.tonishastebonus
        bonus = -1
        thresholds = [30, 75]
        thresholds.each { |val| if Skills.elair >= val then bonus -= 1 end }
        bonus
      end

      # Calculates depression push down value
      #
      # @return [Integer] Push down value
      # @example
      #   pushdown = Spellsong.depressionpushdown
      def self.depressionpushdown
        20 + Skills.mltelepathy
      end

      # Calculates depression slow effect
      #
      # @return [Integer] Slow effect value (negative)
      # @example
      #   slow = Spellsong.depressionslow
      def self.depressionslow
        thresholds = [10, 25, 45, 70, 100]
        bonus = -2
        thresholds.each { |val| if Skills.mltelepathy >= val then bonus -= 1 end }
        bonus
      end

      # Calculates number of holding spell targets
      #
      # @return [Integer] Number of targets
      # @example
      #   targets = Spellsong.holdingtargets
      def self.holdingtargets
        1 + ((Spells.bard - 1) / 7).truncate
      end

      # Alias for renew_cost
      #
      # @return [Integer] Total mana cost
      def self.cost
        self.renew_cost
      end

      # Calculates Tonis's dodge bonus
      #
      # @return [Integer] Dodge bonus value
      # @example
      #   bonus = Spellsong.tonisdodgebonus
      def self.tonisdodgebonus
        thresholds = [1, 2, 3, 5, 8, 10, 14, 17, 21, 26, 31, 36, 42, 49, 55, 63, 70, 78, 87, 96]
        bonus = 20
        thresholds.each { |val| if Skills.elair >= val then bonus += 1 end }
        bonus
      end

      # Calculates mirrors dodge bonus
      #
      # @return [Integer] Dodge bonus value
      # @example
      #   bonus = Spellsong.mirrorsdodgebonus
      def self.mirrorsdodgebonus
        20 + ((Spells.bard - 19) / 2).round
      end

      # Calculates mirrors spell costs
      #
      # @return [Array<Integer>] [Base cost, Maintenance cost]
      # @example
      #   costs = Spellsong.mirrorscost
      def self.mirrorscost
        [19 + ((Spells.bard - 19) / 5).truncate, 8 + ((Spells.bard - 19) / 10).truncate]
      end

      # Calculates base sonic bonus
      #
      # @return [Integer] Sonic bonus value
      # @example
      #   bonus = Spellsong.sonicbonus
      def self.sonicbonus
        (Spells.bard / 2).round
      end

      # Calculates sonic armor bonus
      #
      # @return [Integer] Armor bonus value
      # @example
      #   bonus = Spellsong.sonicarmorbonus
      def self.sonicarmorbonus
        self.sonicbonus + 15
      end

      # Calculates sonic blade bonus
      #
      # @return [Integer] Blade bonus value
      # @example
      #   bonus = Spellsong.sonicbladebonus
      def self.sonicbladebonus
        self.sonicbonus + 10
      end

      # Alias for sonicbladebonus
      #
      # @return [Integer] Weapon bonus value
      def self.sonicweaponbonus
        self.sonicbladebonus
      end

      # Calculates sonic shield bonus
      #
      # @return [Integer] Shield bonus value
      # @example
      #   bonus = Spellsong.sonicshieldbonus
      def self.sonicshieldbonus
        self.sonicbonus + 10
      end

      # Calculates valor song bonus
      #
      # @return [Integer] Valor bonus value
      # @example
      #   bonus = Spellsong.valorbonus
      def self.valorbonus
        10 + (([Spells.bard, Stats.level].min - 10) / 2).round
      end

      # Calculates valor spell costs
      #
      # @return [Array<Integer>] [Base cost, Maintenance cost]
      # @example
      #   costs = Spellsong.valorcost
      def self.valorcost
        [10 + (self.valorbonus / 2), 3 + (self.valorbonus / 5)]
      end

      # Calculates luck spell costs
      #
      # @return [Array<Integer>] [Base cost, Maintenance cost]
      # @example
      #   costs = Spellsong.luckcost
      def self.luckcost
        [6 + ((Spells.bard - 6) / 4), (6 + ((Spells.bard - 6) / 4) / 2).round]
      end

      # Returns mana spell costs
      #
      # @return [Array<Integer>] [Base cost, Maintenance cost]
      def self.manacost
        [18, 15]
      end

      # Returns fortitude spell costs
      #
      # @return [Array<Integer>] [Base cost, Maintenance cost]
      def self.fortcost
        [3, 1]
      end

      # Returns shield spell costs
      #
      # @return [Array<Integer>] [Base cost, Maintenance cost]
      def self.shieldcost
        [9, 4]
      end

      # Returns weapon spell costs
      #
      # @return [Array<Integer>] [Base cost, Maintenance cost]
      def self.weaponcost
        [12, 4]
      end

      # Returns armor spell costs
      #
      # @return [Array<Integer>] [Base cost, Maintenance cost]
      def self.armorcost
        [14, 5]
      end

      # Returns sword spell costs
      #
      # @return [Array<Integer>] [Base cost, Maintenance cost]
      def self.swordcost
        [25, 15]
      end
    end
  end
end