module Lich
  module Gemstone
    # Represents a spellsong for a bard character.
    class Spellsong
      @@renewed ||= 0.to_f
      @@song_duration ||= 120.to_f
      @@duration_calcs ||= []

      # Synchronizes the spellsong duration based on active bard spells.
      #
      # @return [String] message indicating the status of active bard spells.
      # @example
      #   Spellsong.sync
      def self.sync
        timed_spell = Effects::Spells.to_h.keys.find { |k| k.to_s.match(/10[0-9][0-9]/) }
        return 'No active bard spells' if timed_spell.nil?
        @@renewed = Time.at(Time.now.to_f - self.timeleft.to_f + (Effects::Spells.time_left(timed_spell) * 60.to_f)) # duration
      end

      # Updates the time when the spellsong was last renewed.
      #
      # @return [Time] the current time when the spellsong was renewed.
      # @example
      #   Spellsong.renewed
      def self.renewed
        @@renewed = Time.now
      end

      # Sets the renewed time for the spellsong.
      #
      # @param [Time] val the time to set as the renewed time.
      # @example
      #   Spellsong.renewed = Time.now
      def self.renewed=(val)
        @@renewed = val
      end

      # Retrieves the last renewed time of the spellsong.
      #
      # @return [Time] the last renewed time.
      # @example
      #   Spellsong.renewed_at
      def self.renewed_at
        @@renewed
      end

      # Calculates the remaining time left for the spellsong.
      #
      # @return [Float] the time left in minutes.
      # @note Returns 0.0 if the character is not a Bard.
      # @example
      #   Spellsong.timeleft
      def self.timeleft
        return 0.0 if Stats.prof != 'Bard'
        (self.duration - ((Time.now.to_f - @@renewed.to_f) % self.duration)) / 60.to_f
      end

      # Serializes the current time left for the spellsong.
      #
      # @return [Float] the time left in minutes.
      # @example
      #   Spellsong.serialize
      def self.serialize
        self.timeleft
      end

      # Calculates the duration of the spellsong based on various stats.
      #
      # @return [Float] the duration of the spellsong.
      # @example
      #   Spellsong.duration
      def self.duration
        return @@song_duration if @@duration_calcs == [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy]
        return @@song_duration if [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy].include?(nil)
        @@duration_calcs = [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy]
        total = self.duration_base_level(Stats.level)
        return (@@song_duration = total + Stats.log[1] + (Stats.inf[1] * 3) + (Skills.mltelepathy * 2))
      end

      # Calculates the base duration of the spellsong based on the bard's level.
      #
      # @param [Integer] level the level of the bard (default is the current level).
      # @return [Integer] the base duration of the spellsong.
      # @example
      #   Spellsong.duration_base_level(30)
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

      # Calculates the total cost to renew active spells.
      #
      # @return [Integer] the total renewal cost for active spells.
      # @example
      #   Spellsong.renew_cost
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

      # Calculates the durability of the sonic armor.
      #
      # @return [Integer] the durability of the sonic armor.
      # @example
      #   Spellsong.sonicarmordurability
      def self.sonicarmordurability
        210 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Calculates the durability of the sonic blade.
      #
      # @return [Integer] the durability of the sonic blade.
      # @example
      #   Spellsong.sonicbladedurability
      def self.sonicbladedurability
        160 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Calculates the durability of the sonic weapon.
      #
      # @return [Integer] the durability of the sonic weapon.
      # @example
      #   Spellsong.sonicweapondurability
      def self.sonicweapondurability
        self.sonicbladedurability
      end

      # Calculates the durability of the sonic shield.
      #
      # @return [Integer] the durability of the sonic shield.
      # @example
      #   Spellsong.sonicshielddurability
      def self.sonicshielddurability
        125 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Calculates the bonus for the tonis spell.
      #
      # @return [Integer] the tonis haste bonus.
      # @example
      #   Spellsong.tonishastebonus
      def self.tonishastebonus
        bonus = -1
        thresholds = [30, 75]
        thresholds.each { |val| if Skills.elair >= val then bonus -= 1 end }
        bonus
      end

      # Calculates the push down bonus for the depression spell.
      #
      # @return [Integer] the depression push down bonus.
      # @example
      #   Spellsong.depressionpushdown
      def self.depressionpushdown
        20 + Skills.mltelepathy
      end

      # Calculates the slow bonus for the depression spell.
      #
      # @return [Integer] the depression slow bonus.
      # @example
      #   Spellsong.depressionslow
      def self.depressionslow
        thresholds = [10, 25, 45, 70, 100]
        bonus = -2
        thresholds.each { |val| if Skills.mltelepathy >= val then bonus -= 1 end }
        bonus
      end

      # Calculates the number of targets that can be held by the bard.
      #
      # @return [Integer] the number of holding targets.
      # @example
      #   Spellsong.holdingtargets
      def self.holdingtargets
        1 + ((Spells.bard - 1) / 7).truncate
      end

      # Calculates the cost of the spellsong.
      #
      # @return [Integer] the cost of the spellsong.
      # @example
      #   Spellsong.cost
      def self.cost
        self.renew_cost
      end

      # Calculates the dodge bonus for the tonis spell.
      #
      # @return [Integer] the tonis dodge bonus.
      # @example
      #   Spellsong.tonisdodgebonus
      def self.tonisdodgebonus
        thresholds = [1, 2, 3, 5, 8, 10, 14, 17, 21, 26, 31, 36, 42, 49, 55, 63, 70, 78, 87, 96]
        bonus = 20
        thresholds.each { |val| if Skills.elair >= val then bonus += 1 end }
        bonus
      end

      # Calculates the dodge bonus for the mirrors spell.
      #
      # @return [Integer] the mirrors dodge bonus.
      # @example
      #   Spellsong.mirrorsdodgebonus
      def self.mirrorsdodgebonus
        20 + ((Spells.bard - 19) / 2).round
      end

      # Calculates the cost for the mirrors spell.
      #
      # @return [Array<Integer>] the cost of the mirrors spell.
      # @example
      #   Spellsong.mirrorscost
      def self.mirrorscost
        [19 + ((Spells.bard - 19) / 5).truncate, 8 + ((Spells.bard - 19) / 10).truncate]
      end

      # Calculates the sonic bonus based on the bard's spells.
      #
      # @return [Integer] the sonic bonus.
      # @example
      #   Spellsong.sonicbonus
      def self.sonicbonus
        (Spells.bard / 2).round
      end

      # Calculates the sonic armor bonus.
      #
      # @return [Integer] the sonic armor bonus.
      # @example
      #   Spellsong.sonicarmorbonus
      def self.sonicarmorbonus
        self.sonicbonus + 15
      end

      # Calculates the sonic blade bonus.
      #
      # @return [Integer] the sonic blade bonus.
      # @example
      #   Spellsong.sonicbladebonus
      def self.sonicbladebonus
        self.sonicbonus + 10
      end

      # Calculates the sonic weapon bonus.
      #
      # @return [Integer] the sonic weapon bonus.
      # @example
      #   Spellsong.sonicweaponbonus
      def self.sonicweaponbonus
        self.sonicbladebonus
      end

      # Calculates the sonic shield bonus.
      #
      # @return [Integer] the sonic shield bonus.
      # @example
      #   Spellsong.sonicshieldbonus
      def self.sonicshieldbonus
        self.sonicbonus + 10
      end

      # Calculates the valor bonus based on the bard's level and spells.
      #
      # @return [Integer] the valor bonus.
      # @example
      #   Spellsong.valorbonus
      def self.valorbonus
        10 + (([Spells.bard, Stats.level].min - 10) / 2).round
      end

      # Calculates the cost for the valor spell.
      #
      # @return [Array<Integer>] the cost of the valor spell.
      # @example
      #   Spellsong.valorcost
      def self.valorcost
        [10 + (self.valorbonus / 2), 3 + (self.valorbonus / 5)]
      end

      # Calculates the cost for the luck spell.
      #
      # @return [Array<Integer>] the cost of the luck spell.
      # @example
      #   Spellsong.luckcost
      def self.luckcost
        [6 + ((Spells.bard - 6) / 4), (6 + ((Spells.bard - 6) / 4) / 2).round]
      end

      # Calculates the mana cost for spells.
      #
      # @return [Array<Integer>] the mana cost for spells.
      # @example
      #   Spellsong.manacost
      def self.manacost
        [18, 15]
      end

      # Calculates the cost for the fort spell.
      #
      # @return [Array<Integer>] the cost of the fort spell.
      # @example
      #   Spellsong.fortcost
      def self.fortcost
        [3, 1]
      end

      # Calculates the cost for the shield spell.
      #
      # @return [Array<Integer>] the cost of the shield spell.
      # @example
      #   Spellsong.shieldcost
      def self.shieldcost
        [9, 4]
      end

      # Calculates the cost for the weapon spell.
      #
      # @return [Array<Integer>] the cost of the weapon spell.
      # @example
      #   Spellsong.weaponcost
      def self.weaponcost
        [12, 4]
      end

      # Calculates the cost for the armor spell.
      #
      # @return [Array<Integer>] the cost of the armor spell.
      # @example
      #   Spellsong.armorcost
      def self.armorcost
        [14, 5]
      end

      # Calculates the cost for the sword spell.
      #
      # @return [Array<Integer>] the cost of the sword spell.
      # @example
      #   Spellsong.swordcost
      def self.swordcost
        [25, 15]
      end
    end
  end
end
