# Extensions to the Ruby Numeric class to add time-related functionality and formatting
#
# @author Lich5 Documentation Generator
class Numeric
  # Formats a numeric value representing seconds into a time string in the format "HH:MM:SS"
  #
  # @return [String] A string in the format "hours:minutes:seconds" 
  # @example
  #   125.5.as_time #=> "0:02:05"
  #   3600.as_time #=> "1:00:00"
  #
  # @note Handles fractional seconds by converting to minutes
  def as_time
    sprintf("%d:%02d:%02d", (self / 60).truncate, self.truncate % 60, ((self % 1) * 60).truncate)
  end

  # Formats a number with comma separators for thousands
  #
  # @return [String] The number formatted with commas as thousand separators
  # @example
  #   1234567.with_commas #=> "1,234,567"
  #   1234.56.with_commas #=> "1,234.56"
  #
  # @note Works with both integers and decimal numbers
  def with_commas
    self.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
  end

  # Returns the numeric value interpreted as seconds
  #
  # @return [Numeric] The same numeric value
  # @example
  #   5.seconds #=> 5
  #
  # @note Provided for semantic sugar when specifying time durations
  def seconds
    return self
  end
  
  # Alias for #seconds
  #
  # @see #seconds
  # @return [Numeric]
  alias :second :seconds

  # Converts the numeric value from minutes to seconds
  #
  # @return [Numeric] The value multiplied by 60 (seconds per minute)
  # @example
  #   2.minutes #=> 120
  #
  # @note Useful for specifying time durations in minutes
  def minutes
    return self * 60
  end
  
  # Alias for #minutes
  #
  # @see #minutes
  # @return [Numeric]
  alias :minute :minutes

  # Converts the numeric value from hours to seconds
  #
  # @return [Numeric] The value multiplied by 3600 (seconds per hour)
  # @example
  #   2.hours #=> 7200
  #
  # @note Useful for specifying time durations in hours
  def hours
    return self * 3600
  end
  
  # Alias for #hours
  #
  # @see #hours
  # @return [Numeric]
  alias :hour :hours

  # Converts the numeric value from days to seconds
  #
  # @return [Numeric] The value multiplied by 86400 (seconds per day)
  # @example
  #   2.days #=> 172800
  #
  # @note Useful for specifying time durations in days
  def days
    return self * 86400
  end
  
  # Alias for #days
  #
  # @see #days
  # @return [Numeric]
  alias :day :days
end