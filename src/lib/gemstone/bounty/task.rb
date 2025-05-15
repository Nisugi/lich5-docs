# Module for the Lich game automation system
module Lich
  # Module containing Gemstone-specific functionality 
  module Gemstone
    # Class representing bounty-related functionality
    class Bounty
      # Represents a bounty task with its type, requirements and description
      #
      # @author Lich5 Documentation Generator
      class Task
        # Initializes a new Task instance
        #
        # @param options [Hash] Options for creating the task
        # @option options [String] :description Task description text
        # @option options [Symbol] :type The type of task
        # @option options [Hash] :requirements Task-specific requirements
        # @option options [String] :town Town where task takes place
        #
        # @example
        #   task = Task.new(
        #     description: "Kill 3 goblins",
        #     type: :creature_assignment,
        #     requirements: {creature: "goblin", count: 3}
        #   )
        def initialize(options = {})
          @description    = options[:description]
          @type           = options[:type]
          @requirements   = options[:requirements] || {}
          @town           = options[:town] || @requirements[:town]
        end

        # @return [String] The task description
        # @return [Symbol] The task type
        # @return [Hash] The task requirements
        # @return [String] The town where task takes place
        attr_accessor :type, :requirements, :description, :town

        # Gets the task type (alias for type)
        # @return [Symbol] The task type
        def task; type; end

        # Gets the task type (alias for type)
        # @return [Symbol] The task type
        def kind; type; end

        # Gets the count requirement
        # @return [Integer] The required count for the task
        def count; number; end

        # Gets the creature requirement
        # @return [String, nil] The creature name if specified
        def creature
          requirements[:creature]
        end

        # Gets the creature requirement (alias for creature)
        # @return [String, nil] The creature name if specified
        def critter
          requirements[:creature]
        end

        # Checks if task has a creature requirement
        # @return [Boolean] true if task involves a creature
        def critter?
          !!requirements[:creature]
        end

        # Gets the task location
        # @return [String] The area or town where task takes place
        def location
          requirements[:area] || town
        end

        # Checks if task is bandit-related
        # @return [Boolean] true if task type starts with "bandit"
        def bandit?
          type.to_s.start_with?("bandit")
        end

        # Checks if task is creature-related
        # @return [Boolean] true if task involves creatures
        def creature?
          [
            :creature_assignment, :cull, :dangerous, :dangerous_spawned, :rescue, :heirloom
          ].include?(type)
        end

        # Checks if task is a culling task
        # @return [Boolean] true if task type starts with "cull"
        def cull?
          type.to_s.start_with?("cull")
        end

        # Checks if task is dangerous
        # @return [Boolean] true if task type starts with "dangerous"
        def dangerous?
          type.to_s.start_with?("dangerous")
        end

        # Checks if task is an escort mission
        # @return [Boolean] true if task type starts with "escort"
        def escort?
          type.to_s.start_with?("escort")
        end

        # Checks if task involves gems
        # @return [Boolean] true if task type starts with "gem"
        def gem?
          type.to_s.start_with?("gem")
        end

        # Checks if task involves heirlooms
        # @return [Boolean] true if task type starts with "heirloom"
        def heirloom?
          type.to_s.start_with?("heirloom")
        end

        # Checks if task involves herbs
        # @return [Boolean] true if task type starts with "herb"
        def herb?
          type.to_s.start_with?("herb")
        end

        # Checks if task is a rescue mission
        # @return [Boolean] true if task type starts with "rescue"
        def rescue?
          type.to_s.start_with?("rescue")
        end

        # Checks if task involves skinning
        # @return [Boolean] true if task type starts with "skin"
        def skin?
          type.to_s.start_with?("skin")
        end

        # Checks if task involves searching for heirloom
        # @return [Boolean] true if heirloom task with search action
        def search_heirloom?
          [:heirloom].include?(type) &&
            requirements[:action] == "search"
        end

        # Checks if task involves looting heirloom
        # @return [Boolean] true if heirloom task with loot action
        def loot_heirloom?
          [:heirloom].include?(type) &&
            requirements[:action] == "loot"
        end

        # Checks if heirloom has been found
        # @return [Boolean] true if heirloom was found
        def heirloom_found?
          [
            :heirloom_found
          ].include?(type)
        end

        # Checks if task is complete
        # @return [Boolean] true if task is in a completed state
        def done?
          [
            :failed, :guard, :taskmaster, :heirloom_found
          ].include?(type)
        end

        # Checks if creatures have spawned
        # @return [Boolean] true if task involves spawned creatures
        def spawned?
          [
            :dangerous_spawned, :escort, :rescue_spawned
          ].include?(type)
        end

        # Alias for spawned?
        # @return [Boolean] true if task involves spawned creatures
        def triggered?; spawned?; end

        # Checks if task exists
        # @return [Boolean] true if task is not none/nil
        def any?
          !none?
        end

        # Checks if no task exists
        # @return [Boolean] true if task is none/nil
        def none?
          [:none, nil].include?(type)
        end

        # Checks if task involves guard
        # @return [Boolean] true if task involves guard interaction
        def guard?
          [
            :guard,
            :bandit_assignment, :creature_assignment, :heirloom_assignment, :heirloom_found, :rescue_assignment
          ].include?(type)
        end

        # Checks if task is in assigned state
        # @return [Boolean] true if task type ends with "assignment"
        def assigned?
          type.to_s.end_with?("assignment")
        end

        # Checks if task is ready for action
        # @return [Boolean] true if task is in actionable state
        def ready?
          [
            :bandit_assignment, :escort_assignment,
            :bandit, :cull, :dangerous, :escort, :gem, :heirloom, :herb, :rescue, :skin
          ].include?(type)
        end

        # Checks if task involves helping others
        # @return [Boolean] true if description indicates helping others
        def help?
          description.start_with?("You have been tasked to help")
        end

        # Alias for help?
        # @return [Boolean] true if task involves helping others
        def assist?
          help?
        end

        # Alias for help?
        # @return [Boolean] true if task involves helping others
        def group?
          help?
        end

        # Provides dynamic access to requirement values
        #
        # @param symbol [Symbol] The requirement key to access
        # @param args [Array] Additional arguments (unused)
        # @param blk [Proc] Block parameter (unused)
        # @return [Object] The value for the requirement key
        # @raise [NoMethodError] If requirement key doesn't exist
        def method_missing(symbol, *args, &blk)
          if requirements&.keys&.include?(symbol)
            requirements[symbol]
          else
            super
          end
        end

        # Checks if object responds to missing method
        #
        # @param symbol [Symbol] Method name to check
        # @param include_private [Boolean] Whether to include private methods
        # @return [Boolean] true if method can be handled via requirements
        def respond_to_missing?(symbol, include_private = false)
          requirements&.keys&.include?(symbol) || super
        end
      end
    end
  end
end