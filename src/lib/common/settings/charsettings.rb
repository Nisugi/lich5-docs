# Carve out from Lich5 for module CharSettings
# 2024-06-13

# Module for managing character-specific settings in Lich5.
# Provides methods to store and retrieve settings specific to a character/game combination.
#
# @author Lich5 Documentation Generator
module Lich
  module Common
    module CharSettings
      # Retrieves a character-specific setting value by name
      #
      # @param name [Symbol, String] The name of the setting to retrieve
      # @return [Object] The value of the requested setting
      # @example
      #   CharSettings[:my_setting] # Returns value for current character/game
      def CharSettings.[](name)
        Settings.to_hash("#{XMLData.game}:#{XMLData.name}")[name]
      end

      # Sets a character-specific setting value
      #
      # @param name [Symbol, String] The name of the setting to set
      # @param value [Object] The value to store
      # @return [Object] The value that was set
      # @example
      #   CharSettings[:my_setting] = "new value"
      def CharSettings.[]=(name, value)
        Settings.set_script_settings("#{XMLData.game}:#{XMLData.name}", name, value)
      end

      # Returns all character-specific settings as a hash
      #
      # @return [Hash] All settings for the current character/game combination
      # @example
      #   settings = CharSettings.to_hash
      def CharSettings.to_hash
        Settings.to_hash("#{XMLData.game}:#{XMLData.name}")
      end

      # @deprecated No longer applicable in current version
      # @note This method is deprecated and will be removed in a future version
      # @return [nil]
      def CharSettings.load
        Lich.deprecated('CharSettings.load', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # @deprecated No longer applicable in current version
      # @note This method is deprecated and will be removed in a future version
      # @return [nil]
      def CharSettings.save
        Lich.deprecated('CharSettings.save', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # @deprecated No longer applicable in current version
      # @note This method is deprecated and will be removed in a future version
      # @return [nil]
      def CharSettings.save_all
        Lich.deprecated('CharSettings.save_all', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # @deprecated No longer applicable in current version
      # @note This method is deprecated and will be removed in a future version
      # @return [nil]
      def CharSettings.clear
        Lich.deprecated('CharSettings.clear', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # @deprecated No longer applicable in current version
      # @param val [Object] Ignored parameter
      # @note This method is deprecated and will be removed in a future version
      # @return [nil]
      def CharSettings.auto=(_val)
        Lich.deprecated('CharSettings.auto=(val)', 'not using, not applicable,', caller[0], fe_log: true)
        return nil
      end

      # @deprecated No longer applicable in current version
      # @note This method is deprecated and will be removed in a future version
      # @return [nil]
      def CharSettings.auto
        Lich.deprecated('CharSettings.auto', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # @deprecated No longer applicable in current version
      # @note This method is deprecated and will be removed in a future version
      # @return [nil]
      def CharSettings.autoload
        Lich.deprecated('CharSettings.autoload', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end
    end
  end
end