# Directory constants for the application
LICH_DIR    ||= File.dirname(File.expand_path($PROGRAM_NAME))
TEMP_DIR    ||= File.join(LICH_DIR, "temp").freeze
DATA_DIR    ||= File.join(LICH_DIR, "data").freeze
SCRIPT_DIR  ||= File.join(LICH_DIR, "scripts").freeze
LIB_DIR     ||= File.join(LICH_DIR, "lib").freeze
MAP_DIR     ||= File.join(LICH_DIR, "maps").freeze
LOG_DIR     ||= File.join(LICH_DIR, "logs").freeze
BACKUP_DIR  ||= File.join(LICH_DIR, "backup").freeze

# Indicates whether the application is in testing mode
TESTING = false

# Adds the LICH_DIR to the load path for require statements
$LOAD_PATH << "#{LICH_DIR}"

# Deprecated global variables for directory paths
# @deprecated Use the constants defined above instead
# @note These variables will be removed in future versions
$lich_dir = "#{LICH_DIR}/"
$temp_dir = "#{TEMP_DIR}/"
$script_dir = "#{SCRIPT_DIR}/"
$data_dir = "#{DATA_DIR}/"

# Mapping of direction abbreviations to their corresponding codes
# @return [Hash] A hash mapping direction strings to their codes
# @example
#   DIRMAP['out'] # => 'K'
DIRMAP = {
  'out'  => 'K',
  'ne'   => 'B',
  'se'   => 'D',
  'sw'   => 'F',
  'nw'   => 'H',
  'up'   => 'I',
  'down' => 'J',
  'n'    => 'A',
  'e'    => 'C',
  's'    => 'E',
  'w'    => 'G',
}

# Mapping of full direction names to their abbreviations
# @return [Hash] A hash mapping full direction names to their short forms
# @example
#   SHORTDIR['northeast'] # => 'ne'
SHORTDIR = {
  'out'       => 'out',
  'northeast' => 'ne',
  'southeast' => 'se',
  'southwest' => 'sw',
  'northwest' => 'nw',
  'up'        => 'up',
  'down'      => 'down',
  'north'     => 'n',
  'east'      => 'e',
  'south'     => 's',
  'west'      => 'w',
}

# Mapping of direction abbreviations to their full names
# @return [Hash] A hash mapping direction abbreviations to their full names
# @example
#   LONGDIR['n'] # => 'north'
LONGDIR = {
  'out'  => 'out',
  'ne'   => 'northeast',
  'se'   => 'southeast',
  'sw'   => 'southwest',
  'nw'   => 'northwest',
  'up'   => 'up',
  'down' => 'down',
  'n'    => 'north',
  'e'    => 'east',
  's'    => 'south',
  'w'    => 'west',
}

# Mapping of mental state descriptions to their corresponding codes
# @return [Hash] A hash mapping mental state descriptions to their codes
# @example
#   MINDMAP['clear as a bell'] # => 'A'
MINDMAP = {
  'clear as a bell' => 'A',
  'fresh and clear' => 'B',
  'clear'           => 'C',
  'muddled'         => 'D',
  'becoming numbed' => 'E',
  'numbed'          => 'F',
  'must rest'       => 'G',
  'saturated'       => 'H',
}

# Mapping of icon names to their corresponding codes
# @return [Hash] A hash mapping icon names to their codes
# @example
#   ICONMAP['IconKNEELING'] # => 'GH'
ICONMAP = {
  'IconKNEELING'  => 'GH',
  'IconPRONE'     => 'G',
  'IconSITTING'   => 'H',
  'IconSTANDING'  => 'T',
  'IconSTUNNED'   => 'I',
  'IconHIDDEN'    => 'N',
  'IconINVISIBLE' => 'D',
  'IconDEAD'      => 'B',
  'IconWEBBED'    => 'C',
  'IconJOINED'    => 'P',
  'IconBLEEDING'  => 'O',
}