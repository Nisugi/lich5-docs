# Carve out from Lich 5 for module GameSettings
# 2024-06-13

module Lich
  module Common
    # GameSettings module provides game-specific settings management functionality for Lich5.
    # It allows storing and retrieving settings specific to the current game context.
    #
    # @author Lich5 Documentation Generator
    module GameSettings
      # Retrieves a game setting value by name
      #
      # @param name [Symbol, String] The name/key of the setting to retrieve
      # @return [Object] The value associated with the setting name
      # @example
      #   GameSettings[:combat_style] #=> "aggressive"
      #   GameSettings["spell_prep_time"] #=> 5
      def GameSettings.[](name)
        Settings.to_hash(XMLData.game)[name]
      end

      # Sets a game setting value
      #
      # @param name [Symbol, String] The name/key of the setting to set
      # @param value [Object] The value to store for this setting
      # @return [Object] The value that was set
      # @example
      #   GameSettings[:combat_style] = "defensive"
      #   GameSettings["spell_prep_time"] = 3
      def GameSettings.[]=(name, value)
        Settings.set_script_settings(XMLData.game, name, value)
      end

      # Returns all game settings as a hash
      #
      # @return [Hash] Hash containing all current game settings
      # @example
      #   GameSettings.to_hash #=> {:combat_style => "defensive", :spell_prep_time => 3}
      def GameSettings.to_hash
        Settings.to_hash(XMLData.game)
      end

      # [DEPRECATED] Legacy method for loading settings
      #
      # @deprecated Use direct setting access instead
      # @return [nil]
      # @note This method is deprecated and will log a warning when used
      def GameSettings.load
        Lich.deprecated('GameSettings.load', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # [DEPRECATED] Legacy method for saving settings
      #
      # @deprecated Use direct setting access instead
      # @return [nil]
      # @note This method is deprecated and will log a warning when used
      def GameSettings.save
        Lich.deprecated('GameSettings.save', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # [DEPRECATED] Legacy method for saving all settings
      #
      # @deprecated Use direct setting access instead
      # @return [nil]
      # @note This method is deprecated and will log a warning when used
      def GameSettings.save_all
        Lich.deprecated('GameSettings.save_all', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # [DEPRECATED] Legacy method for clearing settings
      #
      # @deprecated Use direct setting access instead
      # @return [nil]
      # @note This method is deprecated and will log a warning when used
      def GameSettings.clear
        Lich.deprecated('GameSettings.clear', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # [DEPRECATED] Legacy method for setting auto mode
      #
      # @deprecated No longer applicable
      # @param _val [Object] Ignored parameter
      # @return [nil]
      # @note This method is deprecated and will log a warning when used
      def GameSettings.auto=(_val)
        Lich.deprecated('GameSettings.auto=(val)', 'not using, not applicable,', caller[0], fe_log: true)
        return nil
      end

      # [DEPRECATED] Legacy method for getting auto mode
      #
      # @deprecated No longer applicable
      # @return [nil]
      # @note This method is deprecated and will log a warning when used
      def GameSettings.auto
        Lich.deprecated('GameSettings.auto', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end

      # [DEPRECATED] Legacy method for autoloading
      #
      # @deprecated No longer applicable
      # @return [nil]
      # @note This method is deprecated and will log a warning when used
      def GameSettings.autoload
        Lich.deprecated('GameSettings.autoload', 'not using, not applicable,', caller[0], fe_log: true)
        nil
      end
    end
  end
end