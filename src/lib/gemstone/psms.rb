require "ostruct"

require_relative('./psms/armor.rb')
require_relative('./psms/cman.rb')
require_relative('./psms/feat.rb')
require_relative('./psms/shield.rb')
require_relative('./psms/weapon.rb')
require_relative('./psms/warcry.rb')
require_relative('./psms/ascension.rb')

# Provides functionality for managing and checking Physical Skills Management System (PSMS)
# abilities in the Gemstone IV game, including armor, combat maneuvers, feats, shields,
# weapons, warcries, and ascension abilities.
#
# @author Lich5 Documentation Generator
module Lich
  module Gemstone
    module PSMS
      # Normalizes a skill name using the Lich utility function
      #
      # @param name [String] The raw skill name to normalize
      # @return [String] The normalized skill name
      # @example
      #   PSMS.name_normal("Shield bash") #=> "shield bash"
      #
      # @note Uses Lich::Util.normalize_name internally
      def self.name_normal(name)
        Lich::Util.normalize_name(name)
      end

      # Finds a PSMS ability by name within a specific category
      #
      # @param name [String] The normalized name of the ability to find
      # @param type [String] The category type (Armor, CMan, Feat, Shield, Weapon, Warcry, Ascension)
      # @return [Hash, nil] Hash containing ability details if found, nil if not found
      # @example
      #   PSMS.find_name("shield bash", "Shield") 
      #   #=> {long_name: "shield bash", short_name: "bash", cost: 10}
      def self.find_name(name, type)
        Object.const_get("Lich::Gemstone::#{type}").method("#{type.downcase}_lookups").call
              .find { |h| h[:long_name].eql?(name) || h[:short_name].eql?(name) }
      end

      # Assesses if a PSMS ability can be used or checks its training level
      #
      # @param name [String] The name of the ability to assess
      # @param type [String] The category type (Armor, CMan, Feat, Shield, Weapon, Warcry, Ascension)
      # @param costcheck [Boolean] If true, checks if player has enough stamina to use ability
      # @return [Boolean, Integer] Boolean for cost checks, Integer for training level checks
      # @raise [StandardError] When the specified ability name or type is invalid
      # @example
      #   # Check if can use ability
      #   PSMS.assess("shield bash", "Shield", true) #=> true
      #   
      #   # Check training level
      #   PSMS.assess("shield bash", "Shield") #=> 34
      #
      # @note Requires valid XMLData.stamina for cost checks
      def self.assess(name, type, costcheck = false)
        name = self.name_normal(name)
        seek_psm = self.find_name(name, type)
        # this logs then raises an exception to stop (kill) the offending script
        if seek_psm.nil?
          Lich.log("error: PSMS request: #{$!}\n\t")
          raise StandardError.new "Aborting script - The referenced #{type} skill #{name} is invalid.\r\nCheck your PSM category (Armor, CMan, Feat, Shield, Warcry, Weapon) and your spelling of #{name}."
        end
        # otherwise process request
        case costcheck
        when true
          seek_psm[:cost] < XMLData.stamina
        else
          Infomon.get("#{type.downcase}.#{seek_psm[:short_name]}")
        end
      end

      # Common failure messages that can occur when using any PSMS ability
      #
      # @return [Regexp] A union of regular expressions matching various failure messages
      # @note These are used to detect when PSMS abilities fail to activate
      FAILURES_REGEXES = Regexp.union(
        /^And give yourself away!  Never!$/,
        /^You are unable to do that right now\.$/,
        /^You don't seem to be able to move to do that\.$/,
        /^Provoking a GameMaster is not such a good idea\.$/,
        /^You do not currently have a target\.$/,
        /^Your mind clouds with confusion and you glance around uncertainly\.$/,
        /^But your hands are full\!$/,
        /^You are still stunned\.$/
      )
    end
  end
end