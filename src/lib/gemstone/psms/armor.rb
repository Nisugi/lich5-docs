## breakout for Armor released with PSM3
## updated for Ruby 3.2.1 and new Infomon module

module Lich
  module Gemstone
    module Armor
      # rubocop:disable Layout/ExtraSpacing
      
      # Retrieves a list of armor lookups with their long names, short names, and costs.
      #
      # @return [Array<Hash>] An array of hashes containing armor attributes.
      #   Each hash includes :long_name, :short_name, and :cost.
      #
      # @example
      #   Armor.armor_lookups
      #   # => [{ long_name: 'armor_blessing', short_name: 'blessing', cost: 0 }, ...]
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

      # Retrieves the armor technique based on the name.
      #
      # @param name [String] The name of the armor technique.
      # @return [Hash] The armor technique details including regex and usage.
      # @raise [KeyError] If the armor technique does not exist.
      #
      # @example
      #   Armor["armor_blessing"]
      #   # => { regex: /As \w+ prays? over \w+(?:'s)? [\w\s]+, .../, usage: "blessing" }
      def Armor.[](name)
        return PSMS.assess(name, 'Armor')
      end

      # Checks if the specified armor technique is known at or above the minimum rank.
      #
      # @param name [String] The name of the armor technique.
      # @param min_rank [Integer] The minimum rank to check against (default is 1).
      # @return [Boolean] True if the armor technique is known at the specified rank or higher, false otherwise.
      #
      # @example
      #   Armor.known?("armor_blessing", min_rank: 2)
      #   # => true or false
      def Armor.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        Armor[name] >= min_rank
      end

      # Checks if the specified armor technique is affordable.
      #
      # @param name [String] The name of the armor technique.
      # @return [Boolean] True if the armor technique is affordable, false otherwise.
      #
      # @example
      #   Armor.affordable?("armor_blessing")
      #   # => true or false
      def Armor.affordable?(name)
        return PSMS.assess(name, 'Armor', true)
      end

      # Checks if the specified armor technique is available for use.
      #
      # @param name [String] The name of the armor technique.
      # @param min_rank [Integer] The minimum rank to check against (default is 1).
      # @return [Boolean] True if the armor technique is known, affordable, and not on cooldown or debuffed, false otherwise.
      #
      # @example
      #   Armor.available?("armor_blessing", min_rank: 1)
      #   # => true or false
      def Armor.available?(name, min_rank: 1)
        Armor.known?(name, min_rank: min_rank) and Armor.affordable?(name) and !Lich::Util.normalize_lookup('Cooldowns', name) and !Lich::Util.normalize_lookup('Debuffs', 'Overexerted')
      end

      # Uses the specified armor technique on a target.
      #
      # @param name [String] The name of the armor technique.
      # @param target [String, GameObj, Integer] The target to use the technique on (optional).
      # @param results_of_interest [Regexp, nil] Additional regex to match results (optional).
      # @return [String, nil] The result of the usage or nil if not available.
      #
      # @example
      #   Armor.use("armor_blessing", "target_name")
      #   # => "You bless the target with armor."
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

      # Retrieves the regex pattern for the specified armor technique.
      #
      # @param name [String] The name of the armor technique.
      # @return [Regexp] The regex pattern associated with the armor technique.
      # @raise [KeyError] If the armor technique does not exist.
      #
      # @example
      #   Armor.regexp("armor_blessing")
      #   # => /As \w+ prays? over \w+(?:'s)? [\w\s]+, .../
      def Armor.regexp(name)
        @@armor_techniques.fetch(PSMS.name_normal(name))[:regex]
      end

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