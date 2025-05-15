# Extensions to the Ruby String class for Lich5 functionality
#
# @author Lich5 Documentation Generator
class String
  # Returns a duplicate of the string
  #
  # @return [String] A new copy of the string object
  # @example
  #   str = "test"
  #   copy = str.to_s #=> "test"
  #
  # @note This overrides the default to_s method to ensure a new string copy is returned
  def to_s
    self.dup
  end

  # Gets the stream associated with this string
  #
  # @return [Object, nil] The stream object associated with this string or nil if not set
  # @example
  #   str = "test"
  #   str.stream #=> nil
  #
  # @note Used internally by Lich5 for stream handling
  def stream
    @stream
  end

  # Sets the stream associated with this string
  #
  # @param val [Object] The stream object to associate with this string
  # @return [Object] The stream that was set
  # @example
  #   str = "test" 
  #   str.stream = some_stream_obj
  #
  # @note Will only set the stream if it hasn't been set before (uses ||=)
  # @note Used internally by Lich5 for stream handling
  def stream=(val)
    @stream ||= val
  end

  #  def to_a # for compatibility with Ruby 1.8
  #    [self]
  #  end

  #  def silent
  #    false
  #  end

  #  def split_as_list
  #    string = self
  #    string.sub!(/^You (?:also see|notice) |^In the .+ you see /, ',')
  #    string.sub('.', '').sub(/ and (an?|some|the)/, ', \1').split(',').reject { |str| str.strip.empty? }.collect { |str| str.lstrip }
  #  end
end