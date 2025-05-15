module Lich
  module Common
    module Account
      @@name ||= nil
      @@subscription ||= nil
      @@game_code ||= nil
      @@members ||= {}
      @@character ||= nil

      # Returns the name of the account.
      #
      # @return [String, nil] the name of the account or nil if not set.
      def self.name
        @@name
      end

      # Sets the name of the account.
      #
      # @param value [String] the name to set for the account.
      # @return [String] the name that was set.
      # @example
      #   Lich::Common::Account.name = "Player1"
      def self.name=(value)
        @@name = value
      end

      # Returns the character associated with the account.
      #
      # @return [Object, nil] the character object or nil if not set.
      def self.character
        @@character
      end

      # Sets the character associated with the account.
      #
      # @param value [Object] the character to set for the account.
      # @return [Object] the character that was set.
      # @example
      #   Lich::Common::Account.character = my_character
      def self.character=(value)
        @@character = value
      end

      # Returns the subscription type of the account.
      #
      # @return [String, nil] the subscription type or nil if not set.
      def self.subscription
        @@subscription
      end

      # Sets the subscription type of the account.
      #
      # @param value [String] the subscription type to set.
      # @return [String] the subscription type that was set.
      # @raise [ArgumentError] if the value does not match the expected types.
      # @example
      #   Lich::Common::Account.subscription = "PREMIUM"
      def self.subscription=(value)
        if value =~ /(NORMAL|PREMIUM|TRIAL|INTERNAL|FREE)/
          @@subscription = Regexp.last_match(1)
        end
      end

      # Returns the game code associated with the account.
      #
      # @return [String, nil] the game code or nil if not set.
      def self.game_code
        @@game_code
      end

      # Sets the game code associated with the account.
      #
      # @param value [String] the game code to set.
      # @return [String] the game code that was set.
      # @example
      #   Lich::Common::Account.game_code = "GAME123"
      def self.game_code=(value)
        @@game_code = value
      end

      # Returns the members associated with the account.
      #
      # @return [Hash] a hash of member character codes and names.
      def self.members
        @@members
      end

      # Sets the members associated with the account.
      #
      # @param value [String] a string containing member character codes and names.
      # @return [Hash] the members that were set.
      # @note This method processes the input string to extract character codes and names.
      # @example
      #   Lich::Common::Account.members = "C\t1\t2\t3\t4\t\nA\tCharacter1\nB\tCharacter2"
      def self.members=(value)
        potential_members = {}
        for code_name in value.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/)
          char_code, char_name = code_name.split("\t")
          potential_members[char_code] = char_name
        end
        @@members = potential_members
      end

      # Returns the names of the characters associated with the account.
      #
      # @return [Array<String>] an array of character names.
      def self.characters
        @@members.values
      end
    end
  end
end
