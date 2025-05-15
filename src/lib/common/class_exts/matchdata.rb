# extension to class MatchData 2025-03-14

class MatchData
  # Converts the MatchData object to an OpenStruct.
  #
  # @return [OpenStruct] an OpenStruct representation of the MatchData.
  #
  # @example
  #   match_data = /(\w+)/.match("hello")
  #   struct = match_data.to_struct
  #   puts struct[0] # => "hello"
  def to_struct
    OpenStruct.new to_hash
  end

  # Converts the MatchData object to a hash.
  #
  # @return [Hash] a hash where keys are the names of the captures and values are the corresponding captures.
  #
  # @note This method strips whitespace from each capture and converts numeric captures to integers.
  #
  # @example
  #   match_data = /(\d+)/.match("123")
  #   hash = match_data.to_hash
  #   puts hash # => {"0"=>"123"}
  #
  # @raise [TypeError] if names or captures are not enumerable.
  def to_hash
    Hash[self.names.zip(self.captures.map(&:strip).map do |capture|
      if capture.is_i? then capture.to_i else capture end
    end)]
  end
end