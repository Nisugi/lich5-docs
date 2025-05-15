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
    # Module for handling Wine registry operations
    #
    # @note This module requires a valid Wine binary and prefix to function correctly.
    module Wine
      # The path to the Wine binary
      BIN = $wine_bin
      
      # The path to the Wine prefix
      PREFIX = $wine_prefix
      
      # Retrieves a value from the Wine registry.
      #
      # @param key [String] The registry key to retrieve the value from.
      # @return [String, nil] The value associated with the key, or nil if not found.
      # @raise [StandardError] If there is an issue reading the registry file.
      # @example
      #   value = Wine.registry_gets('HKEY_CURRENT_USER\\Software\\MyApp\\Setting')
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

      # Writes a value to the Wine registry.
      #
      # @param key [String] The registry key to write the value to.
      # @param value [String] The value to be written to the registry.
      # @return [Boolean] True if the operation was successful, false otherwise.
      # @raise [StandardError] If there is an issue writing to the registry.
      # @example
      #   success = Wine.registry_puts('HKEY_CURRENT_USER\\Software\\MyApp\\Setting', 'MyValue')
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