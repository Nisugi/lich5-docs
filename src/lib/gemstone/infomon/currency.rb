module Lich
  module Currency
    # Retrieves the current amount of silver currency.
    #
    # @return [Integer] the amount of silver.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_silver = Lich::Currency.silver
    def self.silver
      Lich::Gemstone::Infomon.get('currency.silver')
    end

    # Retrieves the current amount of silver container currency.
    #
    # @return [Integer] the amount of silver container.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_silver_container = Lich::Currency.silver_container
    def self.silver_container
      Lich::Gemstone::Infomon.get('currency.silver_container')
    end

    # Retrieves the current amount of redsteel marks currency.
    #
    # @return [Integer] the amount of redsteel marks.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_redsteel_marks = Lich::Currency.redsteel_marks
    def self.redsteel_marks
      Lich::Gemstone::Infomon.get('currency.redsteel_marks')
    end

    # Retrieves the current amount of tickets currency.
    #
    # @return [Integer] the amount of tickets.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_tickets = Lich::Currency.tickets
    def self.tickets
      Lich::Gemstone::Infomon.get('currency.tickets')
    end

    # Retrieves the current amount of blackscrip currency.
    #
    # @return [Integer] the amount of blackscrip.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_blackscrip = Lich::Currency.blackscrip
    def self.blackscrip
      Lich::Gemstone::Infomon.get('currency.blackscrip')
    end

    # Retrieves the current amount of bloodscrip currency.
    #
    # @return [Integer] the amount of bloodscrip.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_bloodscrip = Lich::Currency.bloodscrip
    def self.bloodscrip
      Lich::Gemstone::Infomon.get('currency.bloodscrip')
    end

    # Retrieves the current amount of ethereal scrip currency.
    #
    # @return [Integer] the amount of ethereal scrip.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_ethereal_scrip = Lich::Currency.ethereal_scrip
    def self.ethereal_scrip
      Lich::Gemstone::Infomon.get('currency.ethereal_scrip')
    end

    # Retrieves the current amount of raikhen currency.
    #
    # @return [Integer] the amount of raikhen.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_raikhen = Lich::Currency.raikhen
    def self.raikhen
      Lich::Gemstone::Infomon.get('currency.raikhen')
    end

    # Retrieves the current amount of elans currency.
    #
    # @return [Integer] the amount of elans.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_elans = Lich::Currency.elans
    def self.elans
      Lich::Gemstone::Infomon.get('currency.elans')
    end

    # Retrieves the current amount of soul shards currency.
    #
    # @return [Integer] the amount of soul shards.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_soul_shards = Lich::Currency.soul_shards
    def self.soul_shards
      Lich::Gemstone::Infomon.get('currency.soul_shards')
    end

    # Retrieves the current amount of gigas artifact fragments currency.
    #
    # @return [Integer] the amount of gigas artifact fragments.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_gigas_artifact_fragments = Lich::Currency.gigas_artifact_fragments
    def self.gigas_artifact_fragments
      Lich::Gemstone::Infomon.get('currency.gigas_artifact_fragments')
    end

    # Retrieves the current amount of gemstone dust currency.
    #
    # @return [Integer] the amount of gemstone dust.
    # @raise [StandardError] if there is an issue retrieving the data.
    # @example
    #   amount_of_gemstone_dust = Lich::Currency.gemstone_dust
    def self.gemstone_dust
      Lich::Gemstone::Infomon.get('currency.gemstone_dust')
    end
  end
end