# UserVars module provides functionality for managing user variables in the Lich system.
# It acts as a wrapper around the Vars system for storing and retrieving user-specific data.
#
# @author Lich5 Documentation Generator
module Lich
  module Common
    module UserVars
      # Lists all user variables currently set
      #
      # @return [Array<String>] Array of variable names that are currently set
      # @example
      #   UserVars.list #=> ["var1", "var2", "var3"]
      def UserVars.list
        Vars.list
      end

      # Gets or sets a user variable value
      #
      # @param arg1 [Symbol, String] Variable name to get/set
      # @param arg2 [Object] Optional value to set (defaults to empty string)
      # @return [Object] Value of the variable if getting, or the set value if setting
      # @example
      #   UserVars.myvar #=> Gets value of 'myvar'
      #   UserVars.myvar = "new value" #=> Sets 'myvar' to "new value"
      def UserVars.method_missing(arg1, arg2 = '')
        Vars.method_missing(arg1, arg2)
      end

      # Changes the value of an existing user variable
      #
      # @param var_name [String, Symbol] Name of variable to change
      # @param value [Object] New value to set
      # @param _t [nil] Unused parameter kept for compatibility
      # @return [Object] The new value that was set
      # @example
      #   UserVars.change(:myvar, "new value")
      def UserVars.change(var_name, value, _t = nil)
        Vars[var_name] = value
      end

      # Adds a value to an existing comma-separated list variable
      #
      # @param var_name [String, Symbol] Name of list variable
      # @param value [String] Value to append to list
      # @param _t [nil] Unused parameter kept for compatibility
      # @return [String] Updated comma-separated list
      # @example
      #   UserVars.add(:mylist, "new item")
      def UserVars.add(var_name, value, _t = nil)
        Vars[var_name] = Vars[var_name].split(', ').push(value).join(', ')
      end

      # Deletes a user variable
      #
      # @param var_name [String, Symbol] Name of variable to delete
      # @param _t [nil] Unused parameter kept for compatibility
      # @return [nil]
      # @example
      #   UserVars.delete(:myvar)
      def UserVars.delete(var_name, _t = nil)
        Vars[var_name] = nil
      end

      # Lists global variables (currently returns empty array)
      #
      # @return [Array] Empty array, as global vars not implemented
      # @note This is a placeholder method that currently returns an empty array
      # @example
      #   UserVars.list_global #=> []
      def UserVars.list_global
        Array.new
      end

      # Lists character-specific variables
      # Alias for UserVars.list
      #
      # @return [Array<String>] Array of variable names for current character
      # @example
      #   UserVars.list_char #=> ["var1", "var2"]
      def UserVars.list_char
        Vars.list
      end
    end
  end
end