## breakout for Weapon released with PSM3
## updated for Ruby 3.2.1 and new Infomon module

# Module for handling weapon techniques and abilities in the Gemstone game
# Provides functionality for checking, using and managing combat weapon skills
#
# @author Lich5 Documentation Generator
module Lich
  module Gemstone
    module Weapon
      # Returns an array of weapon technique definitions with their names and costs
      #
      # @return [Array<Hash>] Array of hashes containing :long_name, :short_name, and :cost for each technique
      #
      # @example
      #   Weapon.weapon_lookups
      #   # => [{long_name: 'barrage', short_name: 'barrage', cost: 15}, ...]
      def self.weapon_lookups
        # rubocop:disable Layout/ExtraSpacing
        [{ long_name: 'barrage',                  short_name: 'barrage',          cost: 15 },
         { long_name: 'charge',                   short_name: 'charge',           cost: 14 },
         { long_name: 'clash',			              short_name: 'clash',			      cost: 20 },
         { long_name: 'clobber',			            short_name: 'clobber',			    cost:  0 },
         { long_name: 'cripple',			            short_name: 'cripple',			    cost:  7 },
         { long_name: 'cyclone',			            short_name: 'cyclone',			    cost: 20 },
         { long_name: 'dizzying_swing',			      short_name: 'dizzyingswing',    cost:  7 },
         { long_name: 'flurry',			              short_name: 'flurry',			      cost: 15 },
         { long_name: 'fury',			                short_name: 'fury',			        cost: 15 },
         { long_name: 'guardant_thrusts',         short_name: 'gthrusts',         cost: 15 },
         { long_name: 'overpower',                short_name: 'overpower',        cost:  0 },
         { long_name: 'pin_down',                 short_name: 'pindown',			    cost: 14 },
         { long_name: 'pulverize',                short_name: 'pulverize',			  cost: 20 },
         { long_name: 'pummel',			              short_name: 'pummel',           cost: 15 },
         { long_name: 'radial_sweep',			        short_name: 'radialsweep',      cost:  0 },
         { long_name: 'reactive_shot',            short_name: 'reactiveshot',     cost:  0 },
         { long_name: 'reverse_strike',           short_name: 'reversestrike',    cost:  0 },
         { long_name: 'riposte',			            short_name: 'riposte',          cost:  0 },
         { long_name: 'spin_kick',			          short_name: 'spinkick',         cost:  0 },
         { long_name: 'thrash',                   short_name: 'thrash',           cost: 15 },
         { long_name: 'twin_hammerfists',         short_name: 'twinhammer',       cost:  7 },
         { long_name: 'volley',			              short_name: 'volley',           cost: 20 },
         { long_name: 'whirling_blade',			      short_name: 'wblade',           cost: 20 },
         { long_name: 'whirlwind',                short_name: 'whirlwind',        cost: 20 }]
        # rubocop:enable Layout/ExtraSpacing
      end

      @@weapon_techniques = {
        "barrage"          => {
          :regex      => /Drawing several (?:arrows|bolts) from your .+, you grip them loosely between your fingers in preparation for a rapid barrage\./,
          :assault_rx => /Your satisfying display of dexterity bolsters you and inspires those around you\!/,
          :buff       => "Enh. Dexterity (+10)",
        },
        "charge"           => {
          :regex => /You rush forward at .+ with your .+ and attempt a charge\!/,
        },
        "clash"            => {
          :regex => /Steeling yourself for a brawl, you plunge into the fray\!/,
        },
        "clobber"          => {
          :regex => /You redirect the momentum of your parry, hauling your .+ around to clobber .+\!/,
        },
        "cripple"          => {
          :regex => /You reverse your grip on your .+ and dart toward .+ at an angle\!/,
        },
        "cyclone"          => {
          :regex => /You weave your .+ in an under arm spin, swiftly picking up speed until it becomes a blurred cyclone of .+\!/,
        },
        "dizzying_swing"   => {
          :regex => /You heft your .+ and, looping it once to build momentum, lash out in a strike at .+ head\!/,
          :usage => "dizzyingswing",
        },
        "flurry"           => {
          :regex      => /You rotate your wrist, your .+ executing a casual spin to establish your flow as you advance upon .+\!/,
          :assault_rx => /The mesmerizing sway of body and blade glides to its inevitable end with one final twirl of your .+\./,
          :buff       => "Slashing Strikes",
        },
        "fury"             => {
          :regex      => /With a percussive snap, you shake out your arms in quick succession and bear down on .+ in a fury\!/,
          :assault_rx => /Your furious assault bolsters you and inspires those around you\!/,
          :buff       => "Enh. Constitution (+10)",
        },
        "guardant_thrusts" => {
          :regex => /Retaining a defensive profile, you raise your .+ in a hanging guard and prepare to unleash a barrage of guardant thrusts upon .+\!/,
          :usage => "gthrusts",
        },
        "overpower"        => {
          :regex => /On the heels of .+ parry, you erupt into motion, determined to overpower .+ defenses\!/,
        },
        "pin_down"         => {
          :regex => /You take quick assessment and raise your .+, several (?:arrows|bolts) nocked to your string in parallel\./,
          :usage => "pindown",
        },
        "pulverize"        => {
          :regex => /You wheel your .+ overhead before slamming it around in a wide arc to pulverize your foes\!/,
        },
        "pummel"           => {
          :regex      => /You take a menacing step toward .+, sweeping your .+ out low to your side in your advance\./,
          :assault_rx => /With a final snap of your wrist, you sweep your .+ back to the ready, your assault complete\./,
          :buff       => "Concussive Blows",
        },
        "radial_sweep"     => {
          :regex => /Crouching low, you sweep your .+ in a broad arc\!/,
          :usage => "radialsweep",
        },
        "reactive_shot"    => {
          :regex => /You fire off a quick shot at the .+, then make a hasty retreat\!/,
          :usage => "reactiveshot",
        },
        "reverse_strike"   => {
          :regex => /Spotting an opening in .+ defenses, you quickly reverse the direction of your .+ and strike from a different angle\!/,
          :usage => "reversestrike",
        },
        "riposte"          => {
          :regex => /Before .+ can recover, you smoothly segue from parry to riposte\!/,
        },
        "spin_kick"        => {
          :regex => /Stepping with deliberation, you wheel into a leaping spin\!/,
          :usage => "spinkick",
        },
        "thrash"           => {
          :regex => /You rush .+, raising your .+ high to deliver a sound thrashing\!/,
        },
        "twin_hammerfists" => {
          :regex => /You raise your hands high, lace them together and bring them crashing down towards the .+\!/,
          :usage => "twinhammer",
        },
        "volley"           => {
          :regex => /Raising your .+ high, you loose (?:arrow|bolt) after (?:arrow|bolt) as fast as you can, filling the sky with a volley of deadly projectiles\!/,
        },
        "whirling_blade"   => {
          :regex => /With a broad flourish, you sweep your .+ into a whirling display of keen-edged menace\!/,
          :usage => "wblade",
        },
        "whirlwind"        => {
          :regex => /Twisting and spinning among your foes, you lash out again and again with the force of a reaping whirlwind\!/,
        },
      }

      # Retrieves the rank/level of a specified weapon technique
      #
      # @param name [String] The name of the weapon technique
      # @return [Integer] The rank/level of the technique
      # @example
      #   Weapon['barrage'] # => 3
      def Weapon.[](name)
        return PSMS.assess(name, 'Weapon')
      end

      # Checks if a weapon technique is known at or above a minimum rank
      #
      # @param name [String] The name of the weapon technique
      # @param min_rank [Integer] Minimum rank required (defaults to 1)
      # @return [Boolean] True if technique is known at specified rank
      # @example
      #   Weapon.known?('barrage', min_rank: 2) # => true
      def Weapon.known?(name, min_rank: 1)
        min_rank = 1 unless min_rank >= 1 # in case a 0 or below is passed
        Weapon[name] >= min_rank
      end

      # Checks if a weapon technique can be afforded with current resources
      #
      # @param name [String] The name of the weapon technique
      # @return [Boolean] True if technique can be afforded
      # @example
      #   Weapon.affordable?('barrage') # => true
      def Weapon.affordable?(name)
        return PSMS.assess(name, 'Weapon', true)
      end

      # Checks if a weapon technique is available for use
      #
      # @param name [String] The name of the weapon technique
      # @param min_rank [Integer] Minimum rank required (defaults to 1)
      # @return [Boolean] True if technique is known, affordable, not on cooldown and not overexerted
      # @example
      #   Weapon.available?('barrage') # => true
      def Weapon.available?(name, min_rank: 1)
        Weapon.known?(name, min_rank: min_rank) and Weapon.affordable?(name) and !Lich::Util.normalize_lookup('Cooldowns', name) and !Lich::Util.normalize_lookup('Debuffs', 'Overexerted')
      end

      # Checks if a weapon technique's buff effect is currently active
      #
      # @param name [String] The name of the weapon technique
      # @return [Boolean, nil] True if buff is active, nil if technique has no buff
      # @example
      #   Weapon.active?('flurry') # => true
      def Weapon.active?(name)
        name = PSMS.name_normal(name)
        return unless @@weapon_techniques.fetch(name).key?(:buff)
        Effects::Buffs.active?(@@weapon_techniques.fetch(name)[:buff])
      end

      # Executes a weapon technique against an optional target
      #
      # @param name [String] The name of the weapon technique
      # @param target [String, GameObj, Integer] The target of the technique (optional)
      # @param results_of_interest [Regexp] Additional regex pattern to match in results (optional)
      # @return [String, nil] The result of the technique execution or nil if unavailable
      # @example
      #   Weapon.use('barrage', monster)
      #   Weapon.use('flurry', '#1234')
      #
      # @note Will wait for roundtime and casting roundtime before executing
      def Weapon.use(name, target = "", results_of_interest: nil)
        return unless Weapon.available?(name)
        name_normalized = PSMS.name_normal(name)
        technique = @@weapon_techniques.fetch(name_normalized)
        usage = technique.key?(:usage) ? technique[:usage] : name_normalized
        return if usage.nil?

        in_cooldown_regex = /^#{name} is still in cooldown\./i

        results_regex = Regexp.union(
          PSMS::FAILURES_REGEXES,
          /^#{name} what\?$/i,
          in_cooldown_regex
        )

        if results_of_interest.is_a?(Regexp)
          results_regex = Regexp.union(results_regex, results_of_interest)
        end

        usage_cmd = "weapon #{usage}"
        if target.is_a?(GameObj)
          usage_cmd += " ##{target.id}"
        elsif target.is_a?(Integer)
          usage_cmd += " ##{target}"
        elsif target != ""
          usage_cmd += " #{target}"
        end
        usage_result = nil
        if (technique.key?(:assault_rx))
          results_regex = Regexp.union(results_regex, technique[:assault_rx])
          break_out = Time.now() + 12
          loop {
            usage_result = dothistimeout(usage_cmd, 10, results_regex)
            if usage_result =~ /\.\.\.wait/i
              waitrt?
              next
            elsif usage_result =~ technique[:assault_rx] || Time.now() > break_out
              break
            elsif usage_result == false || usage_result =~ in_cooldown_regex
              break
            end
            sleep 0.25
          }
        else
          results_regex = Regexp.union(results_regex, technique[:regex], /^Roundtime: [0-9]+ sec\.$/)
          waitrt?
          waitcastrt?
          usage_result = dothistimeout(usage_cmd, 5, results_regex)
          if usage_result == "You don't seem to be able to move to do that."
            100.times { break if clear.any? { |line| line =~ /^You regain control of your senses!$/ }; sleep 0.1 }
            usage_result = dothistimeout(usage_cmd, 5, results_regex)
          end
        end
        usage_result
      end

      # Gets the regex pattern that matches the technique's execution message
      #
      # @param name [String] The name of the weapon technique
      # @return [Regexp] The regex pattern for the technique
      # @example
      #   Weapon.regexp('barrage')
      #   # => /Drawing several (?:arrows|bolts) from your .+, you grip them loosely.../
      def Weapon.regexp(name)
        @@weapon_techniques.fetch(PSMS.name_normal(name))[:regex]
      end

      # For each weapon technique, creates convenience methods using both long and short names
      # that return the technique's rank
      #
      # @example
      #   Weapon.barrage # => 3
      #   Weapon.dizzying_swing # => 2
      Weapon.weapon_lookups.each { |weapon|
        self.define_singleton_method(weapon[:short_name]) do
          Weapon[weapon[:short_name]]
        end

        self.define_singleton_method(weapon[:long_name]) do
          Weapon[weapon[:short_name]]
        end
      }
    end
  end
end