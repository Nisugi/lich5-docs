## breakout for CMan released with PSM3
## updated for Ruby 3.2.1 and new Infomon module

# Combat Maneuvers (CMan) system for managing combat abilities in Gemstone IV
#
# This module provides functionality for checking, using and managing combat maneuvers,
# including checking availability, costs, and executing maneuvers against targets.
#
# @author Lich5 Documentation Generator
module Lich
  module Gemstone
    module CMan
      # Returns an array of combat maneuver lookup data containing long names, short names and costs
      #
      # @return [Array<Hash>] Array of hashes containing :long_name, :short_name, and :cost for each maneuver
      def self.cman_lookups
        [{ long_name: 'acrobats_leap',           short_name: 'acrobatsleap',     cost:  0 },
         { long_name: 'bearhug',                 short_name: 'bearhug',          cost: 10 },
         # ... rest of the lookup array ...
         { long_name: 'whirling_dervish',        short_name: 'dervish',          cost: 20 }]
      end

      # Hash containing detailed information about each combat maneuver including cost, type, regex patterns and usage
      #
      # @private
      @@combat_mans = {
        "acrobats_leap"          => {
          :cost  => 0,
          :type  => "passive",
          :regex => /The Acrobat\'s Leap combat maneuver is always active once you have learned it\./,
          :usage => nil
        },
        # ... rest of the combat_mans hash ...
      }

      # Gets the rank/level of a specified combat maneuver
      #
      # @param name [String] The name of the combat maneuver to check
      # @return [Integer] The rank/level of the maneuver, 0 if not known
      def CMan.[](name)
        return PSMS.assess(name, 'CMan')
      end

      # Checks if a combat maneuver is known at or above a minimum rank
      #
      # @param name [String] The name of the combat maneuver to check
      # @param min_rank [Integer] The minimum rank required (defaults to 1)
      # @return [Boolean] True if known at or above min_rank, false otherwise
      def CMan.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        CMan[name] >= min_rank
      end

      # Checks if a combat maneuver can be afforded based on current stamina
      #
      # @param name [String] The name of the combat maneuver to check
      # @return [Boolean] True if the maneuver can be afforded, false otherwise
      def CMan.affordable?(name)
        return PSMS.assess(name, 'CMan', true)
      end

      # Checks if a combat maneuver is available for use based on rank, cost and cooldown
      #
      # @param name [String] The name of the combat maneuver to check
      # @param ignore_cooldown [Boolean] Whether to ignore cooldown restrictions
      # @param min_rank [Integer] Minimum rank required (defaults to 1)
      # @return [Boolean] True if the maneuver is available for use, false otherwise
      # @note Some maneuvers cannot have their cooldowns ignored even with ignore_cooldown=true
      def CMan.available?(name, ignore_cooldown: false, min_rank: 1)
        return false unless CMan.known?(name, min_rank: min_rank)
        return false unless CMan.affordable?(name)
        return false if Lich::Util.normalize_lookup('Cooldowns', name) unless ignore_cooldown && @@combat_mans.fetch(PSMS.name_normal(name))[:ignorable_cooldown]
        return false if Lich::Util.normalize_lookup('Debuffs', 'Overexerted')
        return true
      end

      # Attempts to use a combat maneuver on a target
      #
      # @param name [String] The name of the combat maneuver to use
      # @param target [String, GameObj, Integer] The target to use the maneuver on
      # @param ignore_cooldown [Boolean] Whether to ignore cooldown restrictions
      # @param results_of_interest [Regexp] Additional regex patterns to match in results
      # @return [String, nil] The result message from using the maneuver, or nil if unsuccessful
      # @example
      #   CMan.use('sweep', monster) 
      #   CMan.use('disarm', '#12345')
      def CMan.use(name, target = "", ignore_cooldown: false, results_of_interest: nil)
        return unless CMan.available?(name, ignore_cooldown: ignore_cooldown)
        name_normalized = PSMS.name_normal(name)
        technique = @@combat_mans.fetch(name_normalized)
        usage = technique[:usage]
        return if usage.nil?

        in_cooldown_regex = /^#{name} is still in cooldown\./i

        results_regex = Regexp.union(
          PSMS::FAILURES_REGEXES,
          /^#{name} what\?$/i,
          in_cooldown_regex,
          technique[:regex],
          /^Roundtime: [0-9]+ sec\.$/,
        )

        if results_of_interest.is_a?(Regexp)
          results_regex = Regexp.union(results_regex, results_of_interest)
        end

        usage_cmd = "cman #{usage}"
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

      # Gets the regex pattern that matches successful use of a combat maneuver
      #
      # @param name [String] The name of the combat maneuver
      # @return [Regexp] The regex pattern matching successful use
      def CMan.regexp(name)
        @@combat_mans.fetch(PSMS.name_normal(name))[:regex]
      end

      # For each combat maneuver, creates convenience methods using both long and short names
      # that return the maneuver's rank
      #
      # @example
      #   CMan.sweep #=> Returns rank of sweep maneuver
      #   CMan.groin_kick #=> Returns rank of groin kick maneuver
      # @note These are dynamically generated for all maneuvers in cman_lookups
      CMan.cman_lookups.each { |cman|
        self.define_singleton_method(cman[:short_name]) do
          CMan[cman[:short_name]]
        end

        self.define_singleton_method(cman[:long_name]) do
          CMan[cman[:short_name]]
        end
      }
    end
  end
end