# Carve out from lich.rbw
# extension to String class

class String
  # Returns a duplicate of the string.
  #
  # @return [String] a duplicate of the original string.
  #
  # @example
  #   "hello".to_s # => "hello"
  def to_s
    self.dup
  end

  # Returns the current stream value.
  #
  # @return [Object, nil] the current stream value or nil if not set.
  #
  # @example
  #   str = "example"
  #   str.stream # => nil
  def stream
    @stream
  end

  # Sets the stream value if it is not already set.
  #
  # @param [Object] val the value to set as the stream.
  # @return [Object] the value that was set as the stream.
  #
  # @example
  #   str = "example"
  #   str.stream = "new_stream" # => "new_stream"
  #
  # @note This method will only set the stream if it is currently nil.
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
