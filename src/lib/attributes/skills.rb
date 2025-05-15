require "ostruct"

module Lich
  module Gemstone
    module Skills
      # Converts ranks into a bonus value based on predefined thresholds.
      #
      # @param ranks [Integer, Symbol, String] The ranks to convert into a bonus.
      #   - If Integer, it calculates the bonus based on the rank value.
      #   - If Symbol or String, it retrieves the bonus from the Infomon database.
      # @return [Integer] The calculated bonus for the given ranks.
      # @raise [StandardError] If the input is neither an Integer, Symbol, nor String.
      # @example
      #   Skills.to_bonus(Skills.combatmaneuvers) # => returns the bonus for combat maneuvers
      def self.to_bonus(ranks)
        case ranks
        when Integer
          bonus = 0
          while ranks > 0
            if ranks > 40
              bonus += (ranks - 40)
              ranks = 40
            elsif ranks > 30
              bonus += (ranks - 30) * 2
              ranks = 30
            elsif ranks > 20
              bonus += (ranks - 20) * 3
              ranks = 20
            elsif ranks > 10
              bonus += (ranks - 10) * 4
              ranks = 10
            else
              bonus += (ranks * 5)
              ranks = 0
            end
          end
          bonus
        when String, Symbol
          Infomon.get("skill.%s_bonus" % ranks)
        else
          echo "You're trying to move the cheese!"
        end
      end

      @@skills = %i(two_weapon_combat armor_use shield_use combat_maneuvers edged_weapons blunt_weapons two_handed_weapons ranged_weapons thrown_weapons polearm_weapons brawling ambush multi_opponent_combat physical_fitness dodging arcane_symbols magic_item_use spell_aiming harness_power elemental_mana_control mental_mana_control spirit_mana_control elemental_lore_air elemental_lore_earth elemental_lore_fire elemental_lore_water spiritual_lore_blessings spiritual_lore_religion spiritual_lore_summoning sorcerous_lore_demonology sorcerous_lore_necromancy mental_lore_divination mental_lore_manipulation mental_lore_telepathy mental_lore_transference mental_lore_transformation survival disarming_traps picking_locks stalking_and_hiding perception climbing swimming first_aid trading pickpocketing)
      # todo: lich up through 5.6.2 returns rank as integer - should we extend to include bonus?
      @@skills.each do |skill|
        self.define_singleton_method(skill) do
          Infomon.get("skill.%s" % skill).to_i
        end
      end

      # Defines shorthand methods for skills to maintain backward compatibility.
      #
      # These methods will call the corresponding long-hand skill methods.
      # @note This is for backward compatibility; if the method is extended, it should return only rank.
      %i(twoweaponcombat armoruse shielduse combatmaneuvers edgedweapons bluntweapons twohandedweapons rangedweapons thrownweapons polearmweapons multiopponentcombat physicalfitness arcanesymbols magicitemuse spellaiming harnesspower disarmingtraps pickinglocks stalkingandhiding firstaid emc mmc smc elair elearth elfire elwater slblessings slreligion slsummoning sldemonology slnecromancy mldivination mlmanipulation mltelepathy mltransference mltransformation).each do |shorthand|
        long_hand = @@skills.find { |method|
          method.to_s.gsub(/_/, '')
                .gsub(/elementallore/, 'el')
                .gsub(/spirituallore/, 'sl')
                .gsub(/sorcerouslore/, 'sl')
                .gsub(/mentallore/, 'ml')
                .gsub(/elementalmanacontrol/, 'emc')
                .gsub(/spiritmanacontrol/, 'smc')
                .gsub(/mentalmanacontrol/, 'mmc')
                .eql?(shorthand.to_s)
        }
        self.define_singleton_method(shorthand) do
          Skills.send(long_hand)
        end
      end

      # Serializes the current skills into an array.
      #
      # @return [Array<Integer>] An array of the current skill ranks.
      # @example
      #   Skills.serialize # => returns an array of skill ranks
      def self.serialize
        [self.two_weapon_combat, self.armor_use, self.shield_use, self.combat_maneuvers,
         self.edged_weapons, self.blunt_weapons, self.two_handed_weapons, self.ranged_weapons,
         self.thrown_weapons, self.polearm_weapons, self.brawling, self.ambush,
         self.multi_opponent_combat, self.physical_fitness, self.dodging, self.arcane_symbols,
         self.magic_item_use, self.spell_aiming, self.harness_power, self.elemental_mana_control,
         self.mental_mana_control, self.spirit_mana_control, self.elemental_lore_air,
         self.elemental_lore_earth, self.elemental_lore_fire, self.elemental_lore_water,
         self.spiritual_lore_blessings, self.spiritual_lore_religion, self.spiritual_lore_summoning,
         self.sorcerous_lore_demonology, self.sorcerous_lore_necromancy, self.mental_lore_divination,
         self.mental_lore_manipulation, self.mental_lore_telepathy, self.mental_lore_transference,
         self.mental_lore_transformation, self.survival, self.disarming_traps, self.picking_locks,
         self.stalking_and_hiding, self.perception, self.climbing, self.swimming,
         self.first_aid, self.trading, self.pickpocketing]
      end
    end
  end
end
