# Module containing core Lich functionality
module Lich
  # Common utilities and helper classes 
  module Common
    # Character information and status management class
    # Provides access to character attributes, stats, and status
    #
    # @author Lich5 Documentation Generator
    class Char
      # @deprecated No longer used, prints warning message
      # @param [Object] _blah Unused parameter
      # @return [void]
      def Char.init(_blah)
        echo 'Char.init is no longer used. Update or fix your script.'
      end

      # Gets the character's name
      # @return [String] The character's current name
      # @example
      #   Char.name #=> "Adventurer"
      def Char.name
        XMLData.name
      end

      # Gets the character's current stance text
      # @return [String] Description of current stance (e.g. "standing", "sitting")
      # @example
      #   Char.stance #=> "standing"
      def Char.stance
        XMLData.stance_text
      end

      # Gets the character's stance as a percentage value
      # @return [Integer] Numeric stance value from 0-100
      # @example
      #   Char.percent_stance #=> 100
      def Char.percent_stance
        XMLData.stance_value
      end

      # Gets the character's encumbrance status text
      # @return [String] Description of current encumbrance level
      # @example
      #   Char.encumbrance #=> "burdened"
      def Char.encumbrance
        XMLData.encumbrance_text
      end

      # Gets the character's encumbrance as a percentage
      # @return [Integer] Numeric encumbrance value from 0-100
      # @example
      #   Char.percent_encumbrance #=> 50
      def Char.percent_encumbrance
        XMLData.encumbrance_value
      end

      # Gets current health points
      # @return [Integer] Current HP value
      # @example
      #   Char.health #=> 100
      def Char.health
        XMLData.health
      end

      # Gets current mana points
      # @return [Integer] Current mana value
      # @example
      #   Char.mana #=> 100
      def Char.mana
        XMLData.mana
      end

      # Gets current spirit points
      # @return [Integer] Current spirit value
      # @example
      #   Char.spirit #=> 100
      def Char.spirit
        XMLData.spirit
      end

      # Gets current stamina points
      # @return [Integer] Current stamina value
      # @example
      #   Char.stamina #=> 100
      def Char.stamina
        XMLData.stamina
      end

      # Gets maximum health points
      # @return [Integer] Maximum possible HP
      # @example
      #   Char.max_health #=> 150
      def Char.max_health
        # Object.module_eval { XMLData.max_health }
        XMLData.max_health
      end

      # @deprecated Use Char.max_health instead
      # Gets maximum health points
      # @return [Integer] Maximum possible HP
      def Char.maxhealth
        Lich.deprecated("Char.maxhealth", "Char.max_health", caller[0], fe_log: true)
        Char.max_health
      end

      # Gets maximum mana points
      # @return [Integer] Maximum possible mana
      # @example
      #   Char.max_mana #=> 150
      def Char.max_mana
        Object.module_eval { XMLData.max_mana }
      end

      # @deprecated Use Char.max_mana instead
      # Gets maximum mana points
      # @return [Integer] Maximum possible mana
      def Char.maxmana
        Lich.deprecated("Char.maxmana", "Char.max_mana", caller[0], fe_log: true)
        Char.max_mana
      end

      # Gets maximum spirit points
      # @return [Integer] Maximum possible spirit
      # @example
      #   Char.max_spirit #=> 150
      def Char.max_spirit
        Object.module_eval { XMLData.max_spirit }
      end

      # @deprecated Use Char.max_spirit instead
      # Gets maximum spirit points
      # @return [Integer] Maximum possible spirit
      def Char.maxspirit
        Lich.deprecated("Char.maxspirit", "Char.max_spirit", caller[0], fe_log: true)
        Char.max_spirit
      end

      # Gets maximum stamina points
      # @return [Integer] Maximum possible stamina
      # @example
      #   Char.max_stamina #=> 150
      def Char.max_stamina
        Object.module_eval { XMLData.max_stamina }
      end

      # @deprecated Use Char.max_stamina instead
      # Gets maximum stamina points
      # @return [Integer] Maximum possible stamina
      def Char.maxstamina
        Lich.deprecated("Char.maxstamina", "Char.max_stamina", caller[0], fe_log: true)
        Char.max_stamina
      end

      # Calculates health as percentage of maximum
      # @return [Integer] Percentage of max health (0-100)
      # @example
      #   Char.percent_health #=> 75
      def Char.percent_health
        ((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i
      end

      # Calculates mana as percentage of maximum
      # @return [Integer] Percentage of max mana (0-100)
      # @note Returns 100 if max_mana is 0
      # @example
      #   Char.percent_mana #=> 80
      def Char.percent_mana
        if XMLData.max_mana == 0
          100
        else
          ((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i
        end
      end

      # Calculates spirit as percentage of maximum
      # @return [Integer] Percentage of max spirit (0-100)
      # @example
      #   Char.percent_spirit #=> 90
      def Char.percent_spirit
        ((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i
      end

      # Calculates stamina as percentage of maximum
      # @return [Integer] Percentage of max stamina (0-100)
      # @note Returns 100 if max_stamina is 0
      # @example
      #   Char.percent_stamina #=> 85
      def Char.percent_stamina
        if XMLData.max_stamina == 0
          100
        else
          ((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i
        end
      end

      # @deprecated No longer used, prints warning message
      # @return [void]
      def Char.dump_info
        echo "Char.dump_info is no longer used. Update or fix your script."
      end

      # @deprecated No longer used, prints warning message
      # @param [String] _string Unused parameter
      # @return [void]
      def Char.load_info(_string)
        echo "Char.load_info is no longer used. Update or fix your script."
      end

      # Enhanced respond_to? that checks Stats, Skills and Spellsong
      # @param [Symbol] m Method name to check
      # @param [Array] args Additional arguments
      # @return [Boolean] True if method exists
      def Char.respond_to?(m, *args)
        [Stats, Skills, Spellsong].any? { |k| k.respond_to?(m) } or super(m, *args)
      end

      # Handles method delegation to Stats, Skills and Spellsong
      # @param [Symbol] meth Method name to call
      # @param [Array] args Method arguments
      # @return [Object] Result from delegated call
      # @raise [NoMethodError] If method not found in any class
      def Char.method_missing(meth, *args)
        polyfill = [Stats, Skills, Spellsong].find { |klass|
          klass.respond_to?(meth, *args)
        }
        if polyfill
          Lich.deprecated("Char.#{meth}", "#{polyfill}.#{meth}", caller[0])
          return polyfill.send(meth, *args)
        end
        super(meth, *args)
      end

      # @deprecated No longer supported, prints warning message
      # @return [void]
      def Char.info
        echo "Char.info is no longer supported. Update or fix your script."
      end

      # @deprecated No longer supported, prints warning message
      # @return [void]
      def Char.skills
        echo "Char.skills is no longer supported. Update or fix your script."
      end

      # Gets character citizenship information
      # @return [String, nil] Citizenship status if in GemStone, nil otherwise
      # @example
      #   Char.citizenship #=> "Wehnimer's Landing"
      def Char.citizenship
        Infomon.get('citizenship') if XMLData.game =~ /^GS/
      end

      # @deprecated No longer supported, prints warning message
      # @param [Object] _val Unused parameter
      # @return [void]
      def Char.citizenship=(_val)
        echo "Updating via Char.citizenship is no longer supported. Update or fix your script."
      end

      # Gets character CHE status
      # @return [Object, nil] CHE information if in GemStone, nil otherwise
      # @example
      #   Char.che #=> "some_value"
      def Char.che
        Infomon.get('che') if XMLData.game =~ /^GS/
      end
    end
  end
end