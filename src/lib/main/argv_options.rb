# Handles command line argument parsing and configuration for the Lich application.
# This module processes various command-line options to configure game settings,
# frontend selection, connection details, and other runtime parameters.
#
# Command line options include:
#
# @note General Options:
# - -h, --help            Display help information
# - -V, --version         Display version and credits
# - -d, --directory       Set main program directory
# - --script-dir          Set scripts directory
# - --data-dir           Set data directory
# - --temp-dir           Set temp directory
#
# @note Frontend Options:  
# - -w, --wizard         Use Wizard frontend (default)
# - -s, --stormfront     Use StormFront frontend
# - --avalon            Use Avalon frontend
# - --frostbite         Use Frostbite frontend
#
# @note Game Options:
# - --gemstone          Connect to Gemstone IV (default)
# - --dragonrealms      Connect to DragonRealms
# - --platinum          Connect to Platinum server
# - --test              Connect to test server
# - -g, --game          Specify custom game host:port
#
# @note Other Options:
# - --dark-mode         Enable/disable dark mode
# - --install          Install registry entries
# - --uninstall        Remove registry entries
# - --no-gui           Disable GUI
# - --reconnect        Enable auto-reconnect
# - --start-scripts    Scripts to run on startup
#
# @note Most functionality is designed for Simutronics MUDs and may not work with other games
# @note Running in bare-bones mode (--bare) can improve performance for non-Simutronics games

# break out for CLI options selected at launch
# 2024-06-13

ARGV.delete_if { |arg| arg =~ /launcher\.exe/i } # added by Simutronics Game Entry

# @!attribute [r] argv_options
#   @return [Hash] Global hash containing parsed command line options
@argv_options = Hash.new
bad_args = Array.new

for arg in ARGV
  if (arg == '-h') or (arg == '--help')
    puts 'Usage:  lich [OPTION]'
    puts ''
    puts 'Options are:'
    puts '  -h, --help            Display this list.'
    puts '  -V, --version         Display the program version number and credits.'
    puts ''
    puts '  -d, --directory       Set the main Lich program directory.'
    puts '      --script-dir      Set the directoy where Lich looks for scripts.'
    puts '      --data-dir        Set the directory where Lich will store script data.'
    puts '      --temp-dir        Set the directory where Lich will store temporary files.'
    puts ''
    puts '  -w, --wizard          Run in Wizard mode (default)'
    puts '  -s, --stormfront      Run in StormFront mode.'
    puts '      --avalon          Run in Avalon mode.'
    puts '      --frostbite       Run in Frosbite mode.'
    puts ''
    puts '      --dark-mode       Enable/disable darkmode without GUI. See example below.'
    puts ''
    puts '      --gemstone        Connect to the Gemstone IV Prime server (default).'
    puts '      --dragonrealms    Connect to the DragonRealms server.'
    puts '      --platinum        Connect to the Gemstone IV/DragonRealms Platinum server.'
    puts '      --test            Connect to the test instance of the selected game server.'
    puts '  -g, --game            Set the IP address and port of the game.  See example below.'
    puts ''
    puts '      --install         Edits the Windows/WINE registry so that Lich is started when logging in using the website or SGE.'
    puts '      --uninstall       Removes Lich from the registry.'
    puts ''
    puts 'The majority of Lich\'s built-in functionality was designed and implemented with Simutronics MUDs in mind (primarily Gemstone IV): as such, many options/features provided by Lich may not be applicable when it is used with a non-Simutronics MUD.  In nearly every aspect of the program, users who are not playing a Simutronics game should be aware that if the description of a feature/option does not sound applicable and/or compatible with the current game, it should be assumed that the feature/option is not.  This particularly applies to in-script methods (commands) that depend heavily on the data received from the game conforming to specific patterns (for instance, it\'s extremely unlikely Lich will know how much "health" your character has left in a non-Simutronics game, and so the "health" script command will most likely return a value of 0).'
    puts ''
    puts 'The level of increase in efficiency when Lich is run in "bare-bones mode" (i.e. started with the --bare argument) depends on the data stream received from a given game, but on average results in a moderate improvement and it\'s recommended that Lich be run this way for any game that does not send "status information" in a format consistent with Simutronics\' GSL or XML encoding schemas.'
    puts ''
    puts ''
    puts 'Examples:'
    puts '  lich -w -d /usr/bin/lich/          (run Lich in Wizard mode using the dir \'/usr/bin/lich/\' as the program\'s home)'
    puts '  lich -g gs3.simutronics.net:4000   (run Lich using the IP address \'gs3.simutronics.net\' and the port number \'4000\')'
    puts '  lich --dragonrealms --test --genie (run Lich connected to DragonRealms Test server for the Genie frontend)'
    puts '  lich --script-dir /mydir/scripts   (run Lich with its script directory set to \'/mydir/scripts\')'
    puts '  lich --bare -g skotos.net:5555     (run in bare-bones mode with the IP address and port of the game set to \'skotos.net:5555\')'
    puts '  lich --login YourCharName --detachable-client=8000 --without-frontend --dark-mode=true'
    puts '       ... (run Lich and login without the GUI in a headless state while enabling dark mode for Lich spawned windows)'
    puts ''
    exit

[... rest of the original code continues unchanged ...]