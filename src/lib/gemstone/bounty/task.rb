module Lich
  module Gemstone
    # Represents a bounty task with various attributes and methods to determine its type and status.
    class Bounty
      class Task
        # Initializes a new Task with the given options.
        #
        # @param options [Hash] the options for the task
        # @option options [String] :description the description of the task
        # @option options [Symbol] :type the type of the task
        # @option options [Hash] :requirements the requirements for the task
        # @option options [String] :town the town associated with the task
        def initialize(options = {})
          @description    = options[:description]
          @type           = options[:type]
          @requirements   = options[:requirements] || {}
          @town           = options[:town] || @requirements[:town]
        end
        
        attr_accessor :type, :requirements, :description, :town

        # Returns the type of the task.
        #
        # @return [Symbol] the type of the task
        def task; type; end

        # Returns the type of the task (alias for task).
        #
        # @return [Symbol] the type of the task
        def kind; type; end

        # Returns the number of tasks (not implemented).
        #
        # @return [nil] always returns nil
        def count; number; end

        # Returns the creature requirement for the task.
        #
        # @return [Symbol, nil] the creature required for the task or nil if not specified
        def creature
          requirements[:creature]
        end

        # Returns the creature requirement for the task (alias for creature).
        #
        # @return [Symbol, nil] the creature required for the task or nil if not specified
        def critter
          requirements[:creature]
        end

        # Checks if a creature is required for the task.
        #
        # @return [Boolean] true if a creature is required, false otherwise
        def critter?
          !!requirements[:creature]
        end

        # Returns the area requirement or the town associated with the task.
        #
        # @return [String] the area or town for the task
        def location
          requirements[:area] || town
        end

        # Checks if the task type starts with "bandit".
        #
        # @return [Boolean] true if the task is a bandit task, false otherwise
        def bandit?
          type.to_s.start_with?("bandit")
        end

        # Checks if the task type is one of the creature-related types.
        #
        # @return [Boolean] true if the task is creature-related, false otherwise
        def creature?
          [
            :creature_assignment, :cull, :dangerous, :dangerous_spawned, :rescue, :heirloom
          ].include?(type)
        end

        # Checks if the task type starts with "cull".
        #
        # @return [Boolean] true if the task is a cull task, false otherwise
        def cull?
          type.to_s.start_with?("cull")
        end

        # Checks if the task type starts with "dangerous".
        #
        # @return [Boolean] true if the task is dangerous, false otherwise
        def dangerous?
          type.to_s.start_with?("dangerous")
        end

        # Checks if the task type starts with "escort".
        #
        # @return [Boolean] true if the task is an escort task, false otherwise
        def escort?
          type.to_s.start_with?("escort")
        end

        # Checks if the task type starts with "gem".
        #
        # @return [Boolean] true if the task is a gem task, false otherwise
        def gem?
          type.to_s.start_with?("gem")
        end

        # Checks if the task type starts with "heirloom".
        #
        # @return [Boolean] true if the task is an heirloom task, false otherwise
        def heirloom?
          type.to_s.start_with?("heirloom")
        end

        # Checks if the task type starts with "herb".
        #
        # @return [Boolean] true if the task is a herb task, false otherwise
        def herb?
          type.to_s.start_with?("herb")
        end

        # Checks if the task type starts with "rescue".
        #
        # @return [Boolean] true if the task is a rescue task, false otherwise
        def rescue?
          type.to_s.start_with?("rescue")
        end

        # Checks if the task type starts with "skin".
        #
        # @return [Boolean] true if the task is a skin task, false otherwise
        def skin?
          type.to_s.start_with?("skin")
        end

        # Checks if the task is a search action for an heirloom.
        #
        # @return [Boolean] true if the task is a search for an heirloom, false otherwise
        def search_heirloom?
          [:heirloom].include?(type) &&
            requirements[:action] == "search"
        end

        # Checks if the task is a loot action for an heirloom.
        #
        # @return [Boolean] true if the task is a loot for an heirloom, false otherwise
        def loot_heirloom?
          [:heirloom].include?(type) &&
            requirements[:action] == "loot"
        end

        # Checks if the task type is "heirloom_found".
        #
        # @return [Boolean] true if the task is an heirloom found task, false otherwise
        def heirloom_found?
          [
            :heirloom_found
          ].include?(type)
        end

        # Checks if the task is done based on its type.
        #
        # @return [Boolean] true if the task is done, false otherwise
        def done?
          [
            :failed, :guard, :taskmaster, :heirloom_found
          ].include?(type)
        end

        # Checks if the task type is one of the spawned types.
        #
        # @return [Boolean] true if the task is spawned, false otherwise
        def spawned?
          [
            :dangerous_spawned, :escort, :rescue_spawned
          ].include?(type)
        end

        # Checks if the task has been triggered (alias for spawned?).
        #
        # @return [Boolean] true if the task is triggered, false otherwise
        def triggered?; spawned?; end

        # Checks if there are any tasks.
        #
        # @return [Boolean] true if there are tasks, false otherwise
        def any?
          !none?
        end

        # Checks if there are no tasks.
        #
        # @return [Boolean] true if there are no tasks, false otherwise
        def none?
          [:none, nil].include?(type)
        end

        # Checks if the task type is one of the guard-related types.
        #
        # @return [Boolean] true if the task is a guard task, false otherwise
        def guard?
          [
            :guard,
            :bandit_assignment, :creature_assignment, :heirloom_assignment, :heirloom_found, :rescue_assignment
          ].include?(type)
        end

        # Checks if the task type ends with "assignment".
        #
        # @return [Boolean] true if the task is assigned, false otherwise
        def assigned?
          type.to_s.end_with?("assignment")
        end

        # Checks if the task is ready based on its type.
        #
        # @return [Boolean] true if the task is ready, false otherwise
        def ready?
          [
            :bandit_assignment, :escort_assignment,
            :bandit, :cull, :dangerous, :escort, :gem, :heirloom, :herb, :rescue, :skin
          ].include?(type)
        end

        # Checks if the description indicates a help task.
        #
        # @return [Boolean] true if the task is a help task, false otherwise
        def help?
          description.start_with?("You have been tasked to help")
        end

        # Checks if the task is an assist task (alias for help?).
        #
        # @return [Boolean] true if the task is an assist task, false otherwise
        def assist?
          help?
        end

        # Checks if the task is a group task (alias for help?).
        #
        # @return [Boolean] true if the task is a group task, false otherwise
        def group?
          help?
        end

        # Handles missing methods by returning the corresponding requirement if it exists.
        #
        # @param symbol [Symbol] the method name that was called
        # @param args [Array] additional arguments (not used)
        # @param blk [Proc] block (not used)
        # @return [Object] the value of the requirement or raises NoMethodError if not found
        # @raise [NoMethodError] if the requirement does not exist
        def method_missing(symbol, *args, &blk)
          if requirements&.keys&.include?(symbol)
            requirements[symbol]
          else
            super
          end
        end

        # Checks if the method is missing and if it corresponds to a requirement.
        #
        # @param symbol [Symbol] the method name
        # @param include_private [Boolean] whether to include private methods
        # @return [Boolean] true if the method is a requirement, false otherwise
        def respond_to_missing?(symbol, include_private = false)
          requirements&.keys&.include?(symbol) || super
        end
      end
    end
  end
end