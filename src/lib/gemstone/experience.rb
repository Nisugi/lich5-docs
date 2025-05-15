require "ostruct"

module Lich
  module Gemstone
    module Experience
      # Retrieves the current fame value.
      #
      # @return [Integer] the current fame value.
      # @raise [StandardError] if there is an issue retrieving the fame value.
      # @example
      #   Lich::Gemstone::Experience.fame
      def self.fame
        Infomon.get("experience.fame")
      end

      # Retrieves the current field experience value.
      #
      # @return [Integer] the current field experience value.
      # @raise [StandardError] if there is an issue retrieving the current field experience.
      # @example
      #   Lich::Gemstone::Experience.fxp_current
      def self.fxp_current
        Infomon.get("experience.field_experience_current")
      end

      # Retrieves the maximum field experience value.
      #
      # @return [Integer] the maximum field experience value.
      # @raise [StandardError] if there is an issue retrieving the maximum field experience.
      # @example
      #   Lich::Gemstone::Experience.fxp_max
      def self.fxp_max
        Infomon.get("experience.field_experience_max")
      end

      # Retrieves the current experience value.
      #
      # @return [Integer] the current experience value.
      # @raise [StandardError] if there is an issue retrieving the experience value.
      # @example
      #   Lich::Gemstone::Experience.exp
      def self.exp
        Stats.exp
      end

      # Retrieves the current ascension experience value.
      #
      # @return [Integer] the current ascension experience value.
      # @raise [StandardError] if there is an issue retrieving the ascension experience.
      # @example
      #   Lich::Gemstone::Experience.axp
      def self.axp
        Infomon.get("experience.ascension_experience")
      end

      # Retrieves the total experience value.
      #
      # @return [Integer] the total experience value.
      # @raise [StandardError] if there is an issue retrieving the total experience.
      # @example
      #   Lich::Gemstone::Experience.txp
      def self.txp
        Infomon.get("experience.total_experience")
      end

      # Calculates the percentage of current field experience relative to the maximum field experience.
      #
      # @return [Float] the percentage of current field experience.
      # @raise [ZeroDivisionError] if the maximum field experience is zero.
      # @example
      #   Lich::Gemstone::Experience.percent_fxp
      def self.percent_fxp
        (fxp_current.to_f / fxp_max.to_f) * 100
      end

      # Calculates the percentage of ascension experience relative to total experience.
      #
      # @return [Float] the percentage of ascension experience.
      # @raise [ZeroDivisionError] if total experience is zero.
      # @example
      #   Lich::Gemstone::Experience.percent_axp
      def self.percent_axp
        (axp.to_f / txp.to_f) * 100
      end

      # Calculates the percentage of current experience relative to total experience.
      #
      # @return [Float] the percentage of current experience.
      # @raise [ZeroDivisionError] if total experience is zero.
      # @example
      #   Lich::Gemstone::Experience.percent_exp
      def self.percent_exp
        (exp.to_f / txp.to_f) * 100
      end

      # Retrieves the long-term experience value.
      #
      # @return [Integer] the long-term experience value.
      # @raise [StandardError] if there is an issue retrieving the long-term experience.
      # @example
      #   Lich::Gemstone::Experience.lte
      def self.lte
        Infomon.get("experience.long_term_experience")
      end

      # Retrieves the deeds value.
      #
      # @return [Integer] the deeds value.
      # @raise [StandardError] if there is an issue retrieving the deeds value.
      # @example
      #   Lich::Gemstone::Experience.deeds
      def self.deeds
        Infomon.get("experience.deeds")
      end

      # Retrieves the deaths sting value.
      #
      # @return [Integer] the deaths sting value.
      # @raise [StandardError] if there is an issue retrieving the deaths sting value.
      # @example
      #   Lich::Gemstone::Experience.deaths_sting
      def self.deaths_sting
        Infomon.get("experience.deaths_sting")
      end
    end
  end
end