# Extensions to Ruby's built-in MatchData class to provide additional conversion methods
#
# @author Lich5 Documentation Generator
class MatchData

  # Converts the MatchData object into an OpenStruct instance where named captures
  # become method-accessible attributes
  #
  # @return [OpenStruct] An OpenStruct containing the named captures as attributes
  # @example
  #   regex = /(?<first>\w+)\s(?<last>\w+)/
  #   match = "John Smith".match(regex)
  #   struct = match.to_struct
  #   struct.first #=> "John"
  #   struct.last  #=> "Smith"
  #
  # @note All capture values are stripped of leading/trailing whitespace
  def to_struct
    OpenStruct.new to_hash
  end

  # Converts the MatchData object into a Hash where named captures become key-value pairs
  #
  # @return [Hash] A hash mapping named capture names to their values
  # @example
  #   regex = /(?<first>\w+)\s(?<last>\w+)/
  #   match = "John Smith".match(regex)
  #   match.to_hash #=> {"first" => "John", "last" => "Smith"}
  #
  # @note The following transformations are applied to capture values:
  #   - All values are stripped of leading/trailing whitespace
  #   - Values that represent integers are automatically converted to Integer objects
  #   - Non-integer values remain as String objects
  def to_hash
    Hash[self.names.zip(self.captures.map(&:strip).map do |capture|
      if capture.is_i? then capture.to_i else capture end
    end)]
  end
end