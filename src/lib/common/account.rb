# Account management module for Lich that handles user account details, subscription status,
# game information and character data.
#
# @author Lich5 Documentation Generator
module Lich
  module Common
    module Account
      @@name ||= nil
      @@subscription ||= nil
      @@game_code ||= nil
      @@members ||= {}
      @@character ||= nil

      # Gets the account holder's name
      #
      # @return [String, nil] The account holder's name or nil if not set
      # @example
      #   Lich::Common::Account.name #=> "PlayerName"
      def self.name
        @@name
      end

      # Sets the account holder's name
      #
      # @param value [String] The name to set for the account
      # @return [String] The newly set name
      # @example
      #   Lich::Common::Account.name = "PlayerName"
      def self.name=(value)
        @@name = value
      end

      # Gets the current character name
      #
      # @return [String, nil] The current character name or nil if not set
      # @example
      #   Lich::Common::Account.character #=> "CharacterName"
      def self.character
        @@character
      end

      # Sets the current character name
      #
      # @param value [String] The character name to set
      # @return [String] The newly set character name
      # @example
      #   Lich::Common::Account.character = "CharacterName"
      def self.character=(value)
        @@character = value
      end

      # Gets the account subscription type
      #
      # @return [String, nil] One of: "NORMAL", "PREMIUM", "TRIAL", "INTERNAL", "FREE" or nil if not set
      # @example
      #   Lich::Common::Account.subscription #=> "PREMIUM"
      def self.subscription
        @@subscription
      end

      # Sets the account subscription type
      #
      # @param value [String] The subscription type to set
      # @return [String, nil] The validated subscription type or nil if invalid
      # @note Only accepts: "NORMAL", "PREMIUM", "TRIAL", "INTERNAL", "FREE"
      # @example
      #   Lich::Common::Account.subscription = "PREMIUM"
      def self.subscription=(value)
        if value =~ /(NORMAL|PREMIUM|TRIAL|INTERNAL|FREE)/
          @@subscription = Regexp.last_match(1)
        end
      end

      # Gets the game code identifier
      #
      # @return [String, nil] The game code or nil if not set
      # @example
      #   Lich::Common::Account.game_code #=> "DR"
      def self.game_code
        @@game_code
      end

      # Sets the game code identifier
      #
      # @param value [String] The game code to set
      # @return [String] The newly set game code
      # @example
      #   Lich::Common::Account.game_code = "DR"
      def self.game_code=(value)
        @@game_code = value
      end

      # Gets the hash of character codes mapped to character names
      #
      # @return [Hash{String => String}] Hash with character codes as keys and names as values
      # @example
      #   Lich::Common::Account.members #=> {"ABC123" => "CharacterOne", "XYZ789" => "CharacterTwo"}
      def self.members
        @@members
      end

      # Parses and sets character membership data
      #
      # @param value [String] Tab-delimited character data string to parse
      # @return [Hash{String => String}] Processed hash of character codes to names
      # @example
      #   Lich::Common::Account.members = "C\t1\t2\t3\t4\tABC123\tCharacterOne\tXYZ789\tCharacterTwo"
      def self.members=(value)
        potential_members = {}
        for code_name in value.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/)
          char_code, char_name = code_name.split("\t")
          potential_members[char_code] = char_name
        end
        @@members = potential_members
      end

      # Gets an array of all character names
      #
      # @return [Array<String>] Array containing all character names
      # @example
      #   Lich::Common::Account.characters #=> ["CharacterOne", "CharacterTwo"]
      def self.characters
        @@members.values
      end
    end
  end
end