# break out module UserVars
# 2024-06-13

module Lich
  module Common
    module UserVars
      # Lists all user variables.
      #
      # @return [Array] an array of user variables.
      #
      # @example
      #   UserVars.list
      #   # => ["var1", "var2", "var3"]
      def UserVars.list
        Vars.list
      end

      # Handles missing methods for user variables.
      #
      # @param arg1 [Symbol] the name of the method being called.
      # @param arg2 [String] an optional argument for the method.
      # @return [Object] the result of the Vars method call.
      #
      # @raise [NoMethodError] if the method does not exist in Vars.
      #
      # @example
      #   UserVars.some_missing_method
      #   # => raises NoMethodError
      def UserVars.method_missing(arg1, arg2 = '')
        Vars.method_missing(arg1, arg2)
      end

      # Changes the value of a user variable.
      #
      # @param var_name [String] the name of the variable to change.
      # @param value [Object] the new value to assign to the variable.
      # @param _t [nil] an optional parameter (not used).
      # @return [Object] the new value of the variable.
      #
      # @note This will overwrite the existing value of the variable.
      #
      # @example
      #   UserVars.change("var1", "new_value")
      #   # => "new_value"
      def UserVars.change(var_name, value, _t = nil)
        Vars[var_name] = value
      end

      # Adds a value to a user variable, appending it to the existing value.
      #
      # @param var_name [String] the name of the variable to add to.
      # @param value [Object] the value to append to the variable.
      # @param _t [nil] an optional parameter (not used).
      # @return [String] the updated value of the variable.
      #
      # @note This assumes the existing value is a comma-separated string.
      #
      # @example
      #   UserVars.add("var1", "new_value")
      #   # => "existing_value, new_value"
      def UserVars.add(var_name, value, _t = nil)
        Vars[var_name] = Vars[var_name].split(', ').push(value).join(', ')
      end

      # Deletes a user variable by setting it to nil.
      #
      # @param var_name [String] the name of the variable to delete.
      # @param _t [nil] an optional parameter (not used).
      # @return [nil] always returns nil.
      #
      # @example
      #   UserVars.delete("var1")
      #   # => nil
      def UserVars.delete(var_name, _t = nil)
        Vars[var_name] = nil
      end

      # Lists all global user variables.
      #
      # @return [Array] an empty array, as global variables are not implemented.
      #
      # @example
      #   UserVars.list_global
      #   # => []
      def UserVars.list_global
        Array.new
      end

      # Lists character-specific user variables.
      #
      # @return [Array] an array of character-specific user variables.
      #
      # @example
      #   UserVars.list_char
      #   # => ["char_var1", "char_var2"]
      def UserVars.list_char
        Vars.list
      end
    end
  end
end
