require "ostruct"

# Provides character statistics functionality for the Lich scripting system
# @author Lich5 Documentation Generator
module Lich

  # Contains Gemstone-specific functionality 
  module Gemstone

    # Handles character statistics and attributes for Gemstone characters
    # Provides access to basic character info, stats, and experience
    module Stats

      # Gets the character's race
      # @return [String] The character's race (e.g., "Human", "Elf", etc.)
      # @example
      #   Lich::Gemstone::Stats.race #=> "Human"
      def self.race
        Infomon.get("stat.race")
      end

      # Gets the character's profession/class
      # @return [String] The character's full profession name
      # @example
      #   Lich::Gemstone::Stats.profession #=> "Warrior"
      def self.profession
        Infomon.get("stat.profession")
      end

      # Alias for profession method
      # @return [String] The character's profession
      # @see #profession
      def self.prof
        self.profession
      end

      # Gets the character's gender
      # @return [String] The character's gender
      # @example
      #   Lich::Gemstone::Stats.gender #=> "Male"
      def self.gender
        Infomon.get("stat.gender")
      end

      # Gets the character's age
      # @return [Integer] The character's age in years
      # @example
      #   Lich::Gemstone::Stats.age #=> 25
      def self.age
        Infomon.get("stat.age")
      end

      # Gets the character's current level
      # @return [Integer] The character's level
      # @example
      #   Lich::Gemstone::Stats.level #=> 15
      def self.level
        XMLData.level
      end

      # Dynamically generated stat methods (strength, constitution, etc.)
      # Each stat method returns detailed information about base and enhanced values
      # @return [OpenStruct] Contains:
      #   - value: [Integer] Base stat value
      #   - bonus: [Integer] Base stat bonus
      #   - enhanced: [OpenStruct] Enhanced stat information
      #     - value: [Integer] Enhanced stat value
      #     - bonus: [Integer] Enhanced stat bonus
      # @example
      #   stat = Lich::Gemstone::Stats.strength
      #   stat.value #=> 70
      #   stat.bonus #=> 3
      #   stat.enhanced.value #=> 75
      #   stat.enhanced.bonus #=> 4
      @@stats = %i(strength constitution dexterity agility discipline aura logic intuition wisdom influence)
      @@stats.each do |stat|
        self.define_singleton_method(stat) do
          enhanced = OpenStruct.new(
            value: Lich::Gemstone::Infomon.get("stat.%s.enhanced" % stat),
            bonus: Lich::Gemstone::Infomon.get("stat.%s.enhanced_bonus" % stat)
          )

          return OpenStruct.new(
            value: Lich::Gemstone::Infomon.get("stat.%s" % stat),
            bonus: Lich::Gemstone::Infomon.get("stat.%s_bonus" % stat),
            enhanced: enhanced
          )
        end
      end

      # Shorthand stat methods (str, con, dex, etc.) and their enhanced versions
      # Provided for backwards compatibility
      # @return [Array<Integer>] Two-element array containing [base_value, base_bonus]
      # @example
      #   Lich::Gemstone::Stats.str #=> [70, 3]
      #   Lich::Gemstone::Stats.enhanced_str #=> [75, 4]
      %i[str con dex agi dis aur log int wis inf].each do |shorthand|
        long_hand = @@stats.find { |method| method.to_s.start_with?(shorthand.to_s) }
        self.define_singleton_method(shorthand) do
          stat = Lich::Gemstone::Stats.send(long_hand)
          [stat.value, stat.bonus]
        end
        self.define_singleton_method("enhanced_%s" % shorthand) do
          stat = Lich::Gemstone::Stats.send(long_hand)
          [stat.enhanced.value, stat.enhanced.bonus]
        end
      end

      # Calculates the character's current experience points
      # @return [Integer] Current experience points
      # @note Uses level thresholds to calculate current experience when "until next level" is shown
      # @example
      #   Lich::Gemstone::Stats.exp #=> 125000
      def self.exp
        if XMLData.next_level_text =~ /until next level/
          exp_threshold = [2500, 5000, 10000, 17500, 27500, 40000, 55000, 72500, 92500, 115000, 140000, 167000, 197500, 230000, 265000, 302000, 341000, 382000, 425000, 470000, 517000, 566000, 617000, 670000, 725000, 781500, 839500, 899000, 960000, 1022500, 1086500, 1152000, 1219000, 1287500, 1357500, 1429000, 1502000, 1576500, 1652500, 1730000, 1808500, 1888000, 1968500, 2050000, 2132500, 2216000, 2300500, 2386000, 2472500, 2560000, 2648000, 2736500, 2825500, 2915000, 3005000, 3095500, 3186500, 3278000, 3370000, 3462500, 3555500, 3649000, 3743000, 3837500, 3932500, 4028000, 4124000, 4220500, 4317500, 4415000, 4513000, 4611500, 4710500, 4810000, 4910000, 5010500, 5111500, 5213000, 5315000, 5417500, 5520500, 5624000, 5728000, 5832500, 5937500, 6043000, 6149000, 6255500, 6362500, 6470000, 6578000, 6686500, 6795500, 6905000, 7015000, 7125500, 7236500, 7348000, 7460000, 7572500]
          exp_threshold[XMLData.level] - XMLData.next_level_text.slice(/[0-9]+/).to_i
        else
          XMLData.next_level_text.slice(/[0-9]+/).to_i
        end
      end

      # Creates a serialized array of all character stats and information
      # @return [Array] Array containing [race, profession, gender, age, exp, level, 
      #   and all base and enhanced stat values/bonuses]
      # @example
      #   stats = Lich::Gemstone::Stats.serialize
      #   # Returns array with all character information
      def self.serialize
        [self.race, self.prof, self.gender,
         self.age, self.exp, self.level,
         self.str, self.con, self.dex,
         self.agi, self.dis, self.aur,
         self.log, self.int, self.wis, self.inf,
         self.enhanced_str, self.enhanced_con, self.enhanced_dex,
         self.enhanced_agi, self.enhanced_dis, self.enhanced_aur,
         self.enhanced_log, self.enhanced_int, self.enhanced_wis,
         self.enhanced_inf]
      end
    end
  end
end