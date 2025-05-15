# Initialization module for Lich5 that handles startup configuration, dependency checking,
# and environment setup.
#
# This module performs several key initialization tasks:
# - Checks for and removes legacy Lich 4.4 configuration
# - Verifies Ruby version compatibility
# - Sets up Windows/Wine frontend paths
# - Initializes SQLite database
# - Creates required directories
# - Sets up logging
#
# @author Lich5 Documentation Generator

# Lich5 carveout for init_db

# Checks for and removes legacy Lich 4.4 configuration file
#
# @raise [SystemExit] If legacy configuration is found
# @note Exits program if lich.sav is found
if File.exist?("#{DATA_DIR}/lich.sav")
  Lich.log "error: Archaic Lich 4.4 configuration found: Please remove #{DATA_DIR}/lich.sav"
  Lich.msgbox "error: Archaic Lich 4.4 configuration found: Please remove #{DATA_DIR}/lich.sav"
  exit
end

# Verifies Ruby version meets minimum requirements
#
# @raise [SystemExit] If Ruby version is too old
# @note Opens documentation URL on Windows if version check fails
if Gem::Version.new(RUBY_VERSION) < Gem::Version.new(REQUIRED_RUBY)
  if (RUBY_PLATFORM =~ /mingw|win/) and (RUBY_PLATFORM !~ /darwin/i)
    require 'win32ole'
    shell = WIN32OLE.new('WScript.Shell')
    message = "!!ALERT!!\nYour version #{RUBY_VERSION} of Ruby is too old!\nUpgrade Ruby to version #{REQUIRED_RUBY} or newer!\nClick OK to launch browser to go to documentation now!"
    title = "Lich v#{LICH_VERSION}"
    type = 1 + 64  # OK/Cancel buttons + Information icon
    result = shell.Popup(message, 0, title, type)

    if result == 1 # OK button clicked
      shell.Run("https://github.com/elanthia-online/lich-5/wiki/Documentation-for-Installing-and-Upgrading-Lich")
    end
  else
    puts "!!ALERT!!"
    puts "Your version #{RUBY_VERSION} of Ruby is too old!"
    puts "Upgrade Ruby to version #{REQUIRED_RUBY} or newer!"
    puts "Go to https://github.com/elanthia-online/lich-5/wiki/Documentation-for-Installing-and-Upgrading-Lich for more info!"
  end
  exit
end

require_relative 'wine'

begin
  # stupid workaround for Windows
  # seems to avoid a 10 second lag when starting lnet, without adding a 10 second lag at startup
  require 'openssl'
  OpenSSL::PKey::RSA.new(512)
rescue LoadError
  nil # not required for basic Lich; however, lnet and repository scripts will fail without openssl
rescue
  nil
end

# find the FE locations for Win and for Linux | WINE

# Sets up Windows frontend paths from registry
#
# @note Only runs on Windows systems
if (RUBY_PLATFORM =~ /mingw|win/i) && (RUBY_PLATFORM !~ /darwin/i)
  require 'win32/registry'
  include Win32

  paths = ['SOFTWARE\\WOW6432Node\\Simutronics\\STORM32',
           'SOFTWARE\\WOW6432Node\\Simutronics\\WIZ32']

  def key_exists?(path)
    Registry.open(Registry::HKEY_LOCAL_MACHINE, path, ::Win32::Registry::KEY_READ)
    true
  rescue StandardError
    false
  end

  paths.each do |path|
    next unless key_exists?(path)

    Registry.open(Registry::HKEY_LOCAL_MACHINE, path).each_value do |_subkey, _type, data|
      dirloc = data
      if path =~ /WIZ32/
        $wiz_fe_loc = dirloc
      elsif path =~ /STORM32/
        $sf_fe_loc = dirloc
      else
        Lich.log("Hammer time, couldn't find me a SIMU FE on a Windows box")
      end
    end
  end

# Sets up Wine frontend paths from registry
#
# @note Only runs on Wine/Linux systems
elsif defined?(Wine)
  ## reminder Wine is defined in the file wine.rb by confirming prefix, directory and executable
  unless (sf_fe_loc_temp = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\STORM32\\Directory'))
    sf_fe_loc_temp = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Simutronics\\STORM32\\Directory')
  end
  unless (wiz_fe_loc_temp = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Simutronics\\WIZ32\\Directory'))
    wiz_fe_loc_temp = Wine.registry_gets('HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Simutronics\\WIZ32\\Directory')
  end
  ## at this point, the temp variables are either FalseClass or have what wine believes is the Directory subkey from registry
  ## fix it up so we can use it on a *nix based system.  If the return is FalseClass, leave it FalseClass
  sf_fe_loc_temp ? $sf_fe_loc = sf_fe_loc_temp.gsub('\\', '/').gsub('C:', Wine::PREFIX + '/drive_c') : :noop
  wiz_fe_loc_temp ? $wiz_fe_loc = wiz_fe_loc_temp.gsub('\\', '/').gsub('C:', Wine::PREFIX + '/drive_c') : :noop
  ## if we have a String class (directory) and the directory exists -- no error detectable at this level
  ## if we have a nil, we have no directory, or if we have a path but cannot find that path (directory) we have an error
  if $sf_fe_loc.nil? # no directory
    Lich.log("STORM equivalent FE is not installed under WINE.") if $debug
  else
    unless $sf_fe_loc.is_a? String and File.exist?($sf_fe_loc) # cannot confirm directory location
      Lich.log("Cannot find STORM equivalent FE to launch under WINE.")
    end
  end
  if $wiz_fe_loc.nil? # no directory
    Lich.log("WIZARD FE is not installed under WINE.") if $debug
  else
    unless $wiz_fe_loc.is_a? String and File.exist?($wiz_fe_loc) # cannot confirm directory location
      Lich.log("Cannot find WIZARD FE to launch under WINE.")
    end
  end
  if $sf_fe_loc.nil? and $wiz_fe_loc.nil? # got nuttin - no FE installed under WINE in registry (or something changed. . . )
    Lich.log("This system has WINE installed but does not have a suitable FE from Simu installed under WINE.")
  end
  ## We have either declared an error, or the global variables for Simu FE are populated with a confirmed path
end

[Rest of code continues unchanged...]