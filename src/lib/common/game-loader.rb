# handles instances of modules that are game dependent

module Lich
  module Common
    module GameLoader
      # Loads common dependencies required before loading game-specific modules.
      #
      # @return [void] This method does not return a value.
      #
      # @example
      #   Lich::Common::GameLoader.common_before
      def self.common_before
        require File.join(LIB_DIR, 'common', 'log.rb')
        require File.join(LIB_DIR, 'common', 'spell.rb')
        require File.join(LIB_DIR, 'util', 'util.rb')
        require File.join(LIB_DIR, 'common', 'hmr.rb')
      end

      # Loads all necessary modules and dependencies for the Gemstone game.
      #
      # @return [void] This method does not return a value.
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

      # Loads all necessary modules and dependencies for the Dragon Realms game.
      #
      # @return [void] This method does not return a value.
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

      # Placeholder for any actions that need to be taken after loading common dependencies.
      #
      # @return [void] This method does not return a value.
      #
      # @note This method is currently a no-op.
      def self.common_after
        # nil
      end

      # Loads the appropriate game-specific modules based on the current game setting.
      #
      # @return [void] This method does not return a value.
      #
      # @raise [RuntimeError] If the game cannot be loaded due to an unknown game type.
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
