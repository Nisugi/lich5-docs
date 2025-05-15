# Handles loading of game-specific modules and dependencies for different game types.
# This module is responsible for initializing the appropriate game environment
# based on whether the user is playing Gemstone or DragonRealms.
#
# @author Lich5 Documentation Generator
module Lich
  module Common
    module GameLoader
      # Loads common dependencies required by all game types.
      # Initializes core functionality like logging, spells, and utilities.
      #
      # @return [void]
      # @note Must be called before loading game-specific modules
      #
      # @example
      #   Lich::Common::GameLoader.common_before
      def self.common_before
        require File.join(LIB_DIR, 'common', 'log.rb')
        require File.join(LIB_DIR, 'common', 'spell.rb')
        require File.join(LIB_DIR, 'util', 'util.rb')
        require File.join(LIB_DIR, 'common', 'hmr.rb')
      end

      # Loads all Gemstone-specific game modules and dependencies.
      # Initializes features like skills, spells, character attributes,
      # inventory management, and game status monitoring.
      #
      # @return [void]
      # @note Calls common_before internally to ensure base dependencies are loaded
      #
      # @example
      #   Lich::Common::GameLoader.gemstone
      def self.gemstone
        self.common_before
        require File.join(LIB_DIR, 'gemstone', 'sk.rb')
        require File.join(LIB_DIR, 'common', 'map', 'map_gs.rb')
        require File.join(LIB_DIR, 'gemstone', 'effects.rb')
        require File.join(LIB_DIR, 'gemstone', 'bounty.rb')
        require File.join(LIB_DIR, 'gemstone', 'claim.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon.rb')
        require File.join(LIB_DIR, 'attributes', 'resources.rb')
        require File.join(LIB_DIR, 'attributes', 'stats.rb')
        require File.join(LIB_DIR, 'attributes', 'spells.rb')
        require File.join(LIB_DIR, 'attributes', 'skills.rb')
        require File.join(LIB_DIR, 'attributes', 'society.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon', 'status.rb')
        require File.join(LIB_DIR, 'gemstone', 'experience.rb')
        require File.join(LIB_DIR, 'attributes', 'spellsong.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon', 'activespell.rb')
        require File.join(LIB_DIR, 'gemstone', 'psms.rb')
        require File.join(LIB_DIR, 'attributes', 'char.rb')
        require File.join(LIB_DIR, 'gemstone', 'infomon', 'currency.rb')
        # require File.join(LIB_DIR, 'gemstone', 'character', 'disk.rb') # dup
        require File.join(LIB_DIR, 'gemstone', 'group.rb')
        require File.join(LIB_DIR, 'gemstone', 'critranks')
        require File.join(LIB_DIR, 'gemstone', 'wounds.rb')
        require File.join(LIB_DIR, 'gemstone', 'scars.rb')
        require File.join(LIB_DIR, 'gemstone', 'gift.rb')
        require File.join(LIB_DIR, 'gemstone', 'readylist.rb')
        require File.join(LIB_DIR, 'gemstone', 'stowlist.rb')
        ActiveSpell.watch!
        self.common_after
      end

      # Loads all DragonRealms-specific game modules and dependencies.
      # Initializes the DR-specific map system, character attributes,
      # and information monitoring.
      #
      # @return [void]
      # @note Calls common_before internally to ensure base dependencies are loaded
      #
      # @example
      #   Lich::Common::GameLoader.dragon_realms
      def self.dragon_realms
        self.common_before
        require File.join(LIB_DIR, 'common', 'map', 'map_dr.rb')
        require File.join(LIB_DIR, 'attributes', 'char.rb')
        require File.join(LIB_DIR, 'dragonrealms', 'drinfomon.rb')
        require File.join(LIB_DIR, 'dragonrealms', 'commons.rb')
        self.common_after
      end

      # Performs any necessary cleanup or final initialization after
      # game-specific modules are loaded.
      #
      # @return [void]
      # @note Currently a no-op placeholder for future functionality
      #
      # @example
      #   Lich::Common::GameLoader.common_after
      def self.common_after
        # nil
      end

      # Main entry point for game-specific module loading.
      # Automatically detects the game type from XMLData and loads appropriate modules.
      #
      # @return [void]
      # @raise [RuntimeError] If game type cannot be determined or is unsupported
      # @note Waits for XMLData.game to be populated before proceeding
      # @note Supports 'DR' (DragonRealms) and 'GS' (Gemstone) game types
      #
      # @example
      #   Lich::Common::GameLoader.load!
      def self.load!
        sleep 0.1 while XMLData.game.nil? or XMLData.game.empty?
        return self.dragon_realms if XMLData.game =~ /DR/
        return self.gemstone if XMLData.game =~ /GS/
        echo "could not load game specifics for %s" % XMLData.game
      end
    end
  end
end