# New module SessionVars for variables needed by more than one script but do not need to be saved to the sqlite db
#   (should this be in settings path?)
# 2024-09-05

# A module to manage session variables that are not persisted in a database.
module SessionVars
  @@svars = Hash.new

  # Retrieves the value of a session variable by name.
  #
  # @param name [String] the name of the session variable to retrieve.
  # @return [Object, nil] the value of the session variable, or nil if it does not exist.
  # @example
  #   SessionVars[:user_id] # => 123
  def SessionVars.[](name)
    @@svars[name]
  end

  # Sets the value of a session variable by name.
  #
  # @param name [String] the name of the session variable to set.
  # @param val [Object, nil] the value to assign to the session variable; if nil, the variable is deleted.
  # @return [void]
  # @example
  #   SessionVars[:user_id] = 123
  def SessionVars.[]=(name, val)
    if val.nil?
      @@svars.delete(name)
    else
      @@svars[name] = val
    end
  end

  # Returns a duplicate of the current session variables.
  #
  # @return [Hash] a duplicate of the session variables hash.
  # @example
  #   SessionVars.list # => { user_id: 123 }
  def SessionVars.list
    @@svars.dup
  end

  # Handles dynamic method calls for setting and getting session variables.
  #
  # @param arg1 [Symbol, String] the name of the session variable or a setter method (ending with '=').
  # @param arg2 [Object, nil] the value to assign if setting a variable; ignored if getting a variable.
  # @return [Object, nil] the value of the session variable if getting, or nil if deleted.
  # @note This method allows for dynamic access to session variables using method names.
  # @example
  #   SessionVars.user_id = 123
  #   SessionVars.user_id # => 123
  def SessionVars.method_missing(arg1, arg2 = '')
    if arg1[-1, 1] == '='
      if arg2.nil?
        @@svars.delete(arg1.to_s.chop)
      else
        @@svars[arg1.to_s.chop] = arg2
      end
    else
      @@svars[arg1.to_s]
    end
  end
end