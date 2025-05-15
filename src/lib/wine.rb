# check for Linux | WINE (and maybe in future MacOS | WINE) first due to low population
# segment of code unmodified from Lich4 (Tillmen)
if (arg = ARGV.find { |a| a =~ /^--wine=.+$/i })
  $wine_bin = arg.sub(/^--wine=/, '')
elsif ARGV.find { |a| a =~ /^--no-wine$/i }
  $wine_bin = nil
else
  begin
    $wine_bin = `which wine`.strip
  rescue
    $wine_bin = nil
  end
end

unless $wine_bin.nil?
  if (arg = ARGV.find { |a| a =~ /^--wine-prefix=.+$/i })
    $wine_prefix = arg.sub(/^--wine-prefix=/, '')
  elsif ENV['WINEPREFIX']
    $wine_prefix = ENV['WINEPREFIX']
  elsif ENV['HOME']
    $wine_prefix = ENV['HOME'] + '/.wine'
  else
    $wine_prefix = nil
  end

  if $wine_bin and File.exist?($wine_bin) and File.file?($wine_bin) and $wine_prefix and File.exist?($wine_prefix) and File.directory?($wine_prefix)
    # Provides WINE (Wine Is Not an Emulator) integration functionality for running Windows applications on Unix-like systems.
    # This module handles WINE registry operations and configuration management.
    #
    # @author Lich5 Documentation Generator
    module Wine
      # The path to the WINE binary executable
      # @return [String] Full path to wine executable
      BIN = $wine_bin

      # The WINE prefix directory path containing the virtual Windows environment
      # @return [String] Path to WINE prefix directory  
      PREFIX = $wine_prefix

      # Retrieves a value from the WINE registry
      #
      # @param key [String] The full registry key path in format "HKEY_LOCAL_MACHINE\path\to\key" or "HKEY_CURRENT_USER\path\to\key"
      # @return [String, false] The registry value if found, false if not found or on error
      # @example Reading a registry value
      #   Wine.registry_gets("HKEY_LOCAL_MACHINE\\Software\\MyApp\\Version")
      #
      # @note Only supports HKEY_LOCAL_MACHINE registry hive currently
      # @note Reads from the system.reg file in the WINE prefix directory
      def Wine.registry_gets(key)
        hkey, subkey, thingie = /(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\(.+)\\([^\\]*)/.match(key).captures # fixme: stupid highlights ]/
        if File.exist?(PREFIX + '/system.reg')
          if hkey == 'HKEY_LOCAL_MACHINE'
            subkey = "[#{subkey.gsub('\\', '\\\\\\')}]"
            if thingie.nil? or thingie.empty?
              thingie = '@'
            else
              thingie = "\"#{thingie}\""
            end
            lookin = result = false
            File.open(PREFIX + '/system.reg') { |f| f.readlines }.each { |line|
              if line[0...subkey.length] == subkey
                lookin = true
              elsif line =~ /^\[/
                lookin = false
              elsif lookin and line =~ /^#{thingie}="(.*)"$/i
                result = $1.split('\\"').join('"').split('\\\\').join('\\').sub(/\\0$/, '')
                break
              end
            }
            return result
          else
            return false
          end
        else
          return false
        end
      end

      # Writes a value to the WINE registry
      #
      # @param key [String] The full registry key path in format "HKEY_LOCAL_MACHINE\path\to\key" or "HKEY_CURRENT_USER\path\to\key" 
      # @param value [String] The value to write to the registry key
      # @return [Boolean] true if successful, false if failed
      # @raise [SystemCallError] If unable to write temporary registry file or execute regedit
      # @example Writing a registry value
      #   Wine.registry_puts("HKEY_LOCAL_MACHINE\\Software\\MyApp\\Version", "1.0.0")
      #
      # @note Creates a temporary .reg file and uses wine regedit to import it
      # @note Automatically escapes backslashes and quotes in the value
      # @note Waits 0.2 seconds after registry write to allow for completion
      def Wine.registry_puts(key, value)
        hkey, subkey, thingie = /(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\(.+)\\([^\\]*)/.match(key).captures # fixme ]/
        if File.exist?(PREFIX)
          if thingie.nil? or thingie.empty?
            thingie = '@'
          else
            thingie = "\"#{thingie}\""
          end
          # gsub sucks for this..
          value = value.split('\\').join('\\\\')
          value = value.split('"').join('\"')
          begin
            regedit_data = "REGEDIT4\n\n[#{hkey}\\#{subkey}]\n#{thingie}=\"#{value}\"\n\n"
            filename = "#{TEMP_DIR}/wine-#{Time.now.to_i}.reg"
            File.open(filename, 'w') { |f| f.write(regedit_data) }
            system("#{BIN} regedit #{filename}")
            sleep 0.2
            File.delete(filename)
          rescue
            return false
          end
          return true
        end
      end
    end
  end
end