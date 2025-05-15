# Carve out from Lich 5 for module GameSettings
# 2024-06-13

module Lich
  module Common
    module GameSettings
      
      # Retrieves the value associated with the given setting name.
      #
      # @param name [String] the name of the setting to retrieve
      # @return [Object] the value of the setting
      # @example
      #   value = GameSettings[:some_setting]
      def GameSettings.[](name)
        Settings.to_hash(XMLData.game)[name]
      end

      # Sets the value for the given setting name.
      #
      # @param name [String] the name of the setting to set
      # @param value [Object] the value to assign to the setting
      # @return [Object] the value that was set
      # @example
      #   GameSettings[:some_setting] = 'new_value'
      def GameSettings.[]=(name, value)
        Settings.set_script_settings(XMLData.game, name, value)
      end

      # Converts the game settings to a hash.
      #
      # @return [Hash] a hash representation of the game settings
      # @example
      #   settings_hash = GameSettings.to_hash
      def GameSettings.to_hash
        Settings.to_hash(XMLData.game)
      end

      # Loads game settings (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is no longer applicable.
      # @example
      #   GameSettings.load
      def GameSettings.load
        Lich.deprecated('GameSettings.load', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Saves game settings (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is no longer applicable.
      # @example
      #   GameSettings.save
      def GameSettings.save
        Lich.deprecated('GameSettings.save', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Saves all game settings (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is no longer applicable.
      # @example
      #   GameSettings.save_all
      def GameSettings.save_all
        Lich.deprecated('GameSettings.save_all', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Clears game settings (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is no longer applicable.
      # @example
      #   GameSettings.clear
      def GameSettings.clear
        Lich.deprecated('GameSettings.clear', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Sets the auto setting (deprecated).
      #
      # @param _val [Object] the value to set for auto (not used)
      # @return [nil] always returns nil
      # @deprecated This method is no longer applicable.
      # @example
      #   GameSettings.auto = true
      def GameSettings.auto=(_val)
        Lich.deprecated('GameSettings.auto=(val)', 'not using, not applicable,', caller[0], fe_log: true)
        return nil
      end

      # Retrieves the auto setting (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is no longer applicable.
      # @example
      #   auto_value = GameSettings.auto
      def GameSettings.auto
        Lich.deprecated('GameSettings.auto', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Retrieves the autoload setting (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is no longer applicable.
      # @example
      #   autoload_value = GameSettings.autoload
      def GameSettings.autoload
        Lich.deprecated('GameSettings.autoload', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end
    end
  end
end
