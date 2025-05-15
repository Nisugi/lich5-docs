module Lich
  module Common
    # Path navigator to encapsulate path navigation logic
    class PathNavigator
      # Initializes a new PathNavigator instance.
      #
      # @param db_adapter [Object] The database adapter used for retrieving settings.
      def initialize(db_adapter)
        @db_adapter = db_adapter
        @path = []
      end

      # Returns the current path.
      #
      # @return [Array] The current path as an array.
      attr_reader :path

      # Resets the path to an empty array.
      #
      # @return [void]
      def reset_path
        @path = []
      end

      # Resets the path and returns the provided value.
      #
      # @param value [Object] The value to return after resetting the path.
      # @return [Object] The provided value.
      def reset_path_and_return(value)
        reset_path
        value
      end

      # Navigates to a specified path based on the script name and scope.
      #
      # @param script_name [String] The name of the script to navigate.
      # @param create_missing [Boolean] Whether to create missing path elements (default: true).
      # @param scope [String] The scope to use for retrieving settings (default: ":").
      # @return [Array] An array containing the target value and the root value.
      # @raise [KeyError] If the key does not exist and create_missing is false.
      # @example
      #   navigator = Lich::Common::PathNavigator.new(db_adapter)
      #   target, root = navigator.navigate_to_path("script_name")
      def navigate_to_path(script_name, create_missing = true, scope = ":")
        root = @db_adapter.get_settings(script_name, scope)
        return [root, root] if @path.empty?

        target = root
        @path.each do |key|
          if target.is_a?(Hash) && target.key?(key)
            target = target[key]
          elsif target.is_a?(Array) && key.is_a?(Integer) && key < target.length
            target = target[key]
          elsif create_missing
            # Path doesn't exist yet, create it
            target[key] = key.is_a?(Integer) ? [] : {}
            target = target[key]
          else
            # Path doesn't exist and we're not creating it
            return [nil, root]
          end
        end

        [target, root]
      end
    end
  end
end