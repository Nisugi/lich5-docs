require_relative "./bounty/parser"
require_relative "./bounty/task"

# A module for Lich game automation functionality
module Lich
  # Module containing Gemstone-specific functionality 
  module Gemstone
    # Handles bounty task information and interactions in Gemstone
    #
    # @author Lich5 Documentation Generator
    class Bounty
      # List of recognized bounty task types
      # @return [Array<Symbol>] List of valid task type symbols
      KNOWN_TASKS = Parser::TASK_MATCHERS.keys

      # Gets the current bounty task for the player
      #
      # @return [Task] A Task object representing the current bounty
      # @example
      #   current_bounty = Lich::Gemstone::Bounty.current
      def self.current
        Task.new(Parser.parse(checkbounty))
      end

      # Alias for .current method to get current bounty task
      #
      # @return [Task] A Task object representing the current bounty
      # @example
      #   task = Lich::Gemstone::Bounty.task
      def self.task
        current
      end

      # Retrieves bounty information for a player via LNet
      #
      # @param person [String] Character name to look up
      # @return [Task, nil] Task object if found, nil if not found or error
      # @example
      #   other_bounty = Lich::Gemstone::Bounty.lnet("PlayerName")
      #
      # @note Will send warning messages on failure via Lich::Messaging
      def self.lnet(person)
        if (target_info = LNet.get_data(person.dup, 'bounty'))
          Task.new(Parser.parse(target_info))
        else
          if target_info == false
            text = "No one on LNet with a name like #{person}"
          else
            text = "Empty response from LNet for bounty from #{person}\n"
          end
          Lich::Messaging.msg("warn", text)
          nil
        end
      end

      # Delegate class methods to a new instance of the current bounty task
      [:status, :type, :requirements, :town, :any?, :none?, :done?].each do |attr|
        self.class.instance_eval do
          define_method(attr) do |*args, &blk|
            current&.send(attr, *args, &blk)
          end
        end
      end
    end
  end
end