# Carve out from Lich5 for module CharSettings
# 2024-06-13

module Lich
  module Common
    module CharSettings
      
      # Retrieves the value associated with the given setting name.
      #
      # @param name [String] the name of the setting to retrieve
      # @return [Object] the value of the setting, or nil if not found
      # @example
      #   value = CharSettings[:some_setting]
      def CharSettings.[](name)
        Settings.to_hash("#{XMLData.game}:#{XMLData.name}")[name]
      end

      # Sets the value for the given setting name.
      #
      # @param name [String] the name of the setting to set
      # @param value [Object] the value to assign to the setting
      # @return [Object] the value that was set
      # @example
      #   CharSettings[:some_setting] = 'new_value'
      def CharSettings.[]=(name, value)
        Settings.set_script_settings("#{XMLData.game}:#{XMLData.name}", name, value)
      end

      # Converts the character settings to a hash.
      #
      # @return [Hash] a hash representation of the character settings
      # @example
      #   settings_hash = CharSettings.to_hash
      def CharSettings.to_hash
        Settings.to_hash("#{XMLData.game}:#{XMLData.name}")
      end

      # Loads character settings (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is deprecated and not applicable.
      # @example
      #   CharSettings.load
      def CharSettings.load
        Lich.deprecated('CharSettings.load', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Saves character settings (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is deprecated and not applicable.
      # @example
      #   CharSettings.save
      def CharSettings.save
        Lich.deprecated('CharSettings.save', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Saves all character settings (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is deprecated and not applicable.
      # @example
      #   CharSettings.save_all
      def CharSettings.save_all
        Lich.deprecated('CharSettings.save_all', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Clears character settings (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is deprecated and not applicable.
      # @example
      #   CharSettings.clear
      def CharSettings.clear
        Lich.deprecated('CharSettings.clear', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Sets the auto setting (deprecated).
      #
      # @param _val [Object] the value to set (not used)
      # @return [nil] always returns nil
      # @deprecated This method is deprecated and not applicable.
      # @example
      #   CharSettings.auto = true
      def CharSettings.auto=(_val)
        Lich.deprecated('CharSettings.auto=(val)', 'not using, not applicable,', caller[0], fe_log: true)
        return nil
      end

      # Retrieves the auto setting (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is deprecated and not applicable.
      # @example
      #   value = CharSettings.auto
      def CharSettings.auto
        Lich.deprecated('CharSettings.auto', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # Retrieves the autoload setting (deprecated).
      #
      # @return [nil] always returns nil
      # @deprecated This method is deprecated and not applicable.
      # @example
      #   value = CharSettings.autoload
      def CharSettings.autoload
        Lich.deprecated('CharSettings.autoload', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end
    end
  end
end
