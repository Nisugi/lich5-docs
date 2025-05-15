require "ostruct"

# Provides skill-related functionality for the Lich game system
# @author Lich5 Documentation Generator
module Lich

  # Contains Gemstone-specific game mechanics and systems 
  module Gemstone

    # Handles character skills and skill bonus calculations for Gemstone
    # This module provides methods to access skill ranks and calculate skill bonuses
    module Skills

      # Converts skill ranks to bonus points using Gemstone's progression system
      #
      # @param ranks [Integer, String, Symbol] Either the number of ranks or the skill name
      # @return [Integer] The calculated bonus points for the given ranks
      # @raise [RuntimeError] When an invalid parameter type is provided
      # @example Calculate bonus from rank number
      #   Skills.to_bonus(25) #=> 85
      # @example Get bonus for a skill by name
      #   Skills.to_bonus(:combat_maneuvers)
      #   Skills.to_bonus('combat_maneuvers')
      #
      # @note Bonus calculation follows Gemstone's tier system:
      #   - Ranks 1-10: 5 points per rank
      #   - Ranks 11-20: 4 points per rank
      #   - Ranks 21-30: 3 points per rank
      #   - Ranks 31-40: 2 points per rank
      #   - Ranks 41+: 1 point per rank
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

      # List of all available skills in the game
      # @return [Array<Symbol>] Array of skill names as symbols
      @@skills = %i(two_weapon_combat armor_use shield_use combat_maneuvers edged_weapons blunt_weapons two_handed_weapons ranged_weapons thrown_weapons polearm_weapons brawling ambush multi_opponent_combat physical_fitness dodging arcane_symbols magic_item_use spell_aiming harness_power elemental_mana_control mental_mana_control spirit_mana_control elemental_lore_air elemental_lore_earth elemental_lore_fire elemental_lore_water spiritual_lore_blessings spiritual_lore_religion spiritual_lore_summoning sorcerous_lore_demonology sorcerous_lore_necromancy mental_lore_divination mental_lore_manipulation mental_lore_telepathy mental_lore_transference mental_lore_transformation survival disarming_traps picking_locks stalking_and_hiding perception climbing swimming first_aid trading pickpocketing)

      # Dynamically creates methods for each standard skill
      # @note Each method returns the current rank for that skill
      @@skills.each do |skill|
        self.define_singleton_method(skill) do
          Infomon.get("skill.%s" % skill).to_i
        end
      end

      # Provides backward compatibility for shortened skill names
      # Maps legacy shorthand names to full skill names
      # @example
      #   Skills.twoweaponcombat #=> Same as Skills.two_weapon_combat
      #   Skills.emc #=> Same as Skills.elemental_mana_control
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

      # Returns an array of all skill ranks in a specific order
      # @return [Array<Integer>] Array containing all skill ranks in standard order
      # @note Used for serialization and data storage purposes
      # @example
      #   Skills.serialize #=> [10, 15, 20, ...] # Array of all skill ranks
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