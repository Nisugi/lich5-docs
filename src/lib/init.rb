# Lich5 carveout for init_db

#
# Report an error if Lich 4.4 data is found
#
if File.exist?("#{DATA_DIR}/lich.sav")
  Lich.log "error: Archaic Lich 4.4 configuration found: Please remove #{DATA_DIR}/lich.sav"
  Lich.msgbox "error: Archaic Lich 4.4 configuration found: Please remove #{DATA_DIR}/lich.sav"
  exit
end

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

if (RUBY_PLATFORM =~ /mingw|win/i) && (RUBY_PLATFORM !~ /darwin/i)
  require 'win32/registry'
  include Win32

  paths = ['SOFTWARE\\WOW6432Node\\Simutronics\\STORM32',
           'SOFTWARE\\WOW6432Node\\Simutronics\\WIZ32']

  #
  # Checks if a registry key exists at the given path.
  #
  # @param path [String] The registry path to check.
  # @return [Boolean] Returns true if the key exists, false otherwise.
  # @raise [StandardError] Raises an error if unable to open the registry key.
  #
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
## The following should be deprecated with the direct-frontend-launch-method
## TODO: remove as part of chore/Remove unnecessary Win32 calls
## Temporarily reinstatated for DR

if (RUBY_PLATFORM =~ /mingw|win/i) and (RUBY_PLATFORM !~ /darwin/i)
  #
  # Windows API made slightly less annoying
  #
  require 'fiddle'
  require 'fiddle/import'
  module Win32
    #
    # Constants for Windows API data types and message box options.
    #
    SIZEOF_CHAR = Fiddle::SIZEOF_CHAR
    SIZEOF_LONG = Fiddle::SIZEOF_LONG
    SEE_MASK_NOCLOSEPROCESS = 0x00000040
    MB_OK = 0x00000000
    MB_OKCANCEL = 0x00000001
    MB_YESNO = 0x00000004
    MB_ICONERROR = 0x00000010
    MB_ICONQUESTION = 0x00000020
    MB_ICONWARNING = 0x00000030
    IDIOK = 1
    IDICANCEL = 2
    IDIYES = 6
    IDINO = 7
    KEY_ALL_ACCESS = 0xF003F
    KEY_CREATE_SUB_KEY = 0x0004
    KEY_ENUMERATE_SUB_KEYS = 0x0008
    KEY_EXECUTE = 0x20019
    KEY_NOTIFY = 0x0010
    KEY_QUERY_VALUE = 0x0001
    KEY_READ = 0x20019
    KEY_SET_VALUE = 0x0002
    KEY_WOW64_32KEY = 0x0200
    KEY_WOW64_64KEY = 0x0100
    KEY_WRITE = 0x20006
    TokenElevation = 20
    TOKEN_QUERY = 8
    STILL_ACTIVE = 259
    SW_SHOWNORMAL = 1
    SW_SHOW = 5
    PROCESS_QUERY_INFORMATION = 1024
    PROCESS_VM_READ = 16
    HKEY_LOCAL_MACHINE = -2147483646
    REG_NONE = 0
    REG_SZ = 1
    REG_EXPAND_SZ = 2
    REG_BINARY = 3
    REG_DWORD = 4
    REG_DWORD_LITTLE_ENDIAN = 4
    REG_DWORD_BIG_ENDIAN = 5
    REG_LINK = 6
    REG_MULTI_SZ = 7
    REG_QWORD = 11
    REG_QWORD_LITTLE_ENDIAN = 11

    #
    # Kernel32 module for Windows API functions.
    #
    module Kernel32
      extend Fiddle::Importer
      dlload 'kernel32'
      extern 'int GetCurrentProcess()'
      extern 'int GetExitCodeProcess(int, int*)'
      extern 'int GetModuleFileName(int, void*, int)'
      extern 'int GetVersionEx(void*)'
      #         extern 'int OpenProcess(int, int, int)' # fixme
      extern 'int GetLastError()'
      extern 'int CreateProcess(void*, void*, void*, void*, int, int, void*, void*, void*, void*)'
    end

    #
    # Retrieves the last error code from the Windows API.
    #
    # @return [Integer] The last error code.
    #
    def Win32.GetLastError
      return Kernel32.GetLastError()
    end

    #
    # Creates a new process with the specified parameters.
    #
    # @param args [Hash] A hash containing the parameters for process creation.
    # @option args [String] :lpApplicationName The name of the application to create.
    # @option args [String] :lpCommandLine The command line to execute.
    # @option args [Boolean] :bInheritHandles Whether to inherit handles.
    # @option args [Integer] :dwCreationFlags Flags for process creation.
    # @option args [String] :lpEnvironment The environment block for the new process.
    # @option args [String] :lpCurrentDirectory The current directory for the new process.
    # @return [Hash] A hash containing the result of the process creation.
    #   - :return [Boolean] Indicates success or failure.
    #   - :hProcess [Integer] Handle to the created process.
    #   - :hThread [Integer] Handle to the created thread.
    #   - :dwProcessId [Integer] Process ID of the created process.
    #   - :dwThreadId [Integer] Thread ID of the created thread.
    #
    def Win32.CreateProcess(args)
      if args[:lpCommandLine]
        lpCommandLine = args[:lpCommandLine].dup
      else
        lpCommandLine = nil
      end
      if args[:bInheritHandles] == false
        bInheritHandles = 0
      elsif args[:bInheritHandles] == true
        bInheritHandles = 1
      else
        bInheritHandles = args[:bInheritHandles].to_i
      end
      if args[:lpEnvironment].class == Array
        # fixme
      end
      lpStartupInfo = [68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      lpStartupInfo_index = { :lpDesktop => 2, :lpTitle => 3, :dwX => 4, :dwY => 5, :dwXSize => 6, :dwYSize => 7, :dwXCountChars => 8, :dwYCountChars => 9, :dwFillAttribute => 10, :dwFlags => 11, :wShowWindow => 12, :hStdInput => 15, :hStdOutput => 16, :hStdError => 17 }
      for sym in [:lpDesktop, :lpTitle]
        if args[sym]
          args[sym] = "#{args[sym]}\0" unless args[sym][-1, 1] == "\0"
          lpStartupInfo[lpStartupInfo_index[sym]] = Fiddle::Pointer.to_ptr(args[sym]).to_i
        end
      end
      for sym in [:dwX, :dwY, :dwXSize, :dwYSize, :dwXCountChars, :dwYCountChars, :dwFillAttribute, :dwFlags, :wShowWindow, :hStdInput, :hStdOutput, :hStdError]
        if args[sym]
          lpStartupInfo[lpStartupInfo_index[sym]] = args[sym]
        end
      end
      lpStartupInfo = lpStartupInfo.pack('LLLLLLLLLLLLSSLLLL')
      lpProcessInformation = [0, 0, 0, 0,].pack('LLLL')
      r = Kernel32.CreateProcess(args[:lpApplicationName], lpCommandLine, args[:lpProcessAttributes], args[:lpThreadAttributes], bInheritHandles, args[:dwCreationFlags].to_i, args[:lpEnvironment], args[:lpCurrentDirectory], lpStartupInfo, lpProcessInformation)
      lpProcessInformation = lpProcessInformation.unpack('LLLL')
      return :return => (r > 0 ? true : false), :hProcess => lpProcessInformation[0], :hThread => lpProcessInformation[1], :dwProcessId => lpProcessInformation[2], :dwThreadId => lpProcessInformation[3]
    end

    #      Win32.CreateProcess(:lpApplicationName => 'Launcher.exe', :lpCommandLine => 'lich2323.sal', :lpCurrentDirectory => 'C:\\PROGRA~1\\SIMU')
    #      def Win32.OpenProcess(args={})
    #         return Kernel32.OpenProcess(args[:dwDesiredAccess].to_i, args[:bInheritHandle].to_i, args[:dwProcessId].to_i)
    #      end
    #
    # Retrieves the current process ID.
    #
    # @return [Integer] The current process ID.
    #
    def Win32.GetCurrentProcess
      return Kernel32.GetCurrentProcess
    end

    #
    # Retrieves the exit code of a specified process.
    #
    # @param args [Hash] A hash containing the parameters for exit code retrieval.
    # @option args [Integer] :hProcess Handle to the process.
    # @return [Hash] A hash containing the result of the exit code retrieval.
    #   - :return [Integer] The result of the exit code retrieval.
    #   - :lpExitCode [Integer] The exit code of the specified process.
    #
    def Win32.GetExitCodeProcess(args)
      lpExitCode = [0].pack('L')
      r = Kernel32.GetExitCodeProcess(args[:hProcess].to_i, lpExitCode)
      return :return => r, :lpExitCode => lpExitCode.unpack('L')[0]
    end

    #
    # Retrieves the file name of a specified module.
    #
    # @param args [Hash] A hash containing the parameters for module file name retrieval.
    # @option args [Integer] :hModule Handle to the module.
    # @option args [Integer] :nSize The size of the buffer for the file name.
    # @return [Hash] A hash containing the result of the module file name retrieval.
    #   - :return [Integer] The result of the retrieval.
    #   - :lpFilename [String] The file name of the specified module.
    #
    def Win32.GetModuleFileName(args = {})
      args[:nSize] ||= 256
      buffer = "\0" * args[:nSize].to_i
      r = Kernel32.GetModuleFileName(args[:hModule].to_i, buffer, args[:nSize].to_i)
      return :return => r, :lpFilename => buffer.gsub("\0", '')
    end

    #
    # Retrieves version information about the operating system.
    #
    # @return [Hash] A hash containing the version information.
    #   - :return [Integer] The result of the version retrieval.
    #   - :dwOSVersionInfoSize [Integer] The size of the version information structure.
    #   - :dwMajorVersion [Integer] The major version number.
    #   - :dwMinorVersion [Integer] The minor version number.
    #   - :dwBuildNumber [Integer] The build number.
    #   - :dwPlatformId [Integer] The platform identifier.
    #   - :szCSDVersion [String] The service pack version string.
    #   - :wServicePackMajor [Integer] The major service pack number.
    #   - :wServicePackMinor [Integer] The minor service pack number.
    #   - :wSuiteMask [Integer] The suite mask.
    #   - :wProductType [Integer] The product type.
    #
    def Win32.GetVersionEx
      a = [156, 0, 0, 0, 0, ("\0" * 128), 0, 0, 0, 0, 0].pack('LLLLLa128SSSCC')
      r = Kernel32.GetVersionEx(a)
      a = a.unpack('LLLLLa128SSSCC')
      return :return => r, :dwOSVersionInfoSize => a[0], :dwMajorVersion => a[1], :dwMinorVersion => a[2], :dwBuildNumber => a[3], :dwPlatformId => a[4], :szCSDVersion => a[5].strip, :wServicePackMajor => a[6], :wServicePackMinor => a[7], :wSuiteMask => a[8], :wProductType => a[9]
    end

    module User32
      extend Fiddle::Importer
      dlload 'user32'
      extern 'int MessageBox(int, char*, char*, int)'
    end

    # Displays a message box with the specified text and caption.
    #
    # @param args [Hash] the arguments for the message box
    # @option args [Integer] :hWnd the handle to the owner window
    # @option args [String] :lpText the text to be displayed in the message box
    # @option args [String] :lpCaption the title of the message box (default: "Lich v#{LICH_VERSION}")
    # @option args [Integer] :uType the type of message box to be displayed
    # @return [Integer] the result of the message box operation
    # @example
    #   Win32.MessageBox(lpText: "Hello, World!", uType: 0)
    def Win32.MessageBox(args)
      args[:lpCaption] ||= "Lich v#{LICH_VERSION}"
      return User32.MessageBox(args[:hWnd].to_i, args[:lpText], args[:lpCaption], args[:uType].to_i)
    end

    module Advapi32
      extend Fiddle::Importer
      dlload 'advapi32'
      extern 'int GetTokenInformation(int, int, void*, int, void*)'
      extern 'int OpenProcessToken(int, int, void*)'
      extern 'int RegOpenKeyEx(int, char*, int, int, void*)'
      extern 'int RegQueryValueEx(int, char*, void*, void*, void*, void*)'
      extern 'int RegSetValueEx(int, char*, int, int, char*, int)'
      extern 'int RegDeleteValue(int, char*)'
      extern 'int RegCloseKey(int)'
    end

    # Retrieves information about a specified access token.
    #
    # @param args [Hash] the arguments for retrieving token information
    # @option args [Integer] :TokenHandle the handle to the access token
    # @option args [Integer] :TokenInformationClass the class of information to retrieve
    # @return [Hash, nil] a hash containing the result and elevation status, or nil if not applicable
    # @example
    #   Win32.GetTokenInformation(TokenHandle: some_token_handle, TokenInformationClass: TokenElevation)
    def Win32.GetTokenInformation(args)
      if args[:TokenInformationClass] == TokenElevation
        token_information_length = SIZEOF_LONG
        token_information = [0].pack('L')
      else
        return nil
      end
      return_length = [0].pack('L')
      r = Advapi32.GetTokenInformation(args[:TokenHandle].to_i, args[:TokenInformationClass], token_information, token_information_length, return_length)
      if args[:TokenInformationClass] == TokenElevation
        return :return => r, :TokenIsElevated => token_information.unpack('L')[0]
      end
    end

    # Opens the access token associated with a process.
    #
    # @param args [Hash] the arguments for opening the process token
    # @option args [Integer] :ProcessHandle the handle to the process
    # @option args [Integer] :DesiredAccess the access rights to request
    # @return [Hash] a hash containing the result and the token handle
    # @example
    #   Win32.OpenProcessToken(ProcessHandle: some_process_handle, DesiredAccess: TOKEN_QUERY)
    def Win32.OpenProcessToken(args)
      token_handle = [0].pack('L')
      r = Advapi32.OpenProcessToken(args[:ProcessHandle].to_i, args[:DesiredAccess].to_i, token_handle)
      return :return => r, :TokenHandle => token_handle.unpack('L')[0]
    end

    # Opens a registry key.
    #
    # @param args [Hash] the arguments for opening the registry key
    # @option args [Integer] :hKey the handle to the key to be opened
    # @option args [String] :lpSubKey the name of the subkey to open
    # @option args [Integer] :samDesired the desired access rights
    # @return [Hash] a hash containing the result and the handle to the opened key
    # @example
    #   Win32.RegOpenKeyEx(hKey: some_key_handle, lpSubKey: "Software\\MyApp", samDesired: KEY_READ)
    def Win32.RegOpenKeyEx(args)
      phkResult = [0].pack('L')
      r = Advapi32.RegOpenKeyEx(args[:hKey].to_i, args[:lpSubKey].to_s, 0, args[:samDesired].to_i, phkResult)
      return :return => r, :phkResult => phkResult.unpack('L')[0]
    end

    # Queries the value of a specified registry key.
    #
    # @param args [Hash] the arguments for querying the registry value
    # @option args [Integer] :hKey the handle to the key
    # @option args [String] :lpValueName the name of the value to query (default: 0)
    # @return [Hash] a hash containing the result, type, data length, and data
    # @example
    #   Win32.RegQueryValueEx(hKey: some_key_handle, lpValueName: "MyValue")
    def Win32.RegQueryValueEx(args)
      args[:lpValueName] ||= 0
      lpcbData = [0].pack('L')
      r = Advapi32.RegQueryValueEx(args[:hKey].to_i, args[:lpValueName], 0, 0, 0, lpcbData)
      if r == 0
        lpcbData = lpcbData.unpack('L')[0]
        lpData = String.new.rjust(lpcbData, "\x00")
        lpcbData = [lpcbData].pack('L')
        lpType = [0].pack('L')
        r = Advapi32.RegQueryValueEx(args[:hKey].to_i, args[:lpValueName], 0, lpType, lpData, lpcbData)
        lpType = lpType.unpack('L')[0]
        lpcbData = lpcbData.unpack('L')[0]
        if [REG_EXPAND_SZ, REG_SZ, REG_LINK].include?(lpType)
          lpData.gsub!("\x00", '')
        elsif lpType == REG_MULTI_SZ
          lpData = lpData.gsub("\x00\x00", '').split("\x00")
        elsif lpType == REG_DWORD
          lpData = lpData.unpack('L')[0]
        elsif lpType == REG_QWORD
          lpData = lpData.unpack('Q')[0]
        elsif lpType == REG_BINARY
          # fixme
        elsif lpType == REG_DWORD_BIG_ENDIAN
          # fixme
        else
          # fixme
        end
        return :return => r, :lpType => lpType, :lpcbData => lpcbData, :lpData => lpData
      else
        return :return => r
      end
    end

    # Sets the value of a specified registry key.
    #
    # @param args [Hash] the arguments for setting the registry value
    # @option args [Integer] :hKey the handle to the key
    # @option args [String] :lpValueName the name of the value to set (default: 0)
    # @option args [Integer] :dwType the type of the value
    # @option args [String, Array, Integer] :lpData the data to set
    # @return [Boolean] true if successful, false otherwise
    # @example
    #   Win32.RegSetValueEx(hKey: some_key_handle, lpValueName: "MyValue", dwType: REG_SZ, lpData: "Hello")
    def Win32.RegSetValueEx(args)
      if [REG_EXPAND_SZ, REG_SZ, REG_LINK].include?(args[:dwType]) and (args[:lpData].class == String)
        lpData = args[:lpData].dup
        lpData.concat("\x00")
        cbData = lpData.length
      elsif (args[:dwType] == REG_MULTI_SZ) and (args[:lpData].class == Array)
        lpData = args[:lpData].join("\x00").concat("\x00\x00")
        cbData = lpData.length
      elsif (args[:dwType] == REG_DWORD) and (args[:lpData].class == Integer)
        lpData = [args[:lpData]].pack('L')
        cbData = 4
      elsif (args[:dwType] == REG_QWORD) and (args[:lpData].class == Integer)
        lpData = [args[:lpData]].pack('Q')
        cbData = 8
      elsif args[:dwType] == REG_BINARY
        # fixme
        return false
      elsif args[:dwType] == REG_DWORD_BIG_ENDIAN
        # fixme
        return false
      else
        # fixme
        return false
      end
      args[:lpValueName] ||= 0
      return Advapi32.RegSetValueEx(args[:hKey].to_i, args[:lpValueName], 0, args[:dwType], lpData, cbData)
    end

    # Deletes a specified value from a registry key.
    #
    # @param args [Hash] the arguments for deleting the registry value
    # @option args [Integer] :hKey the handle to the key
    # @option args [String] :lpValueName the name of the value to delete (default: 0)
    # @return [Integer] the result of the delete operation
    # @example
    #   Win32.RegDeleteValue(hKey: some_key_handle, lpValueName: "MyValue")
    def Win32.RegDeleteValue(args)
      args[:lpValueName] ||= 0
      return Advapi32.RegDeleteValue(args[:hKey].to_i, args[:lpValueName])
    end

    # Closes a registry key handle.
    #
    # @param args [Hash] the arguments for closing the registry key
    # @option args [Integer] :hKey the handle to the key to close
    # @return [Integer] the result of the close operation
    # @example
    #   Win32.RegCloseKey(hKey: some_key_handle)
    def Win32.RegCloseKey(args)
      return Advapi32.RegCloseKey(args[:hKey])
    end

    module Shell32
      extend Fiddle::Importer
      dlload 'shell32'
      extern 'int ShellExecuteEx(void*)'
      extern 'int ShellExecute(int, char*, char*, char*, char*, int)'
    end

    # Executes a shell command with extended options.
    #
    # @param args [Hash] the arguments for executing the shell command
    # @option args [String] :lpVerb the operation to perform (e.g., "runas")
    # @option args [String] :lpFile the file to execute
    # @option args [String] :lpParameters the parameters to pass to the executable
    # @option args [String] :lpDirectory the working directory
    # @option args [Integer] :nShow the display option for the window
    # @return [Hash] a hash containing the result and process information
    # @example
    #   Win32.ShellExecuteEx(lpVerb: 'open', lpFile: 'notepad.exe')
    def Win32.ShellExecuteEx(args)
      #         struct = [ (SIZEOF_LONG * 15), 0, 0, 0, 0, 0, 0, SW_SHOWNORMAL, 0, 0, 0, 0, 0, 0, 0 ]
      struct = [(SIZEOF_LONG * 15), 0, 0, 0, 0, 0, 0, SW_SHOW, 0, 0, 0, 0, 0, 0, 0]
      struct_index = { :cbSize => 0, :fMask => 1, :hwnd => 2, :lpVerb => 3, :lpFile => 4, :lpParameters => 5, :lpDirectory => 6, :nShow => 7, :hInstApp => 8, :lpIDList => 9, :lpClass => 10, :hkeyClass => 11, :dwHotKey => 12, :hIcon => 13, :hMonitor => 13, :hProcess => 14 }
      for sym in [:lpVerb, :lpFile, :lpParameters, :lpDirectory, :lpIDList, :lpClass]
        if args[sym]
          args[sym] = "#{args[sym]}\0" unless args[sym][-1, 1] == "\0"
          struct[struct_index[sym]] = Fiddle::Pointer.to_ptr(args[sym]).to_i
        end
      end
      for sym in [:fMask, :hwnd, :nShow, :hkeyClass, :dwHotKey, :hIcon, :hMonitor, :hProcess]
        if args[sym]
          struct[struct_index[sym]] = args[sym]
        end
      end
      struct = struct.pack('LLLLLLLLLLLLLLL')
      r = Shell32.ShellExecuteEx(struct)
      struct = struct.unpack('LLLLLLLLLLLLLLL')
      return :return => r, :hProcess => struct[struct_index[:hProcess]], :hInstApp => struct[struct_index[:hInstApp]]
    end

    # Executes a shell command.
    #
    # @param args [Hash] the arguments for executing the shell command
    # @option args [Integer] :hwnd the handle to the owner window
    # @option args [String] :lpOperation the operation to perform (default: 0)
    # @option args [String] :lpFile the file to execute
    # @option args [String] :lpParameters the parameters to pass to the executable (default: 0)
    # @option args [String] :lpDirectory the working directory (default: 0)
    # @option args [Integer] :nShowCmd the display option for the window (default: 1)
    # @return [Integer] the result of the shell execution
    # @example
    #   Win32.ShellExecute(hwnd: some_handle, lpFile: 'notepad.exe')
    def Win32.ShellExecute(args)
      args[:lpOperation] ||= 0
      args[:lpParameters] ||= 0
      args[:lpDirectory] ||= 0
      args[:nShowCmd] ||= 1
      return Shell32.ShellExecute(args[:hwnd].to_i, args[:lpOperation], args[:lpFile], args[:lpParameters], args[:lpDirectory], args[:nShowCmd])
    end

    begin
      module Kernel32
        extern 'int EnumProcesses(void*, int, void*)'
      end

      # Enumerates the processes currently running on the system.
      #
      # @param args [Hash] the arguments for enumerating processes
      # @option args [Integer] :cb the size of the buffer (default: 400)
      # @return [Hash] a hash containing the result and the process IDs
      # @example
      #   Win32.EnumProcesses
      def Win32.EnumProcesses(args = {})
        args[:cb] ||= 400
        pProcessIds = Array.new((args[:cb] / SIZEOF_LONG), 0).pack(''.rjust((args[:cb] / SIZEOF_LONG), 'L'))
        pBytesReturned = [0].pack('L')
        r = Kernel32.EnumProcesses(pProcessIds, args[:cb], pBytesReturned)
        pBytesReturned = pBytesReturned.unpack('L')[0]
        return :return => r, :pProcessIds => pProcessIds.unpack(''.rjust((args[:cb] / SIZEOF_LONG), 'L'))[0...(pBytesReturned / SIZEOF_LONG)], :pBytesReturned => pBytesReturned
      end
    rescue
      module Psapi
        extend Fiddle::Importer
        dlload 'psapi'
        extern 'int EnumProcesses(void*, int, void*)'
      end

      # Enumerates the processes currently running on the system.
      #
      # @param args [Hash] the arguments for enumerating processes
      # @option args [Integer] :cb the size of the buffer (default: 400)
      # @return [Hash] a hash containing the result and the process IDs
      # @example
      #   Win32.EnumProcesses
      def Win32.EnumProcesses(args = {})
        args[:cb] ||= 400
        pProcessIds = Array.new((args[:cb] / SIZEOF_LONG), 0).pack(''.rjust((args[:cb] / SIZEOF_LONG), 'L'))
        pBytesReturned = [0].pack('L')
        r = Psapi.EnumProcesses(pProcessIds, args[:cb], pBytesReturned)
        pBytesReturned = pBytesReturned.unpack('L')[0]
        return :return => r, :pProcessIds => pProcessIds.unpack(''.rjust((args[:cb] / SIZEOF_LONG), 'L'))[0...(pBytesReturned / SIZEOF_LONG)], :pBytesReturned => pBytesReturned
      end
    end

    # Checks if the operating system is Windows XP.
    #
    # @return [Boolean] true if the OS is Windows XP, false otherwise
    # @example
    #   Win32.isXP?
    def Win32.isXP?
      return (Win32.GetVersionEx[:dwMajorVersion] < 6)
    end

    #      def Win32.isWin8?
    #         r = Win32.GetVersionEx
    #         return ((r[:dwMajorVersion] == 6) and (r[:dwMinorVersion] >= 2))
    #      end

    # Checks if the current user has administrative privileges.
    #
    # @return [Boolean] true if the user is an administrator, false otherwise
    # @example
    #   Win32.admin?
    def Win32.admin?
      if Win32.isXP?
        return true
      else
        r = Win32.OpenProcessToken(:ProcessHandle => Win32.GetCurrentProcess, :DesiredAccess => TOKEN_QUERY)
        token_handle = r[:TokenHandle]
        r = Win32.GetTokenInformation(:TokenInformationClass => TokenElevation, :TokenHandle => token_handle)
        return (r[:TokenIsElevated] != 0)
      end
    end

    # Executes a command as an administrator.
    #
    # @param args [Hash] the arguments for executing the command
    # @example
    #   Win32.AdminShellExecute(lpFile: 'notepad.exe')
    def Win32.AdminShellExecute(args)
      # open ruby/lich as admin and tell it to open something else
      if not caller.any? { |c| c =~ /eval|run/ }
        r = Win32.GetModuleFileName
        if r[:return] > 0
          if File.exist?(r[:lpFilename])
            Win32.ShellExecuteEx(:lpVerb => 'runas', :lpFile => r[:lpFilename], :lpParameters => "#{File.expand_path($PROGRAM_NAME)} shellexecute #{[Marshal.dump(args)].pack('m').gsub("\n", '')}")
          end
        end
      end
    end
  end
end

if ARGV[0] == 'shellexecute'
  # Executes a shell command using the provided arguments.
  #
  # @param args [Hash] A hash containing the operation, file, directory, and parameters.
  # @return [void]
  # @raise [ArgumentError] If the arguments are not in the expected format.
  # @example
  #   args = { op: 'open', file: 'example.txt', dir: 'C:\\', params: '' }
  #   Win32.ShellExecute(:lpOperation => args[:op], :lpFile => args[:file], :lpDirectory => args[:dir], :lpParameters => args[:params])
  args = Marshal.load(Marshal.dump(ARGV[1].unpack('m')[0]))
  Win32.ShellExecute(:lpOperation => args[:op], :lpFile => args[:file], :lpDirectory => args[:dir], :lpParameters => args[:params])
  exit
end

## End of TODO

begin
  # Attempts to require the sqlite3 gem.
  #
  # @return [void]
  # @raise [LoadError] If the sqlite3 gem is not installed.
  require 'sqlite3'
rescue LoadError
  # Handles the case where sqlite3 is not installed and prompts the user to install it.
  #
  # @return [void]
  # @raise [Win32::Error] If there is an issue with the Windows API calls.
  if defined?(Win32)
    r = Win32.MessageBox(:lpText => "Lich needs sqlite3 to save settings and data, but it is not installed.\n\nWould you like to install sqlite3 now?", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_YESNO | Win32::MB_ICONQUESTION))
    if r == Win32::IDIYES
      r = Win32.GetModuleFileName
      if r[:return] > 0
        ruby_bin_dir = File.dirname(r[:lpFilename])
        if File.exist?("#{ruby_bin_dir}\\gem.bat")
          verb = (Win32.isXP? ? 'open' : 'runas')
          r = Win32.ShellExecuteEx(:fMask => Win32::SEE_MASK_NOCLOSEPROCESS, :lpVerb => verb, :lpFile => "#{ruby_bin_dir}\\#{gem_file}", :lpParameters => 'install sqlite3 --no-ri --no-rdoc')
          if r[:return] > 0
            pid = r[:hProcess]
            sleep 1 while Win32.GetExitCodeProcess(:hProcess => pid)[:lpExitCode] == Win32::STILL_ACTIVE
            r = Win32.MessageBox(:lpText => "Install finished.  Lich will restart now.", :lpCaption => "Lich v#{LICH_VERSION}", :uType => Win32::MB_OKCANCEL)
          else
            # ShellExecuteEx failed: this seems to happen with an access denied error even while elevated on some random systems
            r = Win32.ShellExecute(:lpOperation => verb, :lpFile => "#{ruby_bin_dir}\\#{gem_file}", :lpParameters => 'install sqlite3 --no-ri --no-rdoc')
            if r <= 32
              Win32.MessageBox(:lpText => "error: failed to start the sqlite3 installer\n\nfailed command: Win32.ShellExecute(:lpOperation => #{verb.inspect}, :lpFile => \"#{ruby_bin_dir}\\#{gem_file}\", :lpParameters => \"install sqlite3 --no-ri --no-rdoc'\")\n\nerror code: #{Win32.GetLastError}", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
              exit
            end
            r = Win32.MessageBox(:lpText => "When the installer is finished, click OK to restart Lich.", :lpCaption => "Lich v#{LICH_VERSION}", :uType => Win32::MB_OKCANCEL)
          end
          if r == Win32::IDIOK
            if File.exist?("#{ruby_bin_dir}\\rubyw.exe")
              Win32.ShellExecute(:lpOperation => 'open', :lpFile => "#{ruby_bin_dir}\\rubyw.exe", :lpParameters => "\"#{File.expand_path($PROGRAM_NAME)}\"")
            else
              Win32.MessageBox(:lpText => "error: failed to find rubyw.exe; can't restart Lich for you", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
            end
          else
            # user doesn't want to restart Lich
          end
        else
          Win32.MessageBox(:lpText => "error: Could not find gem.cmd or gem.bat in directory #{ruby_bin_dir}", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
        end
      else
        Win32.MessageBox(:lpText => "error: GetModuleFileName failed", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
      end
    else
      # user doesn't want to install sqlite3 gem
    end
  else
    # fixme: no sqlite3 on Linux/Mac
    puts "The sqlite3 gem is not installed (or failed to load), you may need to: gem install sqlite3"
  end
  exit
end

unless (ARGV.grep(/^--no-(?:gtk|gui)$/).any? || RUBY_PLATFORM !~ /mingw/ && (ENV['DISPLAY'].nil? && !ARGV.include?('--gtk')))
  # Attempts to require the gtk3 gem.
  #
  # @return [void]
  # @raise [LoadError] If the gtk3 gem is not installed.
  begin
    require 'gtk3'
    HAVE_GTK = true
  rescue LoadError
    # Handles the case where gtk3 is not installed and prompts the user to install it.
    #
    # @return [void]
    # @raise [Win32::Error] If there is an issue with the Windows API calls.
    if (ENV['RUN_BY_CRON'].nil? or ENV['RUN_BY_CRON'] == 'false') and ARGV.empty? or ARGV.any? { |any_arg| any_arg =~ /^--gui$/ } or not $stdout.isatty
      if defined?(Win32)
        r = Win32.MessageBox(:lpText => "Lich uses gtk3 to create windows, but it is not installed.  You can use Lich from the command line (ruby lich.rbw --help) or you can install gtk3 for a point and click interface.\n\nWould you like to install gtk3 now?", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_YESNO | Win32::MB_ICONQUESTION))
        if r == Win32::IDIYES
          r = Win32.GetModuleFileName
          if r[:return] > 0
            ruby_bin_dir = File.dirname(r[:lpFilename])
            if File.exist?("#{ruby_bin_dir}\\gem.cmd")
              gem_file = 'gem.cmd'
            elsif File.exist?("#{ruby_bin_dir}\\gem.bat")
              gem_file = 'gem.bat'
            else
              gem_file = nil
            end
            if gem_file
              verb = (Win32.isXP? ? 'open' : 'runas')
              r = Win32.ShellExecuteEx(:fMask => Win32::SEE_MASK_NOCLOSEPROCESS, :lpVerb => verb, :lpFile => "#{ruby_bin_dir}\\gem.bat", :lpParameters => 'install gtk3 --no-ri --no-rdoc')
              if r[:return] > 0
                pid = r[:hProcess]
                sleep 1 while Win32.GetExitCodeProcess(:hProcess => pid)[:lpExitCode] == Win32::STILL_ACTIVE
                r = Win32.MessageBox(:lpText => "Install finished.  Lich will restart now.", :lpCaption => "Lich v#{LICH_VERSION}", :uType => Win32::MB_OKCANCEL)
              else
                # ShellExecuteEx failed: this seems to happen with an access denied error even while elevated on some random systems
                r = Win32.ShellExecute(:lpOperation => verb, :lpFile => "#{ruby_bin_dir}\\gem.bat", :lpParameters => 'install gtk3 --no-ri --no-rdoc')
                if r <= 32
                  Win32.MessageBox(:lpText => "error: failed to start the gtk3 installer\n\nfailed command: Win32.ShellExecute(:lpOperation => #{verb.inspect}, :lpFile => \"#{ruby_bin_dir}\\gem.bat\", :lpParameters => \"install gtk3 --no-ri --no-rdoc\")\n\nerror code: #{Win32.GetLastError}", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
                  exit
                end
                r = Win32.MessageBox(:lpText => "When the installer is finished, click OK to restart Lich.", :lpCaption => "Lich v#{LICH_VERSION}", :uType => Win32::MB_OKCANCEL)
              end
              if r == Win32::IDIOK
                if File.exist?("#{ruby_bin_dir}\\rubyw.exe")
                  Win32.ShellExecute(:lpOperation => 'open', :lpFile => "#{ruby_bin_dir}\\rubyw.exe", :lpParameters => "\"#{File.expand_path($PROGRAM_NAME)}\"")
                else
                  Win32.MessageBox(:lpText => "error: failed to find rubyw.exe; can't restart Lich for you", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
                end
              else
                # user doesn't want to restart Lich
              end
            else
              Win32.MessageBox(:lpText => "error: Could not find gem.bat in directory #{ruby_bin_dir}", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
            end
          else
            Win32.MessageBox(:lpText => "error: GetModuleFileName failed", :lpCaption => "Lich v#{LICH_VERSION}", :uType => (Win32::MB_OK | Win32::MB_ICONERROR))
          end
        else
          # user doesn't want to install gtk3 gem
        end
      else
        # fixme: no gtk3 on Linux/Mac
        puts "The gtk3 gem is not installed (or failed to load), you may need to: gem install gtk3"
      end
      exit
    else
      # gtk is optional if command line arguments are given or started in a terminal
      HAVE_GTK = false
      @early_gtk_error = "warning: failed to load GTK\n\t#{$!}\n\t#{$!.backtrace.join("\n\t")}"
    end
  end
else
  HAVE_GTK = false
  @early_gtk_error = "info: DISPLAY environment variable is not set; not trying gtk"
end

unless File.exist?(LICH_DIR)
  # Attempts to create the LICH_DIR directory if it does not exist.
  #
  # @return [void]
  # @raise [SystemCallError] If there is an error creating the directory.
  begin
    Dir.mkdir(LICH_DIR)
  rescue
    message = "An error occured while attempting to create directory #{LICH_DIR}\n\n"
    if not File.exist?(LICH_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop)
      message.concat "This was likely because the parent directory (#{LICH_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop}) doesn't exist."
    elsif defined?(Win32) and (Win32.GetVersionEx[:dwMajorVersion] >= 6) and (dir !~ /^[A-z]\:\\(Users|Documents and Settings)/)
      message.concat "This was likely because Lich doesn't have permission to create files and folders here.  It is recommended to put Lich in your Documents folder."
    else
      message.concat $!
    end
    Lich.msgbox(:message => message, :icon => :error)
    exit
  end
end

Dir.chdir(LICH_DIR)

unless File.exist?(TEMP_DIR)
  # Attempts to create the TEMP_DIR directory if it does not exist.
  #
  # @return [void]
  # @raise [SystemCallError] If there is an error creating the directory.
  begin
    Dir.mkdir(TEMP_DIR)
  rescue
    message = "An error occured while attempting to create directory #{TEMP_DIR}\n\n"
    if not File.exist?(TEMP_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop)
      message.concat "This was likely because the parent directory (#{TEMP_DIR.sub(/[\\\/]$/, '').slice(/^.+[\\\/]/).chop}) doesn't exist."
    elsif defined?(Win32) and (Win32.GetVersionEx[:dwMajorVersion] >= 6) and (dir !~ /^[A-z]\:\\(Users|Documents and Settings)/)
      message.concat "This was likely because Lich doesn't have permission to create files and folders here.  It is recommended to put Lich in your Documents folder."
    else
      message.concat $!
    end
    Lich.msgbox(:message => message, :icon => :error)
    exit
  end
end

begin
  # Attempts to create a debug log file in the TEMP_DIR.
  #
  # @return [void]
  # @raise [SystemCallError] If there is an error creating the log file.
  debug_filename = "#{TEMP_DIR}/debug-#{Time.now.strftime("%Y-%m-%d-%H-%M-%S-%L")}.log"
  $stderr = File.open(debug_filename, 'w')
rescue
  message = "An error occured while attempting to create file #{debug_filename}\n\n"
  if defined?(Win32) and (TEMP_DIR !~ /^[A-z]\:\\(Users|Documents and Settings)/) and not Win32.isXP?
    message.concat "This was likely because Lich doesn't have permission to create files and folders here.  It is recommended to put Lich in your Documents folder."
  else
    message.concat $!
  end
  Lich.msgbox(:message => message, :icon => :error)
  exit
end

$stderr.sync = true
Lich.log "info: Lich #{LICH_VERSION}"
Lich.log "info: Ruby #{RUBY_VERSION}"
Lich.log "info: #{RUBY_PLATFORM}"
Lich.log @early_gtk_error if @early_gtk_error
@early_gtk_error = nil

unless File.exist?(DATA_DIR)
  # Attempts to create the DATA_DIR directory if it does not exist.
  #
  # @return [void]
  # @raise [SystemCallError] If there is an error creating the directory.
  begin
    Dir.mkdir(DATA_DIR)
  rescue
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    Lich.msgbox(:message => "An error occured while attempting to create directory #{DATA_DIR}\n\n#{$!}", :icon => :error)
    exit
  end
end
unless File.exist?(SCRIPT_DIR)
  # Attempts to create the SCRIPT_DIR directory if it does not exist.
  #
  # @return [void]
  # @raise [SystemCallError] If there is an error creating the directory.
  begin
    Dir.mkdir(SCRIPT_DIR)
  rescue
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    Lich.msgbox(:message => "An error occured while attempting to create directory #{SCRIPT_DIR}\n\n#{$!}", :icon => :error)
    exit
  end
end
unless File.exist?("#{SCRIPT_DIR}/custom")
  # Attempts to create the custom directory within SCRIPT_DIR if it does not exist.
  #
  # @return [void]
  # @raise [SystemCallError] If there is an error creating the directory.
  begin
    Dir.mkdir("#{SCRIPT_DIR}/custom")
  rescue
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    Lich.msgbox(:message => "An error occured while attempting to create directory #{SCRIPT_DIR}/custom\n\n#{$!}", :icon => :error)
    exit
  end
end
unless File.exist?(MAP_DIR)
  # Attempts to create the MAP_DIR directory if it does not exist.
  #
  # @return [void]
  # @raise [SystemCallError] If there is an error creating the directory.
  begin
    Dir.mkdir(MAP_DIR)
  rescue
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    Lich.msgbox(:message => "An error occured while attempting to create directory #{MAP_DIR}\n\n#{$!}", :icon => :error)
    exit
  end
end
unless File.exist?(LOG_DIR)
  # Attempts to create the LOG_DIR directory if it does not exist.
  #
  # @return [void]
  # @raise [SystemCallError] If there is an error creating the directory.
  begin
    Dir.mkdir(LOG_DIR)
  rescue
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    Lich.msgbox(:message => "An error occured while attempting to create directory #{LOG_DIR}\n\n#{$!}", :icon => :error)
    exit
  end
end
unless File.exist?(BACKUP_DIR)
  # Attempts to create the BACKUP_DIR directory if it does not exist.
  #
  # @return [void]
  # @raise [SystemCallError] If there is an error creating the directory.
  begin
    Dir.mkdir(BACKUP_DIR)
  rescue
    Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    Lich.msgbox(:message => "An error occured while attempting to create directory #{BACKUP_DIR}\n\n#{$!}", :icon => :error)
    exit
  end
end

Lich.init_db

#
# only keep the last 20 debug files
#

DELETE_CANDIDATES = %r[^debug(?:-\d+)+\.log$]
if Dir.entries(TEMP_DIR).find_all { |fn| fn =~ DELETE_CANDIDATES }.length > 20 # avoid NIL response
  Dir.entries(TEMP_DIR).find_all { |fn| fn =~ DELETE_CANDIDATES }.sort.reverse[20..-1].each { |oldfile|
    begin
      File.delete(File.join(TEMP_DIR, oldfile))
    rescue
      Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
    end
  }
end

# todo: deprecate / remove for Ruby 3.2.1?
if (RUBY_VERSION =~ /^2\.[012]\./)
  begin
    did_trusted_defaults = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='did_trusted_defaults';")
  rescue SQLite3::BusyException
    sleep 0.1
    retry
  end
  if did_trusted_defaults.nil?
    Script.trust('repository')
    Script.trust('lnet')
    Script.trust('narost')
    begin
      Lich.db.execute("INSERT INTO lich_settings(name,value) VALUES('did_trusted_defaults', 'yes');")
    rescue SQLite3::BusyException
      sleep 0.1
      retry
    end
  end
end