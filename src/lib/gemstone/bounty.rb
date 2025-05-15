require_relative "./bounty/parser"
require_relative "./bounty/task"

module Lich
  module Gemstone
    # Represents a Bounty task within the Lich Gemstone module.
    class Bounty
      # A list of known task matchers.
      KNOWN_TASKS = Parser::TASK_MATCHERS.keys

      # Retrieves the current bounty task.
      #
      # @return [Task] the current bounty task instance.
      #
      # @example
      #   current_task = Lich::Gemstone::Bounty.current
      def self.current
        Task.new(Parser.parse(checkbounty))
      end

      # Retrieves the current bounty task.
      #
      # @return [Task] the current bounty task instance.
      #
      # @example
      #   task = Lich::Gemstone::Bounty.task
      def self.task
        current
      end

      # Retrieves bounty information for a specified person from LNet.
      #
      # @param person [String] the name of the person to retrieve bounty information for.
      # @return [Task, nil] a Task instance with the bounty information or nil if not found.
      #
      # @raise [StandardError] if there is an issue with the LNet data retrieval.
      #
      # @example
      #   bounty_task = Lich::Gemstone::Bounty.lnet("John Doe")
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