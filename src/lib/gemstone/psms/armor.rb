## breakout for Armor released with PSM3
## updated for Ruby 3.2.1 and new Infomon module

# Module for handling armor-related functionality in the Gemstone game
# @author Lich5 Documentation Generator
module Lich
  module Gemstone
    module Armor
      # Returns an array of armor technique definitions with their names and costs
      #
      # @return [Array<Hash>] Array of hashes containing armor definitions
      # @example
      #   Lich::Gemstone::Armor.armor_lookups
      #   # => [{long_name: 'armor_blessing', short_name: 'blessing', cost: 0}, ...]
      # rubocop:disable Layout/ExtraSpacing
      def self.armor_lookups
        [{ long_name: 'armor_blessing',	        short_name: 'blessing',	        cost:	 0 },
         { long_name: 'armor_reinforcement',	  short_name: 'reinforcement',	  cost:	 0 },
         { long_name: 'armor_spike_mastery',	  short_name: 'spikemastery',	    cost:	 0 },
         { long_name: 'armor_support',	        short_name: 'support',	        cost:	 0 },
         { long_name: 'armored_casting',	      short_name: 'casting',	        cost:	 0 },
         { long_name: 'armored_evasion',	      short_name: 'evasion',	        cost:	 0 },
         { long_name: 'armored_fluidity',	      short_name: 'fluidity',	        cost:	 0 },
         { long_name: 'armored_stealth',	      short_name: 'stealth',	        cost:	 0 },
         { long_name: 'crush_protection',	      short_name: 'crush',	          cost:	 0 },
         { long_name: 'puncture_protection',	  short_name: 'puncture',	        cost:	 0 },
         { long_name: 'slash_protection',	      short_name: 'slash',	          cost:	 0 }]
        # rubocop:enable Layout/ExtraSpacing
      end

      @@armor_techniques = {
        "armor_blessing"      => {
          :regex => /As \w+ prays? over \w+(?:'s)? [\w\s]+, you sense that (?:the Arkati's|a) blessing will be granted against magical attacks\./i,
          :usage => "blessing",
        },
        "armor_reinforcement" => {
          :regex => /\w+ adjusts? \w+(?:'s)? [\w\s]+, reinforcing weak spots\./i,
          :usage => "reinforcement",
        },
        "armor_spike_mastery" => {
          :regex => /Armor Spike Mastery is passive and always active once learned\./i,
          :usage => "spikemastery",
        },
        "armor_support"       => {
          :regex => /\w+ adjusts? \w+(?:'s)? [\w\s]+, improving its ability to support the weight of \w+ gear\./i,
          :usage => "support",
        },
        "armored_casting"     => {
          :regex => /\w+ adjusts? \w+(?:'s)? [\w\s]+, making it easier for \w+ to recover from failed spell casting\./i,
          :usage => "casting",
        },
        "armored_evasion"     => {
          :regex => /\w+ adjusts? \w+(?:'s)? [\w\s]+, improving its comfort and maneuverability\./i,
          :usage => "evasion",
        },
        "armored_fluidity"    => {
          :regex => /\w+ adjusts? \w+(?:'s)? [\w\s]+, making it easier for \w+ to cast spells\./i,
          :usage => "fluidity",
        },
        "armored_stealth"     => {
          :regex => /\w+ adjusts? \w+(?:'s)? [\w\s]+ to cushion \w+ movements\./i,
          :usage => "stealth",
        },
        "crush_protection"    => {
          :regex => Regexp.union(/You adjust \w+(?:'s)? [\w\s]+ with your (?:cloth|leather|scale|chain|plate|accessory) armor fittings, rearranging and reinforcing the armor to better protect against (?:punctur|crush|slash)ing damage\./i,
                                 /You must specify an armor slot\./,
                                 /You don't seem to have the necessary armor fittings in hand\./),
          :usage => "crush",
        },
        "puncture_protection" => {
          :regex => Regexp.union(/You adjust \w+(?:'s)? [\w\s]+ with your (?:cloth|leather|scale|chain|plate|accessory) armor fittings, rearranging and reinforcing the armor to better protect against (?:punctur|crush|slash)ing damage\./i,
                                 /You must specify an armor slot\./,
                                 /You don't seem to have the necessary armor fittings in hand\./),
          :usage => "puncture",
        },
        "slash_protection"    => {
          :regex => Regexp.union(/You adjust \w+(?:'s)? [\w\s]+ with your (?:cloth|leather|scale|chain|plate|accessory) armor fittings, rearranging and reinforcing the armor to better protect against (?:punctur|crush|slash)ing damage\./i,
                                 /You must specify an armor slot\./,
                                 /You don't seem to have the necessary armor fittings in hand\./),
          :usage => "slash",
        },
      }

      # Retrieves the rank/level of the specified armor technique
      #
      # @param name [String] The name of the armor technique
      # @return [Integer] The rank/level of the technique
      # @example
      #   Armor['blessing'] #=> 3
      #   Armor['armor_blessing'] #=> 3
      def Armor.[](name)
        return PSMS.assess(name, 'Armor')
      end

      # Checks if an armor technique is known at or above a minimum rank
      #
      # @param name [String] The name of the armor technique
      # @param min_rank [Integer] Minimum rank required (defaults to 1)
      # @return [Boolean] True if technique is known at specified rank
      # @example
      #   Armor.known?('blessing', min_rank: 2) #=> true
      def Armor.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        Armor[name] >= min_rank
      end

      # Checks if an armor technique can be afforded (has enough stamina/mana)
      #
      # @param name [String] The name of the armor technique
      # @return [Boolean] True if technique can be afforded
      # @example
      #   Armor.affordable?('blessing') #=> true
      def Armor.affordable?(name)
        return PSMS.assess(name, 'Armor', true)
      end

      # Checks if an armor technique is available for use
      #
      # @param name [String] The name of the armor technique
      # @param min_rank [Integer] Minimum rank required (defaults to 1)
      # @return [Boolean] True if technique is known, affordable, and not on cooldown
      # @example
      #   Armor.available?('blessing') #=> true
      def Armor.available?(name, min_rank: 1)
        Armor.known?(name, min_rank: min_rank) and Armor.affordable?(name) and !Lich::Util.normalize_lookup('Cooldowns', name) and !Lich::Util.normalize_lookup('Debuffs', 'Overexerted')
      end

      # Attempts to use an armor technique
      #
      # @param name [String] The name of the armor technique
      # @param target [String, GameObj, Integer] The target for the technique (optional)
      # @param results_of_interest [Regexp] Additional regex pattern to match in results (optional)
      # @return [String, nil] The result message if successful, nil if technique unavailable
      # @example
      #   Armor.use('blessing', 'my chainmail')
      #   Armor.use('reinforcement', GameObj.right_hand)
      def Armor.use(name, target = "", results_of_interest: nil)
        return unless Armor.available?(name)
        name_normalized = PSMS.name_normal(name)
        technique = @@armor_techniques.fetch(name_normalized)
        usage = technique[:usage]
        return if usage.nil?

        in_cooldown_regex = /^#{name} is still in cooldown\./i

        results_regex = Regexp.union(
          PSMS::FAILURES_REGEXES,
          /^#{name} what\?$/i,
          in_cooldown_regex,
          technique[:regex],
          /^Roundtime: [0-9]+ sec\.$/,
          /^\w+ [a-z]+ not wearing any armor that you can work with\.$/
        )

        if results_of_interest.is_a?(Regexp)
          results_regex = Regexp.union(results_regex, results_of_interest)
        end

        usage_cmd = "armor #{usage}"
        if target.is_a?(GameObj)
          usage_cmd += " ##{target.id}"
        elsif target.is_a?(Integer)
          usage_cmd += " ##{target}"
        elsif target != ""
          usage_cmd += " #{target}"
        end
        waitrt?
        waitcastrt?
        usage_result = dothistimeout usage_cmd, 5, results_regex
        if usage_result == "You don't seem to be able to move to do that."
          100.times { break if clear.any? { |line| line =~ /^You regain control of your senses!$/ }; sleep 0.1 }
          usage_result = dothistimeout usage_cmd, 5, results_regex
        end
        usage_result
      end

      # Gets the regex pattern that matches the success message for an armor technique
      #
      # @param name [String] The name of the armor technique
      # @return [Regexp] The regex pattern for the technique
      # @raise [KeyError] If technique name is not found
      # @example
      #   Armor.regexp('blessing') #=> /As \w+ prays?.../
      def Armor.regexp(name)
        @@armor_techniques.fetch(PSMS.name_normal(name))[:regex]
      end

      # Dynamically generated convenience methods for each armor technique
      # Both long and short names are created (e.g. armor_blessing and blessing)
      #
      # @example
      #   Armor.blessing #=> 3
      #   Armor.armor_blessing #=> 3
      #   Armor.reinforcement #=> 2
      #   Armor.armor_reinforcement #=> 2
      Armor.armor_lookups.each { |armor|
        self.define_singleton_method(armor[:short_name]) do
          Armor[armor[:short_name]]
        end

        self.define_singleton_method(armor[:long_name]) do
          Armor[armor[:short_name]]
        end
      }
    end
  end
end