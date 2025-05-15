# Module namespace for the Lich game automation system
module Lich
  # Module namespace for Gemstone-specific functionality 
  module Gemstone
    # Handles warcry abilities for warrior characters in Gemstone
    # Provides functionality to check, manage and use warcry combat abilities
    #
    # @author Lich5 Documentation Generator
    class Warcry
      # Returns an array of warcry definitions with their names and costs
      #
      # @return [Array<Hash>] Array of hashes containing warcry definitions with :long_name, :short_name, and :cost keys
      # @example
      #   Warcry.warcry_lookups
      #   # => [{long_name: 'bertrandts_bellow', short_name: 'bellow', cost: 20}, ...]
      def self.warcry_lookups
        [{ long_name: 'bertrandts_bellow',        short_name: 'bellow',         cost: 20 }, # @todo only 10 for single
         { long_name: 'carns_cry',                short_name: 'cry',            cost: 20 },
         { long_name: 'gerrelles_growl',          short_name: 'growl',          cost: 14 }, # @todo only 7 for single
         { long_name: 'horlands_holler',          short_name: 'holler',         cost: 20 },
         { long_name: 'seanettes_shout',          short_name: 'shout',          cost: 20 },
         { long_name: 'yerties_yowlp',            short_name: 'yowlp',          cost: 10 }]
      end

      @@warcries = {
        "bellow" => {
          :regex => /You glare at .+ and let out a nerve-shattering bellow!/,
        },
        "yowlp"  => {
          :regex => /You throw back your shoulders and let out a resounding yowlp!/,
          :buff  => "Yertie's Yowlp",
        },
        "growl"  => {
          :regex => /Your face contorts as you unleash a guttural, deep-throated growl at .+!/,
        },
        "shout"  => {
          :regex => /You let loose an echoing shout!/,
          :buff  => 'Empowered (+20)',
        },
        "cry"    => {
          :regex => /You stare down .+ and let out an eerie, modulating cry!/,
        },
        "holler" => {
          :regex => /You throw back your head and let out a thundering holler!/,
          :buff  => 'Enh. Health (+20)',
        },
      }

      # Gets the rank/level of a specified warcry ability
      #
      # @param name [String] The name of the warcry ability
      # @return [Integer] The rank/level of the warcry ability
      # @example
      #   Warcry['bellow'] # => 3
      def Warcry.[](name)
        return PSMS.assess(name, 'Warcry')
      end

      # Checks if a warcry ability is known at or above a minimum rank
      #
      # @param name [String] The name of the warcry ability
      # @param min_rank [Integer] The minimum rank required (defaults to 1)
      # @return [Boolean] True if the ability is known at sufficient rank
      # @example
      #   Warcry.known?('bellow', min_rank: 2) # => true
      def Warcry.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        Warcry[name] >= min_rank
      end

      # Checks if character has enough resources to use the warcry
      #
      # @param name [String] The name of the warcry ability
      # @return [Boolean] True if the ability can be afforded
      # @example
      #   Warcry.affordable?('bellow') # => true
      def Warcry.affordable?(name)
        return PSMS.assess(name, 'Warcry', true)
      end

      # Checks if a warcry ability can be used (known, affordable, not on cooldown)
      #
      # @param name [String] The name of the warcry ability
      # @param min_rank [Integer] The minimum rank required (defaults to 1)
      # @return [Boolean] True if the ability is available for use
      # @example
      #   Warcry.available?('bellow') # => true
      def Warcry.available?(name, min_rank: 1)
        Warcry.known?(name, min_rank: min_rank) and Warcry.affordable?(name) and !Lich::Util.normalize_lookup('Cooldowns', name) and !Lich::Util.normalize_lookup('Debuffs', 'Overexerted')
      end

      # Checks if a warcry's buff effect is currently active
      #
      # @param name [String] The name of the warcry ability
      # @return [Boolean] True if the buff is active
      # @example
      #   Warcry.buffActive?('shout') # => true
      def Warcry.buffActive?(name)
        buff = @@warcries.fetch(PSMS.name_normal(name))[:buff]
        return false if buff.nil?
        Lich::Util.normalize_lookup('Buffs', buff)
      end

      # Attempts to use a warcry ability
      #
      # @param name [String] The name of the warcry ability
      # @param target [String, GameObj, Integer] The target of the warcry (optional)
      # @param results_of_interest [Regexp] Additional regex pattern to match in results (optional)
      # @return [String, nil] The result message of the warcry attempt or nil if unsuccessful
      # @example
      #   Warcry.use('bellow', monster)
      #   Warcry.use('shout')
      def Warcry.use(name, target = "", results_of_interest: nil)
        return unless Warcry.available?(name)
        return if Warcry.buffActive?(name)
        name_normalized = PSMS.name_normal(name)
        technique = @@warcries.fetch(name_normalized)
        usage = name_normalized
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

        usage_cmd = "warcry #{usage}"
        if target.is_a?(GameObj)
          usage_cmd += " ##{target.id}"
        elsif target.is_a?(Integer)
          usage_cmd += " ##{target}"
        elsif target != ""
          usage_cmd += " #{target}"
        end
        waitrt?
        waitcastrt?
        usage_result = dothistimeout(usage_cmd, 5, results_regex)
        if usage_result == "You don't seem to be able to move to do that."
          100.times { break if clear.any? { |line| line =~ /^You regain control of your senses!$/ }; sleep 0.1 }
          usage_result = dothistimeout(usage_cmd, 5, results_regex)
        end
        usage_result
      end

      # Gets the regex pattern that matches the warcry's success message
      #
      # @param name [String] The name of the warcry ability
      # @return [Regexp] The regex pattern for the warcry's success message
      # @example
      #   Warcry.regexp('bellow') # => /You glare at .+ and let out a nerve-shattering bellow!/
      def Warcry.regexp(name)
        @@warcries.fetch(PSMS.name_normal(name))[:regex]
      end

      # Dynamically generated convenience methods for each warcry
      # Creates methods named after both long and short names that return the warcry's rank
      #
      # @example
      #   Warcry.bellow # => 3
      #   Warcry.bertrandts_bellow # => 3
      #
      # @note These methods are automatically generated for each warcry defined in warcry_lookups
      Warcry.warcry_lookups.each { |warcry|
        self.define_singleton_method(warcry[:short_name]) do
          Warcry[warcry[:short_name]]
        end

        self.define_singleton_method(warcry[:long_name]) do
          Warcry[warcry[:short_name]]
        end
      }
    end
  end
end