# Carve out from lich.rbw
# extension to Numeric class 2024-06-13

class Numeric
  # Converts the numeric value to a time string in the format "H:MM:SS".
  #
  # @return [String] the time representation of the numeric value.
  # @example
  #   3661.as_time # => "1:01:01"
  def as_time
    sprintf("%d:%02d:%02d", (self / 60).truncate, self.truncate % 60, ((self % 1) * 60).truncate)
  end

  # Formats the numeric value with commas as thousands separators.
  #
  # @return [String] the numeric value as a string with commas.
  # @example
  #   1000000.with_commas # => "1,000,000"
  def with_commas
    self.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
  end

  # Returns the numeric value in seconds.
  #
  # @return [Numeric] the original numeric value.
  # @example
  #   5.seconds # => 5
  def seconds
    return self
  end
  alias :second :seconds

  # Converts the numeric value to minutes.
  #
  # @return [Numeric] the numeric value in seconds.
  # @example
  #   5.minutes # => 300
  def minutes
    return self * 60
  end
  alias :minute :minutes

  # Converts the numeric value to hours.
  #
  # @return [Numeric] the numeric value in seconds.
  # @example
  #   2.hours # => 7200
  def hours
    return self * 3600
  end
  alias :hour :hours

  # Converts the numeric value to days.
  #
  # @return [Numeric] the numeric value in seconds.
  # @example
  #   1.days # => 86400
  def days
    return self * 86400
  end
  alias :day :days
end
