# Namespace module for the Lich game automation system
module Lich
  # Module containing Gemstone-specific functionality
  module Gemstone
    # Manages and tracks various types of effects in the game including spells, buffs, debuffs, and cooldowns
    module Effects
      # Registry class for managing collections of timed effects
      #
      # @author Lich5 Documentation Generator
      class Registry
        include Enumerable

        # Initializes a new Registry instance for a specific dialog type
        #
        # @param dialog [String] The name of the dialog to track ("Active Spells", "Buffs", etc)
        # @return [Registry] A new Registry instance
        def initialize(dialog)
          @dialog = dialog
        end

        # Converts the registry to a hash of effects and their expiration times
        #
        # @return [Hash] Key-value pairs where keys are effect identifiers and values are expiration timestamps
        def to_h
          XMLData.dialogs.fetch(@dialog, {})
        end

        # Implements the Enumerable interface for iterating over effects
        #
        # @yield [key, value] Yields each effect and its expiration time
        # @yieldparam key [String, Integer] The effect identifier
        # @yieldparam value [Float] The effect's expiration timestamp
        # @return [Enumerator] If no block given
        def each()
          to_h.each { |k, v| yield(k, v) }
        end

        # Gets the expiration time for a specific effect
        #
        # @param effect [String, Integer, Regexp] The effect identifier or pattern to match
        # @return [Float] The expiration timestamp, or 0 if not found
        # @example
        #   registry.expiration("Strength") #=> 1634567890.0
        #   registry.expiration(/Strength/) #=> 1634567890.0
        def expiration(effect)
          if effect.is_a?(Regexp)
            to_h.find { |k, _v| k.to_s =~ effect }[1] || 0
          else
            to_h.fetch(effect, 0)
          end
        end

        # Checks if an effect is currently active
        #
        # @param effect [String, Integer, Regexp] The effect to check
        # @return [Boolean] true if the effect is active (not expired), false otherwise
        # @example
        #   registry.active?("Shield") #=> true
        def active?(effect)
          expiration(effect).to_f > Time.now.to_f
        end

        # Calculates the remaining time for an effect in minutes
        #
        # @param effect [String, Integer, Regexp] The effect to check
        # @return [Float] Minutes remaining for the effect, or 0 if not active
        # @example
        #   registry.time_left("Shield") #=> 5.5 # 5.5 minutes remaining
        def time_left(effect)
          if expiration(effect) != 0
            ((expiration(effect) - Time.now) / 60.to_f)
          else
            expiration(effect)
          end
        end
      end

      # Registry for active spells
      # @return [Registry]
      Spells    = Registry.new("Active Spells")

      # Registry for active buffs
      # @return [Registry]
      Buffs     = Registry.new("Buffs")

      # Registry for active debuffs
      # @return [Registry]
      Debuffs   = Registry.new("Debuffs")

      # Registry for active cooldowns
      # @return [Registry]
      Cooldowns = Registry.new("Cooldowns")

      # Displays a formatted table of all active effects
      #
      # @return [void]
      # @note Creates a table showing all active spells, cooldowns, buffs, and debuffs
      #   with their IDs, types, names, and remaining durations
      # @example
      #   Effects.display
      #   # Outputs:
      #   # +-----+------------+-----------------+----------+
      #   # | ID  | Type       | Name            | Duration |
      #   # +-----+------------+-----------------+----------+
      #   # | 101 | Spells     | Shield         | 5:30     |
      #   # | 202 | Buffs      | Strength       | 10:15    |
      #   # +-----+------------+-----------------+----------+
      def self.display
        effect_out = Terminal::Table.new :headings => ["ID", "Type", "Name", "Duration"]
        titles = ["Spells", "Cooldowns", "Buffs", "Debuffs"]
        existing_spell_nums = []
        active_spells = Spell.active
        active_spells.each { |s| existing_spell_nums << s.num }
        circle = nil
        [Effects::Spells, Effects::Cooldowns, Effects::Buffs, Effects::Debuffs].each { |effect|
          title = titles.shift
          id_effects = effect.to_h.select { |k, _v| k.is_a?(Integer) }
          text_effects = effect.to_h.reject { |k, _v| k.is_a?(Integer) }
          if id_effects.length != text_effects.length
            # has spell names disabled
            text_effects = id_effects
          end
          if id_effects.length == 0
            effect_out.add_row ["", title, "No #{title.downcase} found!", ""]
          else
            id_effects.each { |sn, end_time|
              stext = text_effects.shift[0]
              duration = ((end_time - Time.now) / 60.to_f)
              if duration < 0
                next
              elsif duration > 86400
                duration = "Indefinite"
              else
                duration = duration.as_time
              end
              if Spell[sn].circlename && circle != Spell[sn].circlename && title == 'Spells'
                circle = Spell[sn].circlename
              end
              effect_out.add_row [sn, title, stext, duration]
              existing_spell_nums.delete_if { |s| Spell[s].name =~ /#{Regexp.escape(stext)}/ || stext =~ /#{Regexp.escape(Spell[s].name)}/ || s == sn }
            }
          end
          effect_out.add_separator unless title == 'Debuffs' && existing_spell_nums.empty?
        }
        existing_spell_nums.each { |sn|
          effect_out.add_row [sn, "Other", Spell[sn].name, (Spell[sn].timeleft.as_time)]
        }
        Lich::Messaging.mono(effect_out.to_s)
      end
    end
  end
end