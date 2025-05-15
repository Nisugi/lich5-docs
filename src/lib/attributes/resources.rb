# A module for managing and checking various game resources in the Lich system
# 
# @author Lich5 Documentation Generator
module Lich
  module Resources
    # Gets the weekly resource value
    #
    # @return [Integer] The current weekly resource amount
    # @example
    #   Lich::Resources.weekly #=> 100
    def self.weekly
      Lich::Gemstone::Infomon.get('resources.weekly')
    end

    # Gets the total resource value
    #
    # @return [Integer] The total accumulated resources
    # @example
    #   Lich::Resources.total #=> 500
    def self.total
      Lich::Gemstone::Infomon.get('resources.total')
    end

    # Gets the suffused resource value
    #
    # @return [Integer] The current suffused resource amount
    # @example
    #   Lich::Resources.suffused #=> 50
    def self.suffused
      Lich::Gemstone::Infomon.get('resources.suffused')
    end

    # Gets the resource type
    #
    # @return [String] The type of resource
    # @example
    #   Lich::Resources.type #=> "mana"
    def self.type
      Lich::Gemstone::Infomon.get('resources.type')
    end

    # Gets the current Voln favor amount
    #
    # @return [Integer] The amount of Voln favor
    # @example
    #   Lich::Resources.voln_favor #=> 25
    def self.voln_favor
      Lich::Gemstone::Infomon.get('resources.voln_favor')
    end

    # Gets the number of covert arts charges
    #
    # @return [Integer] The number of covert arts charges available
    # @example
    #   Lich::Resources.covert_arts_charges #=> 3
    def self.covert_arts_charges
      Lich::Gemstone::Infomon.get('resources.covert_arts_charges')
    end

    # Checks and updates all resource values by issuing a resource command
    #
    # @param quiet [Boolean] Whether to suppress output messages (default: false)
    # @return [Array<Integer>] Array containing [weekly, total, suffused] resource values
    # @example
    #   Lich::Resources.check #=> [100, 500, 50]
    #   Lich::Resources.check(true) # Suppresses output
    #
    # @note This method issues a game command and parses the response to update resource values
    # @note The command response includes health, mana, stamina and spirit values
    def self.check(quiet = false)
      Lich::Util.issue_command('resource', /^Health: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Mana: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Stamina: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Spirit: \d+\/(?:<pushBold\/>)?\d+/, /<prompt/, silent: true, quiet: quiet)
      return [self.weekly, self.total, self.suffused]
    end
  end
end