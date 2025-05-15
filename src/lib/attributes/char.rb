# carve out supporting infomon move to lib

module Lich
  module Common
    class Char
      # Initializes the Char class.
      #
      # @param _blah [Object] Unused parameter.
      # @return [void]
      # @deprecated Char.init is no longer used. Update or fix your script.
      def Char.init(_blah)
        echo 'Char.init is no longer used. Update or fix your script.'
      end

      # Retrieves the name of the character.
      #
      # @return [String] The name of the character.
      # @example
      #   character_name = Char.name
      def Char.name
        XMLData.name
      end

      # Retrieves the stance text of the character.
      #
      # @return [String] The stance text of the character.
      # @example
      #   character_stance = Char.stance
      def Char.stance
        XMLData.stance_text
      end

      # Retrieves the stance value of the character as a percentage.
      #
      # @return [Integer] The percentage of the character's stance.
      # @example
      #   stance_percentage = Char.percent_stance
      def Char.percent_stance
        XMLData.stance_value
      end

      # Retrieves the encumbrance text of the character.
      #
      # @return [String] The encumbrance text of the character.
      # @example
      #   character_encumbrance = Char.encumbrance
      def Char.encumbrance
        XMLData.encumbrance_text
      end

      # Retrieves the encumbrance value of the character as a percentage.
      #
      # @return [Integer] The percentage of the character's encumbrance.
      # @example
      #   encumbrance_percentage = Char.percent_encumbrance
      def Char.percent_encumbrance
        XMLData.encumbrance_value
      end

      # Retrieves the current health of the character.
      #
      # @return [Integer] The current health of the character.
      # @example
      #   current_health = Char.health
      def Char.health
        XMLData.health
      end

      # Retrieves the current mana of the character.
      #
      # @return [Integer] The current mana of the character.
      # @example
      #   current_mana = Char.mana
      def Char.mana
        XMLData.mana
      end

      # Retrieves the current spirit of the character.
      #
      # @return [Integer] The current spirit of the character.
      # @example
      #   current_spirit = Char.spirit
      def Char.spirit
        XMLData.spirit
      end

      # Retrieves the current stamina of the character.
      #
      # @return [Integer] The current stamina of the character.
      # @example
      #   current_stamina = Char.stamina
      def Char.stamina
        XMLData.stamina
      end

      # Retrieves the maximum health of the character.
      #
      # @return [Integer] The maximum health of the character.
      # @example
      #   max_health = Char.max_health
      def Char.max_health
        # Object.module_eval { XMLData.max_health }
        XMLData.max_health
      end

      # Retrieves the maximum health of the character (deprecated).
      #
      # @return [Integer] The maximum health of the character.
      # @deprecated Use Char.max_health instead.
      # @example
      #   max_health = Char.maxhealth
      def Char.maxhealth
        Lich.deprecated("Char.maxhealth", "Char.max_health", caller[0], fe_log: true)
        Char.max_health
      end

      # Retrieves the maximum mana of the character.
      #
      # @return [Integer] The maximum mana of the character.
      # @example
      #   max_mana = Char.max_mana
      def Char.max_mana
        Object.module_eval { XMLData.max_mana }
      end

      # Retrieves the maximum mana of the character (deprecated).
      #
      # @return [Integer] The maximum mana of the character.
      # @deprecated Use Char.max_mana instead.
      # @example
      #   max_mana = Char.maxmana
      def Char.maxmana
        Lich.deprecated("Char.maxmana", "Char.max_mana", caller[0], fe_log: true)
        Char.max_mana
      end

      # Retrieves the maximum spirit of the character.
      #
      # @return [Integer] The maximum spirit of the character.
      # @example
      #   max_spirit = Char.max_spirit
      def Char.max_spirit
        Object.module_eval { XMLData.max_spirit }
      end

      # Retrieves the maximum spirit of the character (deprecated).
      #
      # @return [Integer] The maximum spirit of the character.
      # @deprecated Use Char.max_spirit instead.
      # @example
      #   max_spirit = Char.maxspirit
      def Char.maxspirit
        Lich.deprecated("Char.maxspirit", "Char.max_spirit", caller[0], fe_log: true)
        Char.max_spirit
      end

      # Retrieves the maximum stamina of the character.
      #
      # @return [Integer] The maximum stamina of the character.
      # @example
      #   max_stamina = Char.max_stamina
      def Char.max_stamina
        Object.module_eval { XMLData.max_stamina }
      end

      # Retrieves the maximum stamina of the character (deprecated).
      #
      # @return [Integer] The maximum stamina of the character.
      # @deprecated Use Char.max_stamina instead.
      # @example
      #   max_stamina = Char.maxstamina
      def Char.maxstamina
        Lich.deprecated("Char.maxstamina", "Char.max_stamina", caller[0], fe_log: true)
        Char.max_stamina
      end

      # Retrieves the current health of the character as a percentage.
      #
      # @return [Integer] The percentage of the character's health.
      # @example
      #   health_percentage = Char.percent_health
      def Char.percent_health
        ((XMLData.health.to_f / XMLData.max_health.to_f) * 100).to_i
      end

      # Retrieves the current mana of the character as a percentage.
      #
      # @return [Integer] The percentage of the character's mana.
      # @example
      #   mana_percentage = Char.percent_mana
      def Char.percent_mana
        if XMLData.max_mana == 0
          100
        else
          ((XMLData.mana.to_f / XMLData.max_mana.to_f) * 100).to_i
        end
      end

      # Retrieves the current spirit of the character as a percentage.
      #
      # @return [Integer] The percentage of the character's spirit.
      # @example
      #   spirit_percentage = Char.percent_spirit
      def Char.percent_spirit
        ((XMLData.spirit.to_f / XMLData.max_spirit.to_f) * 100).to_i
      end

      # Retrieves the current stamina of the character as a percentage.
      #
      # @return [Integer] The percentage of the character's stamina.
      # @example
      #   stamina_percentage = Char.percent_stamina
      def Char.percent_stamina
        if XMLData.max_stamina == 0
          100
        else
          ((XMLData.stamina.to_f / XMLData.max_stamina.to_f) * 100).to_i
        end
      end

      # Dumps character information (deprecated).
      #
      # @return [void]
      # @deprecated Char.dump_info is no longer used. Update or fix your script.
      # @example
      #   Char.dump_info
      def Char.dump_info
        echo "Char.dump_info is no longer used. Update or fix your script."
      end

      # Loads character information from a string (deprecated).
      #
      # @param _string [String] The string containing character information.
      # @return [void]
      # @deprecated Char.load_info is no longer used. Update or fix your script.
      # @example
      #   Char.load_info("character data")
      def Char.load_info(_string)
        echo "Char.load_info is no longer used. Update or fix your script."
      end

      # Checks if the character responds to a method.
      #
      # @param m [Symbol] The method name to check.
      # @param args [Array] The arguments to pass to the method.
      # @return [Boolean] True if the character responds to the method, false otherwise.
      # @example
      #   if Char.respond_to?(:health)
      #     puts "Char can respond to health"
      #   end
      def Char.respond_to?(m, *args)
        [Stats, Skills, Spellsong].any? { |k| k.respond_to?(m) } or super(m, *args)
      end

      # Handles missing methods by delegating to Stats, Skills, or Spellsong.
      #
      # @param meth [Symbol] The missing method name.
      # @param args [Array] The arguments to pass to the method.
      # @return [Object] The result of the delegated method call.
      # @raise [NoMethodError] If the method is not found in any of the classes.
      # @example
      #   Char.some_missing_method
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

      # Retrieves character information (deprecated).
      #
      # @return [void]
      # @deprecated Char.info is no longer supported. Update or fix your script.
      # @example
      #   Char.info
      def Char.info
        echo "Char.info is no longer supported. Update or fix your script."
      end

      # Retrieves character skills (deprecated).
      #
      # @return [void]
      # @deprecated Char.skills is no longer supported. Update or fix your script.
      # @example
      #   Char.skills
      def Char.skills
        echo "Char.skills is no longer supported. Update or fix your script."
      end

      # Retrieves the citizenship of the character if the game is GS.
      #
      # @return [String, nil] The citizenship of the character or nil if not applicable.
      # @example
      #   citizenship = Char.citizenship
      def Char.citizenship
        Infomon.get('citizenship') if XMLData.game =~ /^GS/
      end

      # Sets the citizenship of the character (deprecated).
      #
      # @param _val [Object] The value to set for citizenship.
      # @return [void]
      # @deprecated Updating via Char.citizenship is no longer supported. Update or fix your script.
      # @example
      #   Char.citizenship = "New Citizenship"
      def Char.citizenship=(_val)
        echo "Updating via Char.citizenship is no longer supported. Update or fix your script."
      end

      # Retrieves the 'che' value of the character if the game is GS.
      #
      # @return [String, nil] The 'che' value of the character or nil if not applicable.
      # @example
      #   che_value = Char.che
      def Char.che
        Infomon.get('che') if XMLData.game =~ /^GS/
      end
    end
  end
end
