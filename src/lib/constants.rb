# Core directory and path constants for the Lich5 system
#
# This file defines the fundamental directory structure and path constants
# used throughout the Lich5 application, as well as mapping constants for
# direction handling and status icons.
#
# @author Lich5 Documentation Generator

# @!attribute [r] LICH_DIR
# The root directory of the Lich5 installation
# @return [String] Absolute path to Lich5 root directory
LICH_DIR    ||= File.dirname(File.expand_path($PROGRAM_NAME))

# @!attribute [r] TEMP_DIR
# Directory for temporary files
# @return [String] Path to temp directory, frozen
TEMP_DIR    ||= File.join(LICH_DIR, "temp").freeze

# @!attribute [r] DATA_DIR
# Directory for persistent data storage
# @return [String] Path to data directory, frozen
DATA_DIR    ||= File.join(LICH_DIR, "data").freeze

# @!attribute [r] SCRIPT_DIR
# Directory containing user scripts
# @return [String] Path to scripts directory, frozen
SCRIPT_DIR  ||= File.join(LICH_DIR, "scripts").freeze

# @!attribute [r] LIB_DIR
# Directory containing library files
# @return [String] Path to lib directory, frozen
LIB_DIR     ||= File.join(LICH_DIR, "lib").freeze

# @!attribute [r] MAP_DIR
# Directory containing map files
# @return [String] Path to maps directory, frozen
MAP_DIR     ||= File.join(LICH_DIR, "maps").freeze

# @!attribute [r] LOG_DIR
# Directory for log files
# @return [String] Path to logs directory, frozen
LOG_DIR     ||= File.join(LICH_DIR, "logs").freeze

# @!attribute [r] BACKUP_DIR
# Directory for backup files
# @return [String] Path to backup directory, frozen
BACKUP_DIR  ||= File.join(LICH_DIR, "backup").freeze

# @!attribute [r] TESTING
# Flag indicating if system is in testing mode
# @return [Boolean] false by default
TESTING = false

# add this so that require statements can take the form 'lib/file'
$LOAD_PATH << "#{LICH_DIR}"

# @deprecated Use LICH_DIR instead
# @!attribute [r] $lich_dir
# Legacy directory constant with trailing slash
# @return [String] Path with trailing slash
$lich_dir = "#{LICH_DIR}/"

# @deprecated Use TEMP_DIR instead
# @!attribute [r] $temp_dir
# Legacy temp directory constant with trailing slash
# @return [String] Path with trailing slash
$temp_dir = "#{TEMP_DIR}/"

# @deprecated Use SCRIPT_DIR instead
# @!attribute [r] $script_dir
# Legacy script directory constant with trailing slash
# @return [String] Path with trailing slash
$script_dir = "#{SCRIPT_DIR}/"

# @deprecated Use DATA_DIR instead
# @!attribute [r] $data_dir
# Legacy data directory constant with trailing slash
# @return [String] Path with trailing slash
$data_dir = "#{DATA_DIR}/"

# transcoding migrated 2024-06-13

# @!attribute [r] DIRMAP
# Maps abbreviated directions to single-character codes
# @return [Hash<String, String>] Direction mapping hash
# @example
#   DIRMAP['ne'] #=> 'B'
#   DIRMAP['down'] #=> 'J'
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

# @!attribute [r] SHORTDIR
# Maps full direction names to abbreviated forms
# @return [Hash<String, String>] Direction abbreviation mapping
# @example
#   SHORTDIR['northeast'] #=> 'ne'
#   SHORTDIR['south'] #=> 's'
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

# @!attribute [r] LONGDIR
# Maps abbreviated directions to full direction names
# @return [Hash<String, String>] Full direction name mapping
# @example
#   LONGDIR['n'] #=> 'north'
#   LONGDIR['se'] #=> 'southeast'
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

# @!attribute [r] MINDMAP
# Maps mind states to single-character codes
# @return [Hash<String, String>] Mind state mapping
# @example
#   MINDMAP['clear'] #=> 'C'
#   MINDMAP['must rest'] #=> 'G'
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

# @!attribute [r] ICONMAP
# Maps status icon names to their corresponding codes
# @return [Hash<String, String>] Status icon mapping
# @example
#   ICONMAP['IconSTANDING'] #=> 'T'
#   ICONMAP['IconHIDDEN'] #=> 'N'
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