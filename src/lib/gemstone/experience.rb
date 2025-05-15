require "ostruct"

# Provides functionality for tracking and calculating various types of experience
# in the Gemstone game system, including field experience, ascension experience,
# and total experience points.
#
# @author Lich5 Documentation Generator
module Lich
  module Gemstone
    module Experience
      # Gets the character's fame value
      #
      # @return [Integer] The current fame value
      # @example
      #   Lich::Gemstone::Experience.fame #=> 100
      def self.fame
        Infomon.get("experience.fame")
      end

      # Gets the current field experience points
      #
      # @return [Integer] The current field experience points
      # @example
      #   Lich::Gemstone::Experience.fxp_current #=> 1000
      def self.fxp_current
        Infomon.get("experience.field_experience_current")
      end

      # Gets the maximum field experience points possible
      #
      # @return [Integer] The maximum field experience points
      # @example
      #   Lich::Gemstone::Experience.fxp_max #=> 2500
      def self.fxp_max
        Infomon.get("experience.field_experience_max")
      end

      # Gets the current experience points
      #
      # @return [Integer] The current experience points
      # @example
      #   Lich::Gemstone::Experience.exp #=> 10000
      def self.exp
        Stats.exp
      end

      # Gets the ascension experience points
      #
      # @return [Integer] The current ascension experience points
      # @example
      #   Lich::Gemstone::Experience.axp #=> 5000
      def self.axp
        Infomon.get("experience.ascension_experience")
      end

      # Gets the total experience points
      #
      # @return [Integer] The total accumulated experience points
      # @example
      #   Lich::Gemstone::Experience.txp #=> 15000
      def self.txp
        Infomon.get("experience.total_experience")
      end

      # Calculates the percentage of current field experience points relative to maximum
      #
      # @return [Float] Percentage of current FXP to maximum FXP (0-100)
      # @example
      #   Lich::Gemstone::Experience.percent_fxp #=> 40.0
      def self.percent_fxp
        (fxp_current.to_f / fxp_max.to_f) * 100
      end

      # Calculates the percentage of ascension experience points relative to total experience
      #
      # @return [Float] Percentage of AXP to total experience (0-100)
      # @example
      #   Lich::Gemstone::Experience.percent_axp #=> 33.33
      def self.percent_axp
        (axp.to_f / txp.to_f) * 100
      end

      # Calculates the percentage of experience points relative to total experience
      #
      # @return [Float] Percentage of EXP to total experience (0-100)
      # @example
      #   Lich::Gemstone::Experience.percent_exp #=> 66.67
      def self.percent_exp
        (exp.to_f / txp.to_f) * 100
      end

      # Gets the long term experience value
      #
      # @return [Integer] The current long term experience value
      # @example
      #   Lich::Gemstone::Experience.lte #=> 500
      def self.lte
        Infomon.get("experience.long_term_experience")
      end

      # Gets the number of deeds completed
      #
      # @return [Integer] The current number of deeds
      # @example
      #   Lich::Gemstone::Experience.deeds #=> 10
      def self.deeds
        Infomon.get("experience.deeds")
      end

      # Gets the death's sting value
      #
      # @return [Integer] The current death's sting value
      # @example
      #   Lich::Gemstone::Experience.deaths_sting #=> 0
      def self.deaths_sting
        Infomon.get("experience.deaths_sting")
      end
    end
  end
end