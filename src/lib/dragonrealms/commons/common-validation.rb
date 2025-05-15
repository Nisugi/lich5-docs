# Module for the Lich game automation system
module Lich
  # Module containing DragonRealms specific functionality
  module DragonRealms
    # Handles character validation and messaging in DragonRealms
    #
    # @author Lich5 Documentation Generator
    class CharacterValidator
      # Initializes a new character validator instance
      #
      # @param announce [Boolean] Whether to announce the bot's presence in chat
      # @param sleep [Boolean] Whether to make the character sleep on initialization
      # @param greet [Boolean] Whether to send greeting messages to validated characters
      # @param name [String] The name of the bot/character
      #
      # @note Requires the 'lnet' script to be running
      # @example
      #   validator = CharacterValidator.new(true, false, true, "MyBot")
      def initialize(announce, sleep, greet, name)
        waitrt?
        fput('sleep') if sleep

        @lnet = (Script.running + Script.hidden).find { |val| val.name == 'lnet' }
        @validated_characters = []
        @greet = greet
        @name = name

        @lnet.unique_buffer.push("chat #{@name} is up and running in room #{Room.current.id}! Whisper me 'help' for more details.") if announce
      end

      # Sends a Slack token to a specified character via direct message
      #
      # @param character [String] The character name to send the token to
      # @return [void]
      # @example
      #   validator.send_slack_token("PlayerName")
      def send_slack_token(character)
        message = "slack_token: #{UserVars.slack_token || 'Not Found'}"
        echo "Attempting to DM #{character} with message: #{message}"
        @lnet.unique_buffer.push("chat to #{character} #{message}")
      end

      # Validates a character by checking their presence
      #
      # @param character [String] The character name to validate
      # @return [void]
      # @example
      #   validator.validate("PlayerName")
      def validate(character)
        return if valid?(character)

        echo "Attempting to validate: #{character}"
        @lnet.unique_buffer.push("who #{character}")
      end

      # Confirms a character's validation and sends optional greeting
      #
      # @param character [String] The character name to confirm
      # @return [void]
      # @example
      #   validator.confirm("PlayerName")
      def confirm(character)
        return if valid?(character)

        echo "Successfully validated: #{character}"
        @validated_characters << character

        return unless @greet

        put "whisper #{character} Hi! I'm your friendly neighborhood #{@name}. Whisper me 'help' for more details. Don't worry, I've memorized your name so you won't see this message again."
      end

      # Checks if a character has been previously validated
      #
      # @param character [String] The character name to check
      # @return [Boolean] true if character is validated, false otherwise
      # @example
      #   validator.valid?("PlayerName")
      def valid?(character)
        @validated_characters.include?(character)
      end

      # Sends current bank balance to a character
      #
      # @param character [String] The character to send the balance to
      # @param balance [Integer, String] The balance amount to send
      # @return [void]
      # @example
      #   validator.send_bankbot_balance("PlayerName", 1000)
      def send_bankbot_balance(character, balance)
        message = "Current Balance: #{balance}"
        echo "Attempting to DM #{character} with message: #{message}"
        @lnet.unique_buffer.push("chat to #{character} #{message}")
      end

      # Sends current location to a character
      #
      # @param character [String] The character to send the location to
      # @return [void]
      # @example
      #   validator.send_bankbot_location("PlayerName")
      def send_bankbot_location(character)
        message = "Current Location: #{Room.current.id}"
        echo "Attempting to DM #{character} with message: #{message}"
        @lnet.unique_buffer.push("chat to #{character} #{message}")
      end

      # Sends help messages to a character
      #
      # @param character [String] The character to send help messages to
      # @param messages [Array<String>] Array of help messages to send
      # @return [void]
      # @example
      #   validator.send_bankbot_help("PlayerName", ["Command 1: Do this", "Command 2: Do that"])
      def send_bankbot_help(character, messages)
        messages.each do |message|
          echo "Attempting to DM #{character} with message: #{message}"
          @lnet.unique_buffer.push("chat to #{character} #{message}")
        end
      end

      # Checks if a character is currently in the game
      #
      # @param character [String] The character name to check
      # @return [Boolean] true if character is in game, false otherwise
      # @example
      #   validator.in_game?("PlayerName")
      # @note Uses the DRC.bput method to check character presence
      def in_game?(character)
        DRC.bput("find #{character}", 'There are no adventurers in the realms that match the names specified', "^  #{character}.$") == "  #{character}."
      end
    end
  end
end