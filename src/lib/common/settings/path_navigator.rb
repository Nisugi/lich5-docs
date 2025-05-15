# A module containing common functionality for the Lich system
module Lich
  # Contains common utility classes used across the Lich system
  module Common
    # Handles navigation and manipulation of nested data structures via paths
    #
    # PathNavigator provides functionality to traverse nested Hashes and Arrays
    # using an internal path array, with support for creating missing nodes.
    #
    # @author Lich5 Documentation Generator
    class PathNavigator
      # Creates a new PathNavigator instance
      #
      # @param db_adapter [Object] The database adapter used to retrieve settings
      # @return [PathNavigator] A new PathNavigator instance
      #
      # @example
      #   navigator = PathNavigator.new(database_adapter)
      def initialize(db_adapter)
        @db_adapter = db_adapter
        @path = []
      end

      # The current navigation path
      #
      # @return [Array] Array containing the current path elements
      # @note Read-only attribute
      attr_reader :path

      # Resets the current path to empty
      #
      # @return [Array] Empty array representing cleared path
      #
      # @example
      #   navigator.reset_path # => []
      def reset_path
        @path = []
      end

      # Resets the path and returns the provided value
      #
      # @param value [Object] Value to return after resetting path
      # @return [Object] The provided value parameter
      #
      # @example
      #   navigator.reset_path_and_return("some value") # => "some value"
      #   navigator.path # => []
      def reset_path_and_return(value)
        reset_path
        value
      end

      # Navigates to a path within nested settings data
      #
      # Traverses nested Hash/Array structures following the current path.
      # Can optionally create missing nodes along the way.
      #
      # @param script_name [String] Name of script whose settings to navigate
      # @param create_missing [Boolean] Whether to create missing path elements
      # @param scope [String] The settings scope, defaults to ":"
      # @return [Array<Object>] Two-element array containing:
      #   - The target value at the path location
      #   - The root settings object
      # @raise [TypeError] If target is not a Hash/Array when trying to navigate
      #
      # @example Navigate existing path
      #   navigator.path = ["users", 0, "name"] 
      #   target, root = navigator.navigate_to_path("myapp")
      #   # Returns value at myapp.settings.users[0].name
      #
      # @example Create missing path
      #   navigator.path = ["new", "path"]
      #   target, root = navigator.navigate_to_path("myapp", create_missing: true)
      #   # Creates empty Hash/Array nodes along path
      #
      # @note
      #   - Returns [nil, root] if path doesn't exist and create_missing is false
      #   - Creates Arrays for Integer keys and Hashes for other key types
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