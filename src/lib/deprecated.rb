# Global constants and deprecated functions from the Lich5 system
#
# @author Lich5 Documentation Generator

# Current version of Lich
# @return [String] Version number
$version = LICH_VERSION

# Counter for tracking room count
# @return [Integer] Number of rooms
$room_count = 0

# Flag indicating if PSINet is enabled
# @return [Boolean] PSINet status
$psinet = false

# Flag indicating if StormFront is enabled
# @return [Boolean] StormFront status
$stormfront = true

# Deprecated method to check poison survival chances
#
# @return [Boolean] Always returns true
# @note This method is deprecated and only echoes a warning message
# @example
#   survivepoison? #=> true
def survivepoison?
  echo 'survivepoison? called, but there is no XML for poison rate'
  return true
end

# Deprecated method to check disease survival chances
#
# @return [Boolean] Always returns true
# @note This method is deprecated and only echoes a warning message
# @example
#   survivedisease? #=> true
def survivedisease?
  echo 'survivepoison? called, but there is no XML for disease rate'
  return true
end

# Automatically collects and stores loot items in a specified container
#
# @param userbagchoice [String] The container to store loot in (defaults to UserVars.lootsack)
# @return [Boolean] Returns false if no loot is present, true otherwise
# @example
#   fetchloot("backpack")
#   fetchloot # Uses default UserVars.lootsack
#
# @note Will temporarily store held items if hands are full
def fetchloot(userbagchoice = UserVars.lootsack)
  if GameObj.loot.empty?
    return false
  end

  if UserVars.excludeloot.empty?
    regexpstr = nil
  else
    regexpstr = UserVars.excludeloot.split(', ').join('|')
  end
  if checkright and checkleft
    stowed = GameObj.right_hand.noun
    fput "put my #{stowed} in my #{UserVars.lootsack}"
  else
    stowed = nil
  end
  GameObj.loot.each { |loot|
    unless not regexpstr.nil? and loot.name =~ /#{regexpstr}/
      fput "get #{loot.noun}"
      fput("put my #{loot.noun} in my #{userbagchoice}") if (checkright || checkleft)
    end
  }
  if stowed
    fput "take my #{stowed} from my #{UserVars.lootsack}"
  end
end

# Takes specified items and stores them in the default container
#
# @param items [Array<String>] List of items to take and store
# @return [void]
# @example
#   take("gem", "coin")
#   take(["gem", "coin"])
#
# @note Temporarily stores held items if hands are full
def take(*items)
  items.flatten!
  if (righthand? && lefthand?)
    weap = checkright
    fput "put my #{checkright} in my #{UserVars.lootsack}"
    unsh = true
  else
    unsh = false
  end
  items.each { |trinket|
    fput "take #{trinket}"
    fput("put my #{trinket} in my #{UserVars.lootsack}") if (righthand? || lefthand?)
  }
  if unsh then fput("take my #{weap} from my #{UserVars.lootsack}") end
end

# Extensions to the String class for Lich5 compatibility
class String
  # Converts string to single-element array for Ruby 1.8 compatibility
  #
  # @return [Array<String>] Single-element array containing the string
  # @example
  #   "test".to_a #=> ["test"]
  def to_a # for compatibility with Ruby 1.8
    [self]
  end

  # Indicates if string should be processed silently
  #
  # @return [Boolean] Always returns false
  # @example
  #   "test".silent #=> false
  def silent
    false
  end

  # Parses a list-formatted string into an array of items
  #
  # @return [Array<String>] Array of parsed items
  # @example
  #   "You see a gem and a coin.".split_as_list #=> ["a gem", "a coin"]
  #
  # @note Handles various list formats including "You see", "You notice", and "In the ... you see"
  def split_as_list
    string = self
    string.sub!(/^You (?:also see|notice) |^In the .+ you see /, ',')
    string.sub('.', '').sub(/ and (an?|some|the)/, ', \1').split(',').reject { |str| str.strip.empty? }.collect { |str| str.lstrip }
  end
end