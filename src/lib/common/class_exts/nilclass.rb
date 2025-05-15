# Extensions to Ruby's NilClass to provide safe handling of nil values
# and prevent nil-related errors in the Lich5 system.
#
# @author Lich5 Documentation Generator
class NilClass

  # Creates a duplicate of nil, returning nil
  #
  # @return [nil] Always returns nil
  # @example
  #   nil.dup #=> nil
  #
  # @note This maintains consistency with Object#dup while being a no-op for nil
  def dup
    nil
  end

  # Catches any method calls to nil and returns nil instead of raising NoMethodError
  #
  # @param args [Array] Splat of any arguments passed to the missing method
  # @return [nil] Always returns nil
  # @example
  #   nil.some_undefined_method #=> nil
  #   nil.another_method(1,2,3) #=> nil
  #
  # @note Provides null object pattern behavior
  def method_missing(*_args)
    nil
  end

  # Splits nil as if it were an empty string
  #
  # @param val [Array] Splat of split arguments (ignored)
  # @return [Array] Returns an empty array
  # @example
  #   nil.split #=> []
  #   nil.split(',') #=> []
  #
  # @note Mimics String#split behavior for nil
  def split(*_val)
    Array.new
  end

  # Converts nil to an empty string
  #
  # @return [String] Returns an empty string
  # @example
  #   nil.to_s #=> ""
  #
  # @note Provides string conversion compatibility
  def to_s
    ""
  end

  # Returns an empty string as if stripping whitespace
  #
  # @return [String] Returns an empty string
  # @example
  #   nil.strip #=> ""
  #
  # @note Mimics String#strip behavior for nil
  def strip
    ""
  end

  # Adds nil to another value by returning the other value unchanged
  #
  # @param val [Object] The value to add to nil
  # @return [Object] Returns the passed value unchanged
  # @example
  #   nil + 5 #=> 5
  #   nil + "test" #=> "test"
  #
  # @note Treats nil as zero/empty for addition
  def +(val)
    val
  end

  # Checks if nil is "closed"
  #
  # @return [Boolean] Always returns true
  # @example
  #   nil.closed? #=> true
  #
  # @note Used for IO-like interface compatibility
  def closed?
    true
  end
end