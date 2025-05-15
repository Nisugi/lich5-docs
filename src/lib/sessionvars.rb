# A module for managing session-level variables that need to be shared between scripts
# but don't require persistent storage. Provides a hash-like interface for storing
# and retrieving temporary variables during runtime.
#
# @author Lich5 Documentation Generator
module SessionVars
  @@svars = Hash.new

  # Retrieves the value of a session variable by name
  #
  # @param name [Symbol, String] The name of the session variable to retrieve
  # @return [Object, nil] The value stored for the given variable name, or nil if not found
  # @example
  #   SessionVars[:my_var] # => Returns value of :my_var
  #   SessionVars['status'] # => Returns value of 'status'
  def SessionVars.[](name)
    @@svars[name]
  end

  # Sets or deletes a session variable
  #
  # @param name [Symbol, String] The name of the session variable to set
  # @param val [Object, nil] The value to store. If nil, deletes the variable
  # @return [Object, nil] The value that was set, or nil if the variable was deleted
  # @example
  #   SessionVars[:my_var] = "some value"
  #   SessionVars[:temp] = nil # Deletes :temp variable
  def SessionVars.[]=(name, val)
    if val.nil?
      @@svars.delete(name)
    else
      @@svars[name] = val
    end
  end

  # Returns a copy of all session variables
  #
  # @return [Hash] A duplicate of the internal session variables hash
  # @example
  #   all_vars = SessionVars.list
  #   puts all_vars.inspect
  def SessionVars.list
    @@svars.dup
  end

  # Provides dynamic getter/setter methods for session variables
  #
  # @param arg1 [Symbol] The method name, interpreted as variable name
  # @param arg2 [Object] The value to set (for setter methods)
  # @return [Object, nil] For getters, returns the variable value. For setters, returns the value set
  # @example Getter usage
  #   SessionVars.my_var # => Returns value of :my_var
  # @example Setter usage  
  #   SessionVars.my_var = "new value"
  # @note Method names ending in '=' are treated as setters, all others as getters
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