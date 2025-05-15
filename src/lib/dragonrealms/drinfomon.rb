# DragonRealms information monitoring system that tracks character stats, skills, and game state
# This is the main entry point for the DrInfomon system that provides real-time parsing and tracking
# of character information in the DragonRealms game.
#
# @author Lich5 Documentation Generator
module Lich

  # DragonRealms-specific functionality namespace 
  module DragonRealms

    # Core information monitoring system for DragonRealms characters
    # Provides real-time parsing and tracking of character stats, skills, spells and other game state
    #
    # @note This module requires several other components to function properly
    module DRInfomon

      # Current version of the DrInfomon system
      # @return [String] Version number in semantic versioning format
      $DRINFOMON_VERSION = '3.0'

      # List of core Lich script dependencies required by DrInfomon
      # Contains the base script names needed for full functionality
      #
      # @return [Array<String>] Array of required script names
      DRINFOMON_CORE_LICH_DEFINES = %W(drinfomon common common-arcana common-crafting common-healing common-healing-data common-items common-money common-moonmage common-summoning common-theurgy common-travel common-validation events slackbot equipmanager spellmonitor)

      # Flag indicating if DrInfomon is running as part of core Lich
      # Used to determine loading behavior and dependency management
      #
      # @return [Boolean] true if running in core Lich, false otherwise 
      DRINFOMON_IN_CORE_LICH = true

      # @note The module automatically requires several component files:
      #   - drdefs: Core definitions and constants
      #   - drvariables: Variable tracking system
      #   - drparser: Game text parsing engine
      #   - drskill: Skill tracking system
      #   - drstats: Character stats monitoring
      #   - drroom: Room and navigation tracking
      #   - drspells: Spell system integration
      #   - events: Event handling system
      require_relative 'drinfomon/drdefs'
      require_relative 'drinfomon/drvariables'
      require_relative 'drinfomon/drparser'
      require_relative 'drinfomon/drskill'
      require_relative 'drinfomon/drstats'
      require_relative 'drinfomon/drroom'
      require_relative 'drinfomon/drspells'
      require_relative 'drinfomon/events'
    end
  end
end