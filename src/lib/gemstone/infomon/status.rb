# API for char Status
# todo: should include jaws / condemn / others?

require "ostruct"

module Lich
  module Gemstone
    # Provides status checking functionality for a character in the Gemstone game
    # Handles various character states and debuffs
    #
    # @author Lich5 Documentation Generator
    module Status
      # Checks if the character is affected by Wall of Thorns poison
      #
      # @return [Boolean] true if character is thorned, false otherwise
      # @example
      #   Status.thorned? #=> true
      #
      # @note Added 2024-09-08
      def self.thorned?
        (Infomon.get_bool("status.thorned") && Effects::Debuffs.active?(/Wall of Thorns Poison [1-5]/))
      end

      # Checks if the character is magically bound/restrained
      #
      # @return [Boolean] true if character is bound, false otherwise
      # @example
      #   Status.bound? #=> false
      #
      # @note Checks both 'Bind' effect and effect ID 214
      def self.bound?
        Infomon.get_bool("status.bound") && (Effects::Debuffs.active?('Bind') || Effects::Debuffs.active?(214))
      end

      # Checks if the character is under calming effects
      #
      # @return [Boolean] true if character is calmed, false otherwise
      # @example
      #   Status.calmed? #=> true
      #
      # @note Checks both 'Calm' effect and effect ID 201
      def self.calmed?
        Infomon.get_bool("status.calmed") && (Effects::Debuffs.active?('Calm') || Effects::Debuffs.active?(201))
      end

      # Checks if the character is bleeding from a cutthroat attack
      #
      # @return [Boolean] true if character has major bleeding, false otherwise
      # @example
      #   Status.cutthroat? #=> false
      #
      # @note Specifically checks for 'Major Bleed' effect
      def self.cutthroat?
        Infomon.get_bool("status.cutthroat") && Effects::Debuffs.active?('Major Bleed')
      end

      # Checks if the character is magically silenced
      #
      # @return [Boolean] true if character is silenced, false otherwise
      # @example
      #   Status.silenced? #=> true
      def self.silenced?
        Infomon.get_bool("status.silenced") && Effects::Debuffs.active?('Silenced')
      end

      # Checks if the character is asleep
      #
      # @return [Boolean] true if character is sleeping, false otherwise
      # @example
      #   Status.sleeping? #=> false
      #
      # @note Checks both 'Sleep' effect and effect ID 501
      def self.sleeping?
        Infomon.get_bool("status.sleeping") && (Effects::Debuffs.active?('Sleep') || Effects::Debuffs.active?(501))
      end

      # Checks if the character is caught in a web
      #
      # @return [Boolean] true if character is webbed, false otherwise
      # @example
      #   Status.webbed? #=> true
      #
      # @deprecated Use new status system instead
      # @note Relies on XMLData indicator
      def self.webbed?
        XMLData.indicator['IconWEBBED'] == 'y'
      end

      # Checks if the character is dead
      #
      # @return [Boolean] true if character is dead, false otherwise
      # @example
      #   Status.dead? #=> false
      #
      # @deprecated Use new status system instead
      # @note Relies on XMLData indicator
      def self.dead?
        XMLData.indicator['IconDEAD'] == 'y'
      end

      # Checks if the character is stunned
      #
      # @return [Boolean] true if character is stunned, false otherwise
      # @example
      #   Status.stunned? #=> false
      #
      # @deprecated Use new status system instead
      # @note Relies on XMLData indicator
      def self.stunned?
        XMLData.indicator['IconSTUNNED'] == 'y'
      end

      # Checks if the character is incapacitated by any major debilitating effect
      #
      # @return [Boolean] true if character is webbed, dead, stunned, bound or sleeping
      # @example
      #   Status.muckled? #=> true
      #
      # @note Combines multiple status checks into one convenience method
      def self.muckled?
        return Status.webbed? || Status.dead? || Status.stunned? || Status.bound? || Status.sleeping?
      end

      # Serializes the character's status into an array of boolean values
      #
      # @return [Array<Boolean>] Array containing bound, calmed, cutthroat, silenced and sleeping states
      # @example
      #   Status.serialize #=> [false, true, false, false, false]
      #
      # @note May be deprecated in future versions
      def self.serialize
        [self.bound?, self.calmed?, self.cutthroat?, self.silenced?, self.sleeping?]
      end
    end
  end
end