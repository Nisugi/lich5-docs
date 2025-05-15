module Lich
  module Resources
    # Retrieves the weekly resource information.
    #
    # @return [String] the weekly resource information.
    # @example
    #   Lich::Resources.weekly
    def self.weekly
      Lich::Gemstone::Infomon.get('resources.weekly')
    end

    # Retrieves the total resource information.
    #
    # @return [String] the total resource information.
    # @example
    #   Lich::Resources.total
    def self.total
      Lich::Gemstone::Infomon.get('resources.total')
    end

    # Retrieves the suffused resource information.
    #
    # @return [String] the suffused resource information.
    # @example
    #   Lich::Resources.suffused
    def self.suffused
      Lich::Gemstone::Infomon.get('resources.suffused')
    end

    # Retrieves the type of resources.
    #
    # @return [String] the type of resources.
    # @example
    #   Lich::Resources.type
    def self.type
      Lich::Gemstone::Infomon.get('resources.type')
    end

    # Retrieves the Voln favor resource information.
    #
    # @return [String] the Voln favor resource information.
    # @example
    #   Lich::Resources.voln_favor
    def self.voln_favor
      Lich::Gemstone::Infomon.get('resources.voln_favor')
    end

    # Retrieves the covert arts charges resource information.
    #
    # @return [String] the covert arts charges resource information.
    # @example
    #   Lich::Resources.covert_arts_charges
    def self.covert_arts_charges
      Lich::Gemstone::Infomon.get('resources.covert_arts_charges')
    end

    # Checks the current resources and returns an array of resource information.
    #
    # @param quiet [Boolean] whether to suppress output (default: false).
    # @return [Array<String>] an array containing weekly, total, and suffused resource information.
    # @raise [StandardError] if the command fails to execute properly.
    # @example
    #   Lich::Resources.check
    def self.check(quiet = false)
      Lich::Util.issue_command('resource', /^Health: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Mana: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Stamina: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Spirit: \d+\/(?:<pushBold\/>)?\d+/, /<prompt/, silent: true, quiet: quiet)
      return [self.weekly, self.total, self.suffused]
    end
  end
end
