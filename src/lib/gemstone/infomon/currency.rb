# A module for accessing various currency values in the Gemstone game
# through the Infomon system.
#
# @author Lich5 Documentation Generator
module Lich
  module Currency
    # Gets the current amount of silver coins the character has
    #
    # @return [Integer] The number of silver coins
    # @example
    #   silver_amount = Lich::Currency.silver
    #   #=> 1234
    def self.silver
      Lich::Gemstone::Infomon.get('currency.silver')
    end

    # Gets the container where silver coins are stored
    #
    # @return [String] The name of the container holding silver
    # @example
    #   container = Lich::Currency.silver_container
    #   #=> "leather bag"
    def self.silver_container
      Lich::Gemstone::Infomon.get('currency.silver_container')
    end

    # Gets the current amount of redsteel marks
    #
    # @return [Integer] The number of redsteel marks
    # @example
    #   marks = Lich::Currency.redsteel_marks
    #   #=> 50
    def self.redsteel_marks
      Lich::Gemstone::Infomon.get('currency.redsteel_marks')
    end

    # Gets the current number of tickets
    #
    # @return [Integer] The number of tickets
    # @example
    #   tickets = Lich::Currency.tickets
    #   #=> 10
    def self.tickets
      Lich::Gemstone::Infomon.get('currency.tickets')
    end

    # Gets the current amount of blackscrip
    #
    # @return [Integer] The amount of blackscrip
    # @example
    #   scrip = Lich::Currency.blackscrip
    #   #=> 500
    def self.blackscrip
      Lich::Gemstone::Infomon.get('currency.blackscrip')
    end

    # Gets the current amount of bloodscrip
    #
    # @return [Integer] The amount of bloodscrip
    # @example
    #   scrip = Lich::Currency.bloodscrip
    #   #=> 250
    def self.bloodscrip
      Lich::Gemstone::Infomon.get('currency.bloodscrip')
    end

    # Gets the current amount of ethereal scrip
    #
    # @return [Integer] The amount of ethereal scrip
    # @example
    #   scrip = Lich::Currency.ethereal_scrip
    #   #=> 100
    def self.ethereal_scrip
      Lich::Gemstone::Infomon.get('currency.ethereal_scrip')
    end

    # Gets the current amount of raikhen
    #
    # @return [Integer] The amount of raikhen
    # @example
    #   raikhen = Lich::Currency.raikhen
    #   #=> 75
    def self.raikhen
      Lich::Gemstone::Infomon.get('currency.raikhen')
    end

    # Gets the current number of elans
    #
    # @return [Integer] The number of elans
    # @example
    #   elans = Lich::Currency.elans
    #   #=> 25
    def self.elans
      Lich::Gemstone::Infomon.get('currency.elans')
    end

    # Gets the current number of soul shards
    #
    # @return [Integer] The number of soul shards
    # @example
    #   shards = Lich::Currency.soul_shards
    #   #=> 15
    def self.soul_shards
      Lich::Gemstone::Infomon.get('currency.soul_shards')
    end

    # Gets the current number of gigas artifact fragments
    #
    # @return [Integer] The number of gigas artifact fragments
    # @example
    #   fragments = Lich::Currency.gigas_artifact_fragments
    #   #=> 5
    def self.gigas_artifact_fragments
      Lich::Gemstone::Infomon.get('currency.gigas_artifact_fragments')
    end

    # Gets the current amount of gemstone dust
    #
    # @return [Integer] The amount of gemstone dust
    # @example
    #   dust = Lich::Currency.gemstone_dust
    #   #=> 1000
    def self.gemstone_dust
      Lich::Gemstone::Infomon.get('currency.gemstone_dust')
    end
  end
end