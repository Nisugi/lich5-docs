# API for char Status
# todo: should include jaws / condemn / others?

require "ostruct"

module Lich
  module Gemstone
    module Status
      # Checks if the character is thorned.
      #
      # @return [Boolean] true if the character is thorned, false otherwise.
      # @example
      #   Lich::Gemstone::Status.thorned? # => true or false
      def self.thorned? # added 2024-09-08
        (Infomon.get_bool("status.thorned") && Effects::Debuffs.active?(/Wall of Thorns Poison [1-5]/))
      end

      # Checks if the character is bound.
      #
      # @return [Boolean] true if the character is bound, false otherwise.
      # @example
      #   Lich::Gemstone::Status.bound? # => true or false
      def self.bound?
        Infomon.get_bool("status.bound") && (Effects::Debuffs.active?('Bind') || Effects::Debuffs.active?(214))
      end

      # Checks if the character is calmed.
      #
      # @return [Boolean] true if the character is calmed, false otherwise.
      # @example
      #   Lich::Gemstone::Status.calmed? # => true or false
      def self.calmed?
        Infomon.get_bool("status.calmed") && (Effects::Debuffs.active?('Calm') || Effects::Debuffs.active?(201))
      end

      # Checks if the character is cutthroat.
      #
      # @return [Boolean] true if the character is cutthroat, false otherwise.
      # @example
      #   Lich::Gemstone::Status.cutthroat? # => true or false
      def self.cutthroat?
        Infomon.get_bool("status.cutthroat") && Effects::Debuffs.active?('Major Bleed')
      end

      # Checks if the character is silenced.
      #
      # @return [Boolean] true if the character is silenced, false otherwise.
      # @example
      #   Lich::Gemstone::Status.silenced? # => true or false
      def self.silenced?
        Infomon.get_bool("status.silenced") && Effects::Debuffs.active?('Silenced')
      end

      # Checks if the character is sleeping.
      #
      # @return [Boolean] true if the character is sleeping, false otherwise.
      # @example
      #   Lich::Gemstone::Status.sleeping? # => true or false
      def self.sleeping?
        Infomon.get_bool("status.sleeping") && (Effects::Debuffs.active?('Sleep') || Effects::Debuffs.active?(501))
      end

      # Checks if the character is webbed.
      #
      # @return [Boolean] true if the character is webbed, false otherwise.
      # @note This method is planned for deprecation in global_defs.
      # @example
      #   Lich::Gemstone::Status.webbed? # => true or false
      def self.webbed?
        XMLData.indicator['IconWEBBED'] == 'y'
      end

      # Checks if the character is dead.
      #
      # @return [Boolean] true if the character is dead, false otherwise.
      # @example
      #   Lich::Gemstone::Status.dead? # => true or false
      def self.dead?
        XMLData.indicator['IconDEAD'] == 'y'
      end

      # Checks if the character is stunned.
      #
      # @return [Boolean] true if the character is stunned, false otherwise.
      # @example
      #   Lich::Gemstone::Status.stunned? # => true or false
      def self.stunned?
        XMLData.indicator['IconSTUNNED'] == 'y'
      end

      # Checks if the character is muckled (webbed, dead, stunned, bound, or sleeping).
      #
      # @return [Boolean] true if the character is muckled, false otherwise.
      # @example
      #   Lich::Gemstone::Status.muckled? # => true or false
      def self.muckled?
        return Status.webbed? || Status.dead? || Status.stunned? || Status.bound? || Status.sleeping?
      end

      # Serializes the status of the character.
      #
      # @return [Array<Boolean>] an array of booleans representing the character's status.
      # @example
      #   Lich::Gemstone::Status.serialize # => [true, false, true, false, true]
      def self.serialize
        [self.bound?, self.calmed?, self.cutthroat?, self.silenced?, self.sleeping?]
      end
    end
  end
end