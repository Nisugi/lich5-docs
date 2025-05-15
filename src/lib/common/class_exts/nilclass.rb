# Carve out from lich.rbw
# extension to class Nilclass 2024-06-13

class NilClass
  # Duplicates the nil object.
  #
  # @return [NilClass] always returns nil.
  #
  # @example
  #   nil.dup # => nil
  def dup
    nil
  end

  # Handles calls to methods that do not exist on the nil object.
  #
  # @param _args [Array] arguments passed to the missing method.
  # @return [NilClass] always returns nil.
  #
  # @example
  #   nil.some_non_existent_method # => nil
  def method_missing(*_args)
    nil
  end

  # Splits the nil object into an array.
  #
  # @param _val [Array] optional parameters for splitting.
  # @return [Array] returns an empty array.
  #
  # @example
  #   nil.split # => []
  def split(*_val)
    Array.new
  end

  # Converts the nil object to a string.
  #
  # @return [String] returns an empty string.
  #
  # @example
  #   nil.to_s # => ""
  def to_s
    ""
  end

  # Removes whitespace from the nil object.
  #
  # @return [String] returns an empty string.
  #
  # @example
  #   nil.strip # => ""
  def strip
    ""
  end

  # Adds a value to the nil object.
  #
  # @param [Object] val the value to add.
  # @return [Object] returns the value passed in.
  #
  # @example
  #   nil + 5 # => 5
  def +(val)
    val
  end

  # Checks if the nil object is closed.
  #
  # @return [Boolean] always returns true.
  #
  # @example
  #   nil.closed? # => true
  def closed?
    true
  end
end
