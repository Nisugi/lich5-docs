# Carve out from lich.rbw
# module Games on 2024-06-13

module Lich
  module Unknown
    module Game
    end
  end

  module Common
    # module Game
    # end
  end

  module Gemstone
    include Lich
    module Game
      @@socket    = nil
      @@mutex     = Mutex.new
      @@last_recv = nil
      @@thread    = nil
      @@buffer    = Lich::Common::SharedBuffer.new
      @@_buffer   = Lich::Common::SharedBuffer.new
      @@_buffer.max_size = 1000
      @@autostarted = false
      @@cli_scripts = false
      @@infomon_loaded = false
      @@room_number_after_ready = false
      @@last_id_shown_room_window = 0

      # Cleans the server string for Gemstone by replacing specific tags.
      #
      # @param server_string [String] the server string to be cleaned
      # @return [String] the cleaned server string
      # @example
      #   clean_gs_serverstring("<compDef id='room text'></compDef>")
      #   # => "<compDef id='room desc'>...</compDef>"
      def self.clean_gs_serverstring(server_string)
        # The Rift, Scatter is broken...
        if server_string =~ /<compDef id='room text'><\/compDef>/
          server_string.sub!(/(.*)\s\s<compDef id='room text'><\/compDef>/) { "<compDef id='room desc'>#{$1}</compDef>" }
        end
        return server_string
      end

      @atmospherics = false
      @combat_count = 0
      @end_combat_tags = ["<prompt", "<clearStream", "<component", "<pushStream id=\"percWindow"]

      # Cleans the server string for DragonRealms by removing superfluous tags and fixing encoding issues.
      #
      # @param server_string [String] the server string to be cleaned
      # @return [String] the cleaned server string
      # @example
      #   clean_dr_serverstring("<pushStream id=\"combat\" /><popStream id=\"combat\" />")
      #   # => ""
      # @note This method modifies the input string in place.
      def self.clean_dr_serverstring(server_string)
        ## Clear out superfluous tags
        server_string = server_string.gsub("<pushStream id=\"combat\" /><popStream id=\"combat\" />", "")
        server_string = server_string.gsub("<popStream id=\"combat\" /><pushStream id=\"combat\" />", "")

        # DR occasionally has poor encoding in text, which causes parsing errors.
        # One example of this is in the discern text for the spell Membrach's Greed
        # which gets sent as Membrach\x92s Greed. This fixes the bad encoding until
        # Simu fixes it.
        if server_string =~ /\\x92/
          Lich.log "Detected poorly encoded apostrophe: #{server_string.inspect}"
          server_string.gsub!("\x92", "'")
          Lich.log "Changed poorly encoded apostrophe to: #{server_string.inspect}"
        end

        ## Fix combat wrapping components - Why, DR, Why?
        server_string = server_string.gsub("<pushStream id=\"combat\" /><component id=", "<component id=")

        # Fixes xml with \r\n in the middle of it like:
        # We close the first line and in the next segment, we remove the trailing bits
        # <component id='room objs'>  You also see a granite altar with several candles and a water jug on it, and a granite font.\r\n
        # <component id='room extra'>Placed around the interior, you see: some furniture and other bits of interest.\r\n
        # <component id='room exits'>Obvious paths: clockwise, widdershins.\r\n

        # Followed by in a closing line such as one of these:
        # </component>\r\n
        # <compass></compass></component>\r\n

        # If the pattern is on the left of the =~ the named capture gets assigned as a variable
        if /^<(?<xmltag>dynaStream|component) id='.*'>[^<]*(?!<\/\k<xmltag>>)\r\n$/ =~ server_string
          Lich.log "Open-ended #{xmltag} tag: #{server_string.inspect}"
          server_string.gsub!("\r\n", "</#{xmltag}>")
          Lich.log "Open-ended #{xmltag} tag tag fixed to: #{server_string.inspect}"
        end

        # Remove the now dangling closing tag
        if server_string =~ /^(?:(\"|<compass><\/compass>))?<\/(dynaStream|component)>\r\n/
          Lich.log "Extraneous closing tag detected and deleted: #{server_string.inspect}"
          server_string = ""
        end

        ## Fix duplicate pushStrings
        while server_string.include?("<pushStream id=\"combat\" /><pushStream id=\"combat\" />")
          server_string = server_string.gsub("<pushStream id=\"combat\" /><pushStream id=\"combat\" />", "<pushStream id=\"combat\" />")
        end

        if @combat_count > 0
          @end_combat_tags.each do |tag|
            # server_string = "<!-- looking for tag: #{tag}" + server_string
            if server_string.include?(tag)
              server_string = server_string.gsub(tag, "<popStream id=\"combat\" />" + tag) unless server_string.include?("<popStream id=\"combat\" />")
              @combat_count -= 1
            end
            if server_string.include?("<pushStream id=\"combat\" />")
              server_string = server_string.gsub("<pushStream id=\"combat\" />", "")
            end
          end
        end

        @combat_count += server_string.scan("<pushStream id=\"combat\" />").length
        @combat_count -= server_string.scan("<popStream id=\"combat\" />").length
        @combat_count = 0 if @combat_count < 0

        if @atmospherics
          @atmospherics = false
          server_string.prepend('<popStream id="atmospherics" />') unless server_string =~ /<popStream id="atmospherics" \/>/
        end
        if server_string =~ /<pushStream id="familiar" \/><prompt time="[0-9]+">&gt;<\/prompt>/ # Cry For Help spell is broken...
          server_string.sub!('<pushStream id="familiar" />', '')
        elsif server_string =~ /<pushStream id="atmospherics" \/><prompt time="[0-9]+">&gt;<\/prompt>/ # pet pigs in DragonRealms are broken...
          server_string.sub!('<pushStream id="atmospherics" />', '')
        elsif (server_string =~ /<pushStream id="atmospherics" \/>/)
          @atmospherics = true
        end

        return server_string
      end

      # Opens a connection to the game server.
      #
      # @param host [String] the hostname or IP address of the game server.
      # @param port [Integer] the port number to connect to the game server.
      # @return [void]
      # @raise [StandardError] if there is an error while setting socket options or during connection.
      # @example
      #   Game.open('localhost', 1234)
      def Game.open(host, port)
        @@socket = TCPSocket.open(host, port)
        begin
          @@socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
        rescue
          Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        rescue StandardError
          Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
        @@socket.sync = true

        # Add check to determine if the game server hung at initial response

        @@wrap_thread = Thread.new {
          @last_recv = Time.now
          while !@@autostarted && (Time.now - @last_recv < 6)
            break if @@autostarted
            sleep 0.2
          end

          puts 'look' if !@@autostarted
        }

        @@thread = Thread.new {
          begin
            while ($_SERVERSTRING_ = @@socket.gets)
              @@last_recv = Time.now
              @@_buffer.update($_SERVERSTRING_) if TESTING
              begin
                $cmd_prefix = String.new if $_SERVERSTRING_ =~ /^\034GSw/

                unless (XMLData.game.nil? or XMLData.game.empty?)
                  unless Module.const_defined?(:GameLoader)
                    require_relative 'common/game-loader'
                    GameLoader.load!
                  end
                end

                if XMLData.game =~ /^GS/
                  $_SERVERSTRING_ = self.clean_gs_serverstring($_SERVERSTRING_)
                else
                  $_SERVERSTRING_ = self.clean_dr_serverstring($_SERVERSTRING_)
                end

                pp $_SERVERSTRING_ if $deep_debug # retain for deep troubleshooting

                $_SERVERBUFFER_.push($_SERVERSTRING_)

                if !@@autostarted and $_SERVERSTRING_ =~ /<app char/
                  if Gem::Version.new(LICH_VERSION) > Gem::Version.new(Lich.core_updated_with_lich_version)
                    Lich::Messaging.mono(Lich::Messaging.monsterbold("New installation or updated version of Lich5 detected!"))
                    Lich::Messaging.mono(Lich::Messaging.monsterbold("Installing newest core scripts available to ensure you're up-to-date!"))
                    Lich::Messaging.mono("")
                    Lich::Util::Update.update_core_data_and_scripts
                  end
                  Script.start('autostart') if Script.exists?('autostart')
                  @@autostarted = true
                  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new(RECOMMENDED_RUBY)
                    ruby_warning = Terminal::Table.new
                    ruby_warning.title = "Ruby Recommended Version Warning"
                    ruby_warning.add_row(["Please update your Ruby installation."])
                    ruby_warning.add_row(["You're currently running Ruby v#{Gem::Version.new(RUBY_VERSION)}!"])
                    ruby_warning.add_row(["It's recommended to run Ruby v#{Gem::Version.new(RECOMMENDED_RUBY)} or higher!"])
                    ruby_warning.add_row(["Future Lich5 releases will soon require this newer version."])
                    ruby_warning.add_row([" "])
                    ruby_warning.add_row(["Visit the following link for info on updating:"])
                    if XMLData.game =~ /^GS/
                      ruby_warning.add_row(["https://gswiki.play.net/Lich:Software/Installation"])
                    elsif XMLData.game =~ /^DR/
                      ruby_warning.add_row(["https://github.com/elanthia-online/lich-5/wiki/Documentation-for-Installing-and-Upgrading-Lich"])
                    else
                      ruby_warning.add_row(["Unknown game type #{XMLData.game} detected."])
                      ruby_warning.add_row(["Unsure of proper documentation, please seek assistance via discord!"])
                    end
                    ruby_warning.to_s.split("\n").each { |row|
                      Lich::Messaging.mono(Lich::Messaging.monsterbold(row))
                    }
                  end
                end

                if !@@infomon_loaded && (defined?(Infomon) || !$DRINFOMON_VERSION.nil?) && !XMLData.name.nil? && !XMLData.name.empty? && !XMLData.dialogs.empty?
                  ExecScript.start("Infomon.redo!", { :quiet => true, :name => "infomon_reset" }) if XMLData.game !~ /^DR/ && Infomon.db_refresh_needed?
                  @@infomon_loaded = true
                end

                if !@@cli_scripts && @@autostarted && !XMLData.name.nil? && !XMLData.name.empty?
                  if (arg = ARGV.find { |a| a =~ /^\-\-start\-scripts=/ })
                    for script_name in arg.sub('--start-scripts=', '').split(',')
                      Script.start(script_name)
                    end
                  end
                  @@cli_scripts = true
                  Lich.log("info: logged in as #{XMLData.game}:#{XMLData.name}")
                end
                unless $_SERVERSTRING_ =~ /^<settings /
                  begin
                    # Check for valid XML prior to sending to client, corrects double and single nested quotes
                    REXML::Document.parse_stream("<root>#{$_SERVERSTRING_}</root>", XMLData)
                  rescue
                    unless $!.to_s =~ /invalid byte sequence/
                      # Fixed invalid xml such as:
                      # <mode id="GAME"/><settingsInfo  space not found crc='0' instance='DR'/>
                      # <settingsInfo  space not found crc='0' instance='DR'/>
                      if $_SERVERSTRING_ =~ /<settingsInfo .*?space not found /
                        Lich.log "Invalid settingsInfo XML tags detected: #{$_SERVERSTRING_.inspect}"
                        $_SERVERSTRING_.sub!('space not found', '')
                        Lich.log "Invalid settingsInfo XML tags fixed to: #{$_SERVERSTRING_.inspect}"
                        retry
                      end
                      # Illegal character "&" in raw string "  You also see a large bin labeled \"Lost & Found\", a hastily scrawled notice, a brightly painted sign, a silver bell, the Registrar's Office and "
                      if $_SERVERSTRING_ =~ /\&/
                        Lich.log "Invalid \& detected: #{$_SERVERSTRING_.inspect}"
                        $_SERVERSTRING_.gsub!("&", '&amp;')
                        Lich.log "Invalid \& stripped out: #{$_SERVERSTRING_.inspect}"
                        retry
                      end
                      # Illegal character "\a" in raw string "\aYOU HAVE BEEN IDLE TOO LONG. PLEASE RESPOND.\a\n"
                      if $_SERVERSTRING_ =~ /\a/
                        Lich.log "Invalid \a detected: #{$_SERVERSTRING_.inspect}"
                        $_SERVERSTRING_.gsub!("\a", '')
                        Lich.log "Invalid \a stripped out: #{$_SERVERSTRING_.inspect}"
                        retry
                      end
                      # Fixes invalid XML with nested single quotes in it such as:
                      # From DR intro tips
                      # <link id='2' value='Ever wondered about the time you've spent in Elanthia?  Check the PLAYED verb!' cmd='played' echo='played' />
                      # From GS
                      # <d cmd='forage Imaera's Lace'>Imaera's Lace</d>, <d cmd='forage stalk burdock'>stalk of burdock</d>
                      unless (matches = $_SERVERSTRING_.scan(/'([^=>]*'[^=>]*)'/)).empty?
                        Lich.log "Invalid nested single quotes XML tags detected: #{$_SERVERSTRING_.inspect}"
                        matches.flatten.each do |match|
                          $_SERVERSTRING_.gsub!(match, match.gsub(/'/, '&apos;'))
                        end
                        Lich.log "Invalid nested single quotes XML tags fixed to: #{$_SERVERSTRING_.inspect}"
                        retry
                      end
                      # Fixes invalid XML with nested double quotes in it such as:
                      # <subtitle=" - [Avlea's Bows, "The Straight and Arrow"]">
                      unless (matches = $_SERVERSTRING_.scan(/"([^=]*"[^=]*)"/)).empty?
                        Lich.log "Invalid nested double quotes XML tags detected: #{$_SERVERSTRING_.inspect}"
                        matches.flatten.each do |match|
                          $_SERVERSTRING_.gsub!(match, match.gsub(/"/, '&quot;'))
                        end
                        Lich.log "Invalid nested double quotes XML tags fixed to: #{$_SERVERSTRING_.inspect}"
                        retry
                      end
                      $stdout.puts "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
                      Lich.log "Invalid XML detected - please report this: #{$_SERVERSTRING_.inspect}"
                      Lich.log "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
                    end
                    XMLData.reset
                  end
                  if Module.const_defined?(:GameLoader)
                    infomon_serverstring = $_SERVERSTRING_.dup
                    if XMLData.game =~ /^GS/
                      Infomon::XMLParser.parse(infomon_serverstring)
                      stripped_infomon_serverstring = strip_xml(infomon_serverstring, type: 'infomon')
                      stripped_infomon_serverstring.split("\r\n").each { |line|
                        unless line.empty?
                          Infomon::Parser.parse(line)
                        end
                      }
                    elsif XMLData.game =~ /^DR/
                      DRParser.parse(infomon_serverstring)
                    end
                  end
                  Script.new_downstream_xml($_SERVERSTRING_)
                  stripped_server = strip_xml($_SERVERSTRING_, type: 'main')
                  stripped_server.split("\r\n").each { |line|
                    @@buffer.update(line) if TESTING
                    Script.new_downstream(line) if !line.empty?
                  }
                end
                if (alt_string = DownstreamHook.run($_SERVERSTRING_))
                  #                           Buffer.update(alt_string, Buffer::DOWNSTREAM_MOD)
                  if alt_string =~ /^(?:<resource picture="\d+"\/>|<popBold\/>)?<style id="roomName"\s+\/>/
                    if (Lich.display_lichid == true || Lich.display_uid == true)
                      if XMLData.game =~ /^GS/
                        if (Lich.display_lichid == true && Lich.display_uid == true)
                          alt_string.sub!(/] \(\d+\)/) { "]" }
                          alt_string.sub!(']') { " - #{Map.current.id}] (u#{(XMLData.room_id == 0 || XMLData.room_id > 4294967296) ? "nknown" : XMLData.room_id})" }
                        elsif Lich.display_lichid == true
                          alt_string.sub!(']') { " - #{Map.current.id}]" }
                        elsif Lich.display_uid == true
                          alt_string.sub!(/] \(\d+\)/) { "]" }
                          alt_string.sub!(']') { "] (u#{(XMLData.room_id == 0 || XMLData.room_id > 4294967296) ? "nknown" : XMLData.room_id})" }
                        end
                      elsif XMLData.game =~ /^DR/
                        if Lich.display_uid == true
                          alt_string.sub!(/] \((?:\d+|\*\*)\)/) { "]" }
                        elsif Lich.hide_uid_flag == true
                          alt_string.sub!(/] \((?:\d+|\*\*)\)/) { "]" }
                        end
                      end
                    end
                    @@room_number_after_ready = true
                  end
                  if $frontend =~ /genie/i && alt_string =~ /^<streamWindow id='room' title='Room' subtitle=" - \[.*\] \((?:\d+|\*\*)\)"/
                    alt_string.sub!(/] \((?:\d+|\*\*)\)/) { "]" }
                  end
                  if @@room_number_after_ready && alt_string =~ /<prompt /
                    if Lich.display_stringprocs == true
                      room_exits = []
                      Map.current.wayto.each do |key, value|
                        # Don't include cardinals / up/down/out (usually just climb/go)
                        if value.class == Proc
                          if Map.current.timeto[key].is_a?(Numeric) || (Map.current.timeto[key].is_a?(StringProc) && Map.current.timeto[key].call.is_a?(Numeric))
                            room_exits << "<d cmd=';go2 #{key}'>#{Map[key].title.first.gsub(/\[|\]/, '')}#{Lich.display_lichid ? ('(' + Map[key].id.to_s + ')') : ''}</d>"
                          end
                        end
                      end
                      alt_string = "StringProcs: #{room_exits.join(', ')}\r\n#{alt_string}" unless room_exits.empty?
                    end
                    if Lich.display_exits == true
                      room_exits = []
                      Map.current.wayto.each do |_key, value|
                        # Don't include cardinals / up/down/out (usually just climb/go)
                        next if value.to_s =~ /^(?:o|d|u|n|ne|e|se|s|sw|w|nw|out|down|up|north|northeast|east|southeast|south|southwest|west|northwest)$/
                        if value.class != Proc
                          room_exits << "<d cmd='#{value.dump[1..-2]}'>#{value.dump[1..-2]}</d>"
                        end
                      end
                      unless room_exits.empty?
                        alt_string = "Room Exits: #{room_exits.join(', ')}\r\n#{alt_string}"
                        if XMLData.game =~ /^GS/ && ['wrayth', 'stormfront'].include?($frontend) && Map.current.id != @@last_id_shown_room_window
                          alt_string = "#{alt_string}<pushStream id='room' ifClosedStyle='watching'/>Room Exits: #{room_exits.join(', ')}\r\n<popStream/>\r\n"
                          @@last_id_shown_room_window = Map.current.id
                        end
                      end
                    end
                    if XMLData.game =~ /^DR/
                      room_number = ""
                      room_number += "#{Map.current.id}" if Lich.display_lichid
                      room_number += " - " if Lich.display_lichid && Lich.display_uid
                      room_number += "(#{XMLData.room_id == 0 ? "**" : "u#{XMLData.room_id}"})" if Lich.display_uid
                      unless room_number.empty?
                        alt_string = "Room Number: #{room_number}\r\n#{alt_string}"
                        if ['wrayth', 'stormfront'].include?($frontend)
                          alt_string = "<streamWindow id='main' title='Story' subtitle=\" - [#{XMLData.room_title[2..-3]} - #{room_number}]\" location='center' target='drop'/>\r\n#{alt_string}"
                          alt_string = "<streamWindow id='room' title='Room' subtitle=\" - [#{XMLData.room_title[2..-3]} - #{room_number}]\" location='center' target='drop' ifClosed='' resident='true'/>#{alt_string}"
                        end
                      end
                    end
                    @@room_number_after_ready = false
                  end
                  if $frontend =~ /^(?:wizard|avalon)$/
                    alt_string = sf_to_wiz(alt_string)
                  end
                  if $_DETACHABLE_CLIENT_
                    begin
                      $_DETACHABLE_CLIENT_.write(alt_string)
                    rescue
                      $_DETACHABLE_CLIENT_.close rescue nil
                      $_DETACHABLE_CLIENT_ = nil
                      respond "--- Lich: error: client_thread: #{$!}"
                      respond $!.backtrace.first
                      Lich.log "error: client_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
                    end
                  else
                    $_CLIENT_.write(alt_string)
                  end
                end
              rescue
                $stdout.puts "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
                Lich.log "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
              end
            end
          rescue StandardError
            Lich.log "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            $stdout.puts "error: server_thread: #{$!}\n\t#{$!.backtrace.slice(0..10).join("\n\t")}"
            sleep 0.2
            retry unless $_CLIENT_.closed? or @@socket.closed? or ($!.to_s =~ /invalid argument|A connection attempt failed|An existing connection was forcibly closed|An established connection was aborted by the software in your host machine./i)
          rescue
            Lich.log "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            $stdout.puts "error: server_thread: #{$!}\n\t#{$!.backtrace.slice(0..10).join("\n\t")}"
            sleep 0.2
            retry unless $_CLIENT_.closed? or @@socket.closed? or ($!.to_s =~ /invalid argument|A connection attempt failed|An existing connection was forcibly closed|An established connection was aborted by the software in your host machine./i)
          end
        }
        @@thread.priority = 4
        $_SERVER_ = @@socket # deprecated
      end

      # Returns the current thread associated with the Game.
      #
      # @return [Thread] the current game thread
      def Game.thread
        @@thread
      end

      # Checks if the game socket is closed.
      #
      # @return [Boolean] true if the socket is nil or closed, false otherwise
      def Game.closed?
        if @@socket.nil?
          true
        else
          @@socket.closed?
        end
      end

      # Closes the game socket and kills the associated thread if they exist.
      #
      # @return [nil]
      # @raise [StandardError] if closing the socket or killing the thread fails
      def Game.close
        if @@socket
          @@socket.close rescue nil
          @@thread.kill rescue nil
        end
      end

      # Sends a string to the game socket in a thread-safe manner.
      #
      # @param str [String] the string to send
      # @return [nil]
      def Game._puts(str)
        @@mutex.synchronize {
          @@socket.puts(str)
        }
      end

      # Sends a formatted string to the game socket and updates the last upstream message.
      #
      # @param str [String] the string to send
      # @return [nil]
      # @example
      #   Game.puts("Hello, World!")
      def Game.puts(str)
        $_SCRIPTIDLETIMESTAMP_ = Time.now
        if (script = Script.current)
          script_name = script.name
        else
          script_name = '(unknown script)'
        end
        $_CLIENTBUFFER_.push "[#{script_name}]#{$SEND_CHARACTER}#{$cmd_prefix}#{str}\r\n"
        if script.nil? or not script.silent
          respond "[#{script_name}]#{$SEND_CHARACTER}#{str}\r\n"
        end
        Game._puts "#{$cmd_prefix}#{str}"
        $_LASTUPSTREAM_ = "[#{script_name}]#{$SEND_CHARACTER}#{str}"
      end

      # Reads a line from the game buffer.
      #
      # @return [String] the line read from the buffer
      def Game.gets
        @@buffer.gets
      end

      # Returns the game buffer.
      #
      # @return [Buffer] the game buffer
      def Game.buffer
        @@buffer
      end

      # Reads a line from the internal buffer.
      #
      # @return [String] the line read from the internal buffer
      def Game._gets
        @@_buffer.gets
      end

      # Returns the internal buffer.
      #
      # @return [Buffer] the internal buffer
      def Game._buffer
        @@_buffer
      end
    end

    class Gift
      @@gift_start ||= Time.now
      @@pulse_count ||= 0

      # Starts the gift timer and resets the pulse count.
      #
      # @return [nil]
      # @example
      #   Gift.started
      def Gift.started
        @@gift_start = Time.now
        @@pulse_count = 0
      end

      # Increments the pulse count for the gift.
      #
      # @return [nil]
      def Gift.pulse
        @@pulse_count += 1
      end

      # Calculates the remaining time for the gift in seconds.
      #
      # @return [Float] the remaining time in seconds
      def Gift.remaining
        ([360 - @@pulse_count, 0].max * 60).to_f
      end

      # Returns the time when the gift will restart.
      #
      # @return [Time] the restart time of the gift
      def Gift.restarts_on
        @@gift_start + 594000
      end

      # Serializes the gift state into an array.
      #
      # @return [Array] an array containing the gift start time and pulse count
      def Gift.serialize
        [@@gift_start, @@pulse_count]
      end

      # Loads the serialized gift state from an array.
      #
      # @param array [Array] an array containing the gift start time and pulse count
      # @return [nil]
      def Gift.load_serialized=(array)
        @@gift_start = array[0]
        @@pulse_count = array[1].to_i
      end

      # Ends the gift by setting the pulse count to 360.
      #
      # @return [nil]
      def Gift.ended
        @@pulse_count = 360
      end

      # Placeholder for a stopwatch method.
      #
      # @return [nil]
      def Gift.stopwatch
        nil
      end
    end

    class Wounds
      # Returns the wound status of the left eye.
      #
      # @return [Wound] the wound status of the left eye
      # @example
      #   Wounds.leftEye
      def Wounds.leftEye;   fix_injury_mode; XMLData.injuries['leftEye']['wound'];   end

      # Alias for leftEye.
      #
      # @return [Wound] the wound status of the left eye
      # @example
      #   Wounds.leye
      def Wounds.leye;      fix_injury_mode; XMLData.injuries['leftEye']['wound'];   end

      # Returns the wound status of the right eye.
      #
      # @return [Wound] the wound status of the right eye
      # @example
      #   Wounds.rightEye
      def Wounds.rightEye;  fix_injury_mode; XMLData.injuries['rightEye']['wound'];  end

      # Alias for rightEye.
      #
      # @return [Wound] the wound status of the right eye
      # @example
      #   Wounds.reye
      def Wounds.reye;      fix_injury_mode; XMLData.injuries['rightEye']['wound'];  end

      # Returns the wound status of the head.
      #
      # @return [Wound] the wound status of the head
      # @example
      #   Wounds.head
      def Wounds.head;      fix_injury_mode; XMLData.injuries['head']['wound'];      end

      # Returns the wound status of the neck.
      #
      # @return [Wound] the wound status of the neck
      # @example
      #   Wounds.neck
      def Wounds.neck;      fix_injury_mode; XMLData.injuries['neck']['wound'];      end

      # Returns the wound status of the back.
      #
      # @return [Wound] the wound status of the back
      # @example
      #   Wounds.back
      def Wounds.back;      fix_injury_mode; XMLData.injuries['back']['wound'];      end

      # Returns the wound status of the chest.
      #
      # @return [Wound] the wound status of the chest
      # @example
      #   Wounds.chest
      def Wounds.chest;     fix_injury_mode; XMLData.injuries['chest']['wound'];     end

      # Returns the wound status of the abdomen.
      #
      # @return [Wound] the wound status of the abdomen
      # @example
      #   Wounds.abdomen
      def Wounds.abdomen;   fix_injury_mode; XMLData.injuries['abdomen']['wound'];   end

      # Alias for abdomen.
      #
      # @return [Wound] the wound status of the abdomen
      # @example
      #   Wounds.abs
      def Wounds.abs;       fix_injury_mode; XMLData.injuries['abdomen']['wound'];   end

      # Returns the wound status of the left arm.
      #
      # @return [Wound] the wound status of the left arm
      # @example
      #   Wounds.leftArm
      def Wounds.leftArm;   fix_injury_mode; XMLData.injuries['leftArm']['wound'];   end

      # Alias for leftArm.
      #
      # @return [Wound] the wound status of the left arm
      # @example
      #   Wounds.larm
      def Wounds.larm;      fix_injury_mode; XMLData.injuries['leftArm']['wound'];   end

      # Returns the wound status of the right arm.
      #
      # @return [Wound] the wound status of the right arm
      # @example
      #   Wounds.rightArm
      def Wounds.rightArm;  fix_injury_mode; XMLData.injuries['rightArm']['wound'];  end

      # Alias for rightArm.
      #
      # @return [Wound] the wound status of the right arm
      # @example
      #   Wounds.rarm
      def Wounds.rarm;      fix_injury_mode; XMLData.injuries['rightArm']['wound'];  end

      # Returns the wound status of the right hand.
      #
      # @return [Wound] the wound status of the right hand
      # @example
      #   Wounds.rightHand
      def Wounds.rightHand; fix_injury_mode; XMLData.injuries['rightHand']['wound']; end

      # Alias for rightHand.
      #
      # @return [Wound] the wound status of the right hand
      # @example
      #   Wounds.rhand
      def Wounds.rhand;     fix_injury_mode; XMLData.injuries['rightHand']['wound']; end

      # Returns the wound status of the left hand.
      #
      # @return [Wound] the wound status of the left hand
      # @example
      #   Wounds.leftHand
      def Wounds.leftHand;  fix_injury_mode; XMLData.injuries['leftHand']['wound'];  end

      # Alias for leftHand.
      #
      # @return [Wound] the wound status of the left hand
      # @example
      #   Wounds.lhand
      def Wounds.lhand;     fix_injury_mode; XMLData.injuries['leftHand']['wound'];  end

      # Returns the wound status of the left leg.
      #
      # @return [Wound] the wound status of the left leg
      # @example
      #   Wounds.leftLeg
      def Wounds.leftLeg;   fix_injury_mode; XMLData.injuries['leftLeg']['wound'];   end

      # Alias for leftLeg.
      #
      # @return [Wound] the wound status of the left leg
      # @example
      #   Wounds.lleg
      def Wounds.lleg;      fix_injury_mode; XMLData.injuries['leftLeg']['wound'];   end

      # Returns the wound status of the right leg.
      #
      # @return [Wound] the wound status of the right leg
      # @example
      #   Wounds.rightLeg
      def Wounds.rightLeg;  fix_injury_mode; XMLData.injuries['rightLeg']['wound'];  end

      # Alias for rightLeg.
      #
      # @return [Wound] the wound status of the right leg
      # @example
      #   Wounds.rleg
      def Wounds.rleg;      fix_injury_mode; XMLData.injuries['rightLeg']['wound'];  end

      # Returns the wound status of the left foot.
      #
      # @return [Wound] the wound status of the left foot
      # @example
      #   Wounds.leftFoot
      def Wounds.leftFoot;  fix_injury_mode; XMLData.injuries['leftFoot']['wound'];  end

      # Returns the wound status of the right foot.
      #
      # @return [Wound] the wound status of the right foot
      # @example
      #   Wounds.rightFoot
      def Wounds.rightFoot; fix_injury_mode; XMLData.injuries['rightFoot']['wound']; end

      # Returns the wound status of the nervous system.
      #
      # @return [Wound] the wound status of the nervous system
      # @example
      #   Wounds.nsys
      def Wounds.nsys;      fix_injury_mode; XMLData.injuries['nsys']['wound'];      end

      # Returns the wound status of the nerves.
      #
      # @return [Wound] the wound status of the nerves
      # @example
      #   Wounds.nerves
      def Wounds.nerves;    fix_injury_mode; XMLData.injuries['nsys']['wound'];      end

      # Returns the maximum wound status among the arms.
      #
      # @return [Wound] the maximum wound status of the arms
      # @example
      #   Wounds.arms
      def Wounds.arms
        fix_injury_mode
        [XMLData.injuries['leftArm']['wound'], XMLData.injuries['rightArm']['wound'], XMLData.injuries['leftHand']['wound'], XMLData.injuries['rightHand']['wound']].max
      end

      # Returns the maximum wound status among the limbs.
      #
      # @return [Wound] the maximum wound status of the limbs
      # @example
      #   Wounds.limbs
      def Wounds.limbs
        fix_injury_mode
        [XMLData.injuries['leftArm']['wound'], XMLData.injuries['rightArm']['wound'], XMLData.injuries['leftHand']['wound'], XMLData.injuries['rightHand']['wound'], XMLData.injuries['leftLeg']['wound'], XMLData.injuries['rightLeg']['wound']].max
      end

      # Returns the maximum wound status of the torso.
      #
      # @return [Wound] the maximum wound status of the torso
      # @example
      #   Wounds.torso
      def Wounds.torso
        fix_injury_mode
        [XMLData.injuries['rightEye']['wound'], XMLData.injuries['leftEye']['wound'], XMLData.injuries['chest']['wound'], XMLData.injuries['abdomen']['wound'], XMLData.injuries['back']['wound']].max
      end

      # Handles invalid area requests for wounds.
      #
      # @param _arg [nil] ignored parameter
      # @return [nil]
      def Wounds.method_missing(_arg = nil)
        echo "Wounds: Invalid area, try one of these: arms, limbs, torso, #{XMLData.injuries.keys.join(', ')}"
        nil
      end
    end

    class Scars
      # Returns the scar status of the left eye.
      #
      # @return [Scar] the scar status of the left eye
      # @example
      #   Scars.leftEye
      def Scars.leftEye;   fix_injury_mode; XMLData.injuries['leftEye']['scar'];   end

      # Alias for leftEye.
      #
      # @return [Scar] the scar status of the left eye
      # @example
      #   Scars.leye
      def Scars.leye;      fix_injury_mode; XMLData.injuries['leftEye']['scar'];   end

      # Returns the scar status of the right eye.
      #
      # @return [Scar] the scar status of the right eye
      # @example
      #   Scars.rightEye
      def Scars.rightEye;  fix_injury_mode; XMLData.injuries['rightEye']['scar'];  end

      # Alias for rightEye.
      #
      # @return [Scar] the scar status of the right eye
      # @example
      #   Scars.reye
      def Scars.reye;      fix_injury_mode; XMLData.injuries['rightEye']['scar'];  end

      # Returns the scar status of the head.
      #
      # @return [Scar] the scar status of the head
      # @example
      #   Scars.head
      def Scars.head;      fix_injury_mode; XMLData.injuries['head']['scar'];      end

      # Returns the scar status of the neck.
      #
      # @return [Scar] the scar status of the neck
      # @example
      #   Scars.neck
      def Scars.neck;      fix_injury_mode; XMLData.injuries['neck']['scar'];      end

      # Returns the scar status of the back.
      #
      # @return [Scar] the scar status of the back
      # @example
      #   Scars.back
      def Scars.back;      fix_injury_mode; XMLData.injuries['back']['scar'];      end

      # Returns the scar status of the chest.
      #
      # @return [Scar] the scar status of the chest
      # @example
      #   Scars.chest
      def Scars.chest;     fix_injury_mode; XMLData.injuries['chest']['scar'];     end

      # Returns the scar status of the abdomen.
      #
      # @return [Scar] the scar status of the abdomen
      # @example
      #   Scars.abdomen
      def Scars.abdomen;   fix_injury_mode; XMLData.injuries['abdomen']['scar'];   end

      # Alias for abdomen.
      #
      # @return [Scar] the scar status of the abdomen
      # @example
      #   Scars.abs
      def Scars.abs;       fix_injury_mode; XMLData.injuries['abdomen']['scar'];   end

      # Returns the scar status of the left arm.
      #
      # @return [Scar] the scar status of the left arm
      # @example
      #   Scars.leftArm
      def Scars.leftArm;   fix_injury_mode; XMLData.injuries['leftArm']['scar'];   end

      # Alias for leftArm.
      #
      # @return [Scar] the scar status of the left arm
      # @example
      #   Scars.larm
      def Scars.larm;      fix_injury_mode; XMLData.injuries['leftArm']['scar'];   end

      # Returns the scar status of the right arm.
      #
      # @return [Scar] the scar status of the right arm
      # @example
      #   Scars.rightArm
      def Scars.rightArm;  fix_injury_mode; XMLData.injuries['rightArm']['scar'];  end

      # Alias for rightArm.
      #
      # @return [Scar] the scar status of the right arm
      # @example
      #   Scars.rarm
      def Scars.rarm;      fix_injury_mode; XMLData.injuries['rightArm']['scar'];  end

      # Returns the scar status of the right hand.
      #
      # @return [Scar] the scar status of the right hand
      # @example
      #   Scars.rightHand
      def Scars.rightHand; fix_injury_mode; XMLData.injuries['rightHand']['scar']; end

      # Alias for rightHand.
      #
      # @return [Scar] the scar status of the right hand
      # @example
      #   Scars.rhand
      def Scars.rhand;     fix_injury_mode; XMLData.injuries['rightHand']['scar']; end

      # Returns the scar status of the left hand.
      #
      # @return [Scar] the scar status of the left hand
      # @example
      #   Scars.leftHand
      def Scars.leftHand;  fix_injury_mode; XMLData.injuries['leftHand']['scar'];  end

      # Alias for leftHand.
      #
      # @return [Scar] the scar status of the left hand
      # @example
      #   Scars.lhand
      def Scars.lhand;     fix_injury_mode; XMLData.injuries['leftHand']['scar'];  end

      # Returns the scar status of the left leg.
      #
      # @return [Scar] the scar status of the left leg
      # @example
      #   Scars.lefgLeg
      def Scars.leftLeg;   fix_injury_mode; XMLData.injuries['leftLeg']['scar'];   end

      # Alias for leftLeg.
      #
      # @return [Scar] the scar status of the left leg
      # @example
      #   Scars.lleg
      def Scars.lleg;      fix_injury_mode; XMLData.injuries['leftLeg']['scar'];   end

      # Returns the scar status of the right leg.
      #
      # @return [Scar] the scar status of the right leg
      # @example
      #   Scars.rightLeg
      def Scars.rightLeg;  fix_injury_mode; XMLData.injuries['rightLeg']['scar'];  end

      # Alias for rightLeg.
      #
      # @return [Scar] the scar status of the right leg
      # @example
      #   Scars.rleg
      def Scars.rleg;      fix_injury_mode; XMLData.injuries['rightLeg']['scar'];  end

      # Returns the scar status of the left foot.
      #
      # @return [Scar] the scar status of the left foot
      # @example
      #   Scars.leftFoot
      def Scars.leftFoot;  fix_injury_mode; XMLData.injuries['leftFoot']['scar'];  end

      # Returns the scar status of the right foot.
      #
      # @return [Scar] the scar status of the right foot
      # @example
      #   Scars.rightFoot
      def Scars.rightFoot; fix_injury_mode; XMLData.injuries['rightFoot']['scar']; end

      # Retrieves the scar value for the nsys area after fixing the injury mode.
      #
      # @return [Integer] the scar value for the nsys area.
      # @example
      #   Scars.nsys
      def Scars.nsys;      fix_injury_mode; XMLData.injuries['nsys']['scar'];      end

      # Retrieves the scar value for the nerves area after fixing the injury mode.
      #
      # @return [Integer] the scar value for the nerves area.
      # @example
      #   Scars.nerves
      def Scars.nerves;    fix_injury_mode; XMLData.injuries['nsys']['scar'];      end

      # Retrieves the maximum scar value among the arms and hands after fixing the injury mode.
      #
      # @return [Integer] the maximum scar value for arms and hands.
      # @example
      #   Scars.arms
      def Scars.arms
        fix_injury_mode
        [XMLData.injuries['leftArm']['scar'], XMLData.injuries['rightArm']['scar'], XMLData.injuries['leftHand']['scar'], XMLData.injuries['rightHand']['scar']].max
      end

      # Retrieves the maximum scar value among all limbs after fixing the injury mode.
      #
      # @return [Integer] the maximum scar value for all limbs.
      # @example
      #   Scars.limbs
      def Scars.limbs
        fix_injury_mode
        [XMLData.injuries['leftArm']['scar'], XMLData.injuries['rightArm']['scar'], XMLData.injuries['leftHand']['scar'], XMLData.injuries['rightHand']['scar'], XMLData.injuries['leftLeg']['scar'], XMLData.injuries['rightLeg']['scar']].max
      end

      # Retrieves the maximum scar value among the torso areas after fixing the injury mode.
      #
      # @return [Integer] the maximum scar value for the torso.
      # @example
      #   Scars.torso
      def Scars.torso
        fix_injury_mode
        [XMLData.injuries['rightEye']['scar'], XMLData.injuries['leftEye']['scar'], XMLData.injuries['chest']['scar'], XMLData.injuries['abdomen']['scar'], XMLData.injuries['back']['scar']].max
      end

      # Handles calls to undefined methods for the Scars class.
      #
      # @param _arg [nil] an optional argument that is ignored.
      # @return [nil] always returns nil.
      # @note This method provides feedback on valid areas to check for scars.
      # @example
      #   Scars.invalid_method
      def Scars.method_missing(_arg = nil)
        echo "Scars: Invalid area, try one of these: arms, limbs, torso, #{XMLData.injuries.keys.join(', ')}"
        nil
      end
    end
  end

  module DragonRealms
    include Lich
    module Game
      @@socket    = nil
      @@mutex     = Mutex.new
      @@last_recv = nil
      @@thread    = nil
      @@buffer    = Lich::Common::SharedBuffer.new
      @@_buffer   = Lich::Common::SharedBuffer.new
      @@_buffer.max_size = 1000
      @@autostarted = false
      @@cli_scripts = false
      @@infomon_loaded = false
      @@room_number_after_ready = false
      @@last_id_shown_room_window = 0

      # Cleans the game server string by replacing specific tags.
      #
      # @param server_string [String] The server string to be cleaned.
      # @return [String] The cleaned server string.
      # @example
      #   cleaned_string = DragonRealms::Game.clean_gs_serverstring("<compDef id='room text'></compDef>")
      def self.clean_gs_serverstring(server_string)
        # The Rift, Scatter is broken...
        if server_string =~ /<compDef id='room text'><\/compDef>/
          server_string.sub!(/(.*)\s\s<compDef id='room text'><\/compDef>/) { "<compDef id='room desc'>#{$1}</compDef>" }
        end
        return server_string
      end

      @atmospherics = false
      @combat_count = 0
      @end_combat_tags = ["<prompt", "<clearStream", "<component", "<pushStream id=\"percWindow"]

      # Cleans the DragonRealms server string by removing superfluous tags and fixing encoding issues.
      #
      # @param server_string [String] The server string to be cleaned.
      # @return [String] The cleaned server string.
      # @note This method modifies the input string in place.
      # @example
      #   cleaned_string = DragonRealms::Game.clean_dr_serverstring("<pushStream id=\"combat\" /><popStream id=\"combat\" />")
      def self.clean_dr_serverstring(server_string)
        ## Clear out superfluous tags
        server_string = server_string.gsub("<pushStream id=\"combat\" /><popStream id=\"combat\" />", "")
        server_string = server_string.gsub("<popStream id=\"combat\" /><pushStream id=\"combat\" />", "")

        # DR occasionally has poor encoding in text, which causes parsing errors.
        # One example of this is in the discern text for the spell Membrach's Greed
        # which gets sent as Membrach\x92s Greed. This fixes the bad encoding until
        # Simu fixes it.
        if server_string =~ /\\x92/
          Lich.log "Detected poorly encoded apostrophe: #{server_string.inspect}"
          server_string.gsub!("\x92", "'")
          Lich.log "Changed poorly encoded apostrophe to: #{server_string.inspect}"
        end

        ## Fix combat wrapping components - Why, DR, Why?
        server_string = server_string.gsub("<pushStream id=\"combat\" /><component id=", "<component id=")

        # Fixes xml with \r\n in the middle of it like:
        # We close the first line and in the next segment, we remove the trailing bits
        # <component id='room objs'>  You also see a granite altar with several candles and a water jug on it, and a granite font.\r\n
        # <component id='room extra'>Placed around the interior, you see: some furniture and other bits of interest.\r\n
        # <component id='room exits'>Obvious paths: clockwise, widdershins.\r\n

        # Followed by in a closing line such as one of these:
        # </component>\r\n
        # <compass></compass></component>\r\n

        # If the pattern is on the left of the =~ the named capture gets assigned as a variable
        if /^<(?<xmltag>dynaStream|component) id='.*'>[^<]*(?!<\/\k<xmltag>>)\r\n$/ =~ server_string
          Lich.log "Open-ended #{xmltag} tag: #{server_string.inspect}"
          server_string.gsub!("\r\n", "</#{xmltag}>")
          Lich.log "Open-ended #{xmltag} tag tag fixed to: #{server_string.inspect}"
        end

        # Remove the now dangling closing tag
        if server_string =~ /^(?:(\"|<compass><\/compass>))?<\/(dynaStream|component)>\r\n/
          Lich.log "Extraneous closing tag detected and deleted: #{server_string.inspect}"
          server_string = ""
        end

        ## Fix duplicate pushStrings
        while server_string.include?("<pushStream id=\"combat\" /><pushStream id=\"combat\" />")
          server_string = server_string.gsub("<pushStream id=\"combat\" /><pushStream id=\"combat\" />", "<pushStream id=\"combat\" />")
        end

        if @combat_count > 0
          @end_combat_tags.each do |tag|
            # server_string = "<!-- looking for tag: #{tag}" + server_string
            if server_string.include?(tag)
              server_string = server_string.gsub(tag, "<popStream id=\"combat\" />" + tag) unless server_string.include?("<popStream id=\"combat\" />")
              @combat_count -= 1
            end
            if server_string.include?("<pushStream id=\"combat\" />")
              server_string = server_string.gsub("<pushStream id=\"combat\" />", "")
            end
          end
        end

        @combat_count += server_string.scan("<pushStream id=\"combat\" />").length
        @combat_count -= server_string.scan("<popStream id=\"combat\" />").length
        @combat_count = 0 if @combat_count < 0

        if @atmospherics
          @atmospherics = false
          server_string.prepend('<popStream id="atmospherics" />') unless server_string =~ /<popStream id="atmospherics" \/>/
        end
        if server_string =~ /<pushStream id="familiar" \/><prompt time="[0-9]+">&gt;<\/prompt>/ # Cry For Help spell is broken...
          server_string.sub!('<pushStream id="familiar" />', '')
        elsif server_string =~ /<pushStream id="atmospherics" \/><prompt time="[0-9]+">&gt;<\/prompt>/ # pet pigs in DragonRealms are broken...
          server_string.sub!('<pushStream id="atmospherics" />', '')
        elsif (server_string =~ /<pushStream id="atmospherics" \/>/)
          @atmospherics = true
        end

        return server_string
      end

      # Opens a connection to the game server.
      #
      # @param host [String] the hostname or IP address of the game server.
      # @param port [Integer] the port number to connect to on the game server.
      # @return [void]
      # @raise [StandardError] if there is an error while setting socket options or during connection.
      # @example
      #   Game.open('localhost', 1234)
      def Game.open(host, port)
        @@socket = TCPSocket.open(host, port)
        begin
          @@socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
        rescue
          Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        rescue StandardError
          Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
        @@socket.sync = true

        # Add check to determine if the game server hung at initial response

        @@wrap_thread = Thread.new {
          @last_recv = Time.now
          while !@@autostarted && (Time.now - @last_recv < 6)
            break if @@autostarted
            sleep 0.2
          end

          puts 'look' if !@@autostarted
        }

        @@thread = Thread.new {
          begin
            while ($_SERVERSTRING_ = @@socket.gets)
              @@last_recv = Time.now
              @@_buffer.update($_SERVERSTRING_) if TESTING
              begin
                $cmd_prefix = String.new if $_SERVERSTRING_ =~ /^\034GSw/

                unless (XMLData.game.nil? or XMLData.game.empty?)
                  unless Module.const_defined?(:GameLoader)
                    require_relative 'common/game-loader'
                    GameLoader.load!
                  end
                end

                if XMLData.game =~ /^GS/
                  $_SERVERSTRING_ = self.clean_gs_serverstring($_SERVERSTRING_)
                else
                  $_SERVERSTRING_ = self.clean_dr_serverstring($_SERVERSTRING_)
                end

                $_SERVERBUFFER_.push($_SERVERSTRING_)

                if !@@autostarted and $_SERVERSTRING_ =~ /<app char/
                  if Gem::Version.new(LICH_VERSION) > Gem::Version.new(Lich.core_updated_with_lich_version)
                    Lich::Messaging.mono(Lich::Messaging.monsterbold("New installation or updated version of Lich5 detected!"))
                    Lich::Messaging.mono(Lich::Messaging.monsterbold("Installing newest core scripts available to ensure you're up-to-date!"))
                    Lich::Messaging.mono("")
                    Lich::Util::Update.update_core_data_and_scripts
                  end
                  Script.start('autostart') if Script.exists?('autostart')
                  @@autostarted = true
                  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new(RECOMMENDED_RUBY)
                    ruby_warning = Terminal::Table.new
                    ruby_warning.title = "Ruby Recommended Version Warning"
                    ruby_warning.add_row(["Please update your Ruby installation."])
                    ruby_warning.add_row(["You're currently running Ruby v#{Gem::Version.new(RUBY_VERSION)}!"])
                    ruby_warning.add_row(["It's recommended to run Ruby v#{Gem::Version.new(RECOMMENDED_RUBY)} or higher!"])
                    ruby_warning.add_row(["Future Lich5 releases will soon require this newer version."])
                    ruby_warning.add_row([" "])
                    ruby_warning.add_row(["Visit the following link for info on updating:"])
                    if XMLData.game =~ /^GS/
                      ruby_warning.add_row(["https://gswiki.play.net/Lich:Software/Installation"])
                    elsif XMLData.game =~ /^DR/
                      ruby_warning.add_row(["https://github.com/elanthia-online/lich-5/wiki/Documentation-for-Installing-and-Upgrading-Lich"])
                    else
                      ruby_warning.add_row(["Unknown game type #{XMLData.game} detected."])
                      ruby_warning.add_row(["Unsure of proper documentation, please seek assistance via discord!"])
                    end
                    ruby_warning.to_s.split("\n").each { |row|
                      Lich::Messaging.mono(Lich::Messaging.monsterbold(row))
                    }
                  end
                end

                if !@@infomon_loaded && (defined?(Infomon) || !$DRINFOMON_VERSION.nil?) && !XMLData.name.nil? && !XMLData.name.empty? && !XMLData.dialogs.empty?
                  ExecScript.start("Infomon.redo!", { :quiet => true, :name => "infomon_reset" }) if XMLData.game !~ /^DR/ && Infomon.db_refresh_needed?
                  @@infomon_loaded = true
                end

                if !@@cli_scripts && @@autostarted && !XMLData.name.nil? && !XMLData.name.empty?
                  if (arg = ARGV.find { |a| a =~ /^\-\-start\-scripts=/ })
                    for script_name in arg.sub('--start-scripts=', '').split(',')
                      Script.start(script_name)
                    end
                  end
                  @@cli_scripts = true
                  Lich.log("info: logged in as #{XMLData.game}:#{XMLData.name}")
                end
                unless $_SERVERSTRING_ =~ /^<settings /
                  begin
                    # Check for valid XML prior to sending to client, corrects double and single nested quotes
                    REXML::Document.parse_stream("<root>#{$_SERVERSTRING_}</root>", XMLData)
                  rescue
                    unless $!.to_s =~ /invalid byte sequence/
                      # Fixed invalid xml such as:
                      # <mode id="GAME"/><settingsInfo  space not found crc='0' instance='DR'/>
                      # <settingsInfo  space not found crc='0' instance='DR'/>
                      if $_SERVERSTRING_ =~ /<settingsInfo .*?space not found /
                        Lich.log "Invalid settingsInfo XML tags detected: #{$_SERVERSTRING_.inspect}"
                        $_SERVERSTRING_.sub!('space not found', '')
                        Lich.log "Invalid settingsInfo XML tags fixed to: #{$_SERVERSTRING_.inspect}"
                        retry
                      end
                      # Illegal character "&" in raw string "  You also see a large bin labeled \"Lost & Found\", a hastily scrawled notice, a brightly painted sign, a silver bell, the Registrar's Office and "
                      if $_SERVERSTRING_ =~ /\&/
                        Lich.log "Invalid \& detected: #{$_SERVERSTRING_.inspect}"
                        $_SERVERSTRING_.gsub!("&", '&amp;')
                        Lich.log "Invalid \& stripped out: #{$_SERVERSTRING_.inspect}"
                        retry
                      end
                      # Illegal character "\a" in raw string "\aYOU HAVE BEEN IDLE TOO LONG. PLEASE RESPOND.\a\n"
                      if $_SERVERSTRING_ =~ /\a/
                        Lich.log "Invalid \a detected: #{$_SERVERSTRING_.inspect}"
                        $_SERVERSTRING_.gsub!("\a", '')
                        Lich.log "Invalid \a stripped out: #{$_SERVERSTRING_.inspect}"
                        retry
                      end
                      # Fixes invalid XML with nested single quotes in it such as:
                      # From DR intro tips
                      # <link id='2' value='Ever wondered about the time you've spent in Elanthia?  Check the PLAYED verb!' cmd='played' echo='played' />
                      # From GS
                      # <d cmd='forage Imaera's Lace'>Imaera's Lace</d>, <d cmd='forage stalk burdock'>stalk of burdock</d>
                      unless (matches = $_SERVERSTRING_.scan(/'([^=>]*'[^=>]*)'/)).empty?
                        Lich.log "Invalid nested single quotes XML tags detected: #{$_SERVERSTRING_.inspect}"
                        matches.flatten.each do |match|
                          $_SERVERSTRING_.gsub!(match, match.gsub(/'/, '&apos;'))
                        end
                        Lich.log "Invalid nested single quotes XML tags fixed to: #{$_SERVERSTRING_.inspect}"
                        retry
                      end
                      # Fixes invalid XML with nested double quotes in it such as:
                      # <subtitle=" - [Avlea's Bows, "The Straight and Arrow"]">
                      unless (matches = $_SERVERSTRING_.scan(/"([^=]*"[^=]*)"/)).empty?
                        Lich.log "Invalid nested double quotes XML tags detected: #{$_SERVERSTRING_.inspect}"
                        matches.flatten.each do |match|
                          $_SERVERSTRING_.gsub!(match, match.gsub(/"/, '&quot;'))
                        end
                        Lich.log "Invalid nested double quotes XML tags fixed to: #{$_SERVERSTRING_.inspect}"
                        retry
                      end
                      $stdout.puts "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
                      Lich.log "Invalid XML detected - please report this: #{$_SERVERSTRING_.inspect}"
                      Lich.log "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
                    end
                    XMLData.reset
                  end
                  if Module.const_defined?(:GameLoader)
                    infomon_serverstring = $_SERVERSTRING_.dup
                    if XMLData.game =~ /^GS/
                      Infomon::XMLParser.parse(infomon_serverstring)
                      stripped_infomon_serverstring = strip_xml(infomon_serverstring, type: 'infomon')
                      stripped_infomon_serverstring.split("\r\n").each { |line|
                        unless line.empty?
                          Infomon::Parser.parse(line)
                        end
                      }
                    elsif XMLData.game =~ /^DR/
                      DRParser.parse(infomon_serverstring)
                    end
                  end
                  Script.new_downstream_xml($_SERVERSTRING_)
                  stripped_server = strip_xml($_SERVERSTRING_, type: 'main')
                  stripped_server.split("\r\n").each { |line|
                    @@buffer.update(line) if TESTING
                    Script.new_downstream(line) if !line.empty?
                  }
                end
                if (alt_string = DownstreamHook.run($_SERVERSTRING_))
                  #                           Buffer.update(alt_string, Buffer::DOWNSTREAM_MOD)
                  if alt_string =~ /^(?:<resource picture="\d+"\/>|<popBold\/>)?<style id="roomName"\s+\/>/
                    if (Lich.display_lichid == true || Lich.display_uid == true)
                      if XMLData.game =~ /^GS/
                        if (Lich.display_lichid == true && Lich.display_uid == true)
                          alt_string.sub!(/] \(\d+\)/) { "]" }
                          alt_string.sub!(']') { " - #{Map.current.id}] (u#{(XMLData.room_id == 0 || XMLData.room_id > 4294967296) ? "nknown" : XMLData.room_id})" }
                        elsif Lich.display_lichid == true
                          alt_string.sub!(']') { " - #{Map.current.id}]" }
                        elsif Lich.display_uid == true
                          alt_string.sub!(/] \(\d+\)/) { "]" }
                          alt_string.sub!(']') { "] (u#{(XMLData.room_id == 0 || XMLData.room_id > 4294967296) ? "nknown" : XMLData.room_id})" }
                        end
                      elsif XMLData.game =~ /^DR/
                        if Lich.display_uid == true
                          alt_string.sub!(/] \((?:\d+|\*\*)\)/) { "]" }
                        elsif Lich.hide_uid_flag == true
                          alt_string.sub!(/] \((?:\d+|\*\*)\)/) { "]" }
                        end
                      end
                    end
                    @@room_number_after_ready = true
                  end
                  if $frontend =~ /genie/i && alt_string =~ /^<streamWindow id='room' title='Room' subtitle=" - \[.*\] \((?:\d+|\*\*)\)"/
                    alt_string.sub!(/] \((?:\d+|\*\*)\)/) { "]" }
                  end
                  if @@room_number_after_ready && alt_string =~ /<prompt /
                    if Lich.display_stringprocs == true
                      room_exits = []
                      Map.current.wayto.each do |key, value|
                        # Don't include cardinals / up/down/out (usually just climb/go)
                        if value.class == Proc
                          if Map.current.timeto[key].is_a?(Numeric) || (Map.current.timeto[key].is_a?(StringProc) && Map.current.timeto[key].call.is_a?(Numeric))
                            room_exits << "<d cmd=';go2 #{key}'>#{Map[key].title.first.gsub(/\[|\]/, '')}#{Lich.display_lichid ? ('(' + Map[key].id.to_s + ')') : ''}</d>"
                          end
                        end
                      end
                      alt_string = "StringProcs: #{room_exits.join(', ')}\r\n#{alt_string}" unless room_exits.empty?
                    end
                    if Lich.display_exits == true
                      room_exits = []
                      Map.current.wayto.each do |_key, value|
                        # Don't include cardinals / up/down/out (usually just climb/go)
                        next if value.to_s =~ /^(?:o|d|u|n|ne|e|se|s|sw|w|nw|out|down|up|north|northeast|east|southeast|south|southwest|west|northwest)$/
                        if value.class != Proc
                          room_exits << "<d cmd='#{value.dump[1..-2]}'>#{value.dump[1..-2]}</d>"
                        end
                      end
                      unless room_exits.empty?
                        alt_string = "Room Exits: #{room_exits.join(', ')}\r\n#{alt_string}"
                        if XMLData.game =~ /^GS/ && ['wrayth', 'stormfront'].include?($frontend) && Map.current.id != @@last_id_shown_room_window
                          alt_string = "#{alt_string}<pushStream id='room' ifClosedStyle='watching'/>Room Exits: #{room_exits.join(', ')}\r\n<popStream/>\r\n"
                          @@last_id_shown_room_window = Map.current.id
                        end
                      end
                    end
                    if XMLData.game =~ /^DR/
                      room_number = ""
                      room_number += "#{Map.current.id}" if Lich.display_lichid
                      room_number += " - " if Lich.display_lichid && Lich.display_uid
                      room_number += "(#{XMLData.room_id == 0 ? "**" : "u#{XMLData.room_id}"})" if Lich.display_uid
                      unless room_number.empty?
                        alt_string = "Room Number: #{room_number}\r\n#{alt_string}"
                        if ['wrayth', 'stormfront'].include?($frontend)
                          alt_string = "<streamWindow id='main' title='Story' subtitle=\" - [#{XMLData.room_title[2..-3]} - #{room_number}]\" location='center' target='drop'/>\r\n#{alt_string}"
                          alt_string = "<streamWindow id='room' title='Room' subtitle=\" - [#{XMLData.room_title[2..-3]} - #{room_number}]\" location='center' target='drop' ifClosed='' resident='true'/>#{alt_string}"
                        end
                      end
                    end
                    @@room_number_after_ready = false
                  end
                  if $frontend =~ /^(?:wizard|avalon)$/
                    alt_string = sf_to_wiz(alt_string)
                  end
                  if $_DETACHABLE_CLIENT_
                    begin
                      $_DETACHABLE_CLIENT_.write(alt_string)
                    rescue
                      $_DETACHABLE_CLIENT_.close rescue nil
                      $_DETACHABLE_CLIENT_ = nil
                      respond "--- Lich: error: client_thread: #{$!}"
                      respond $!.backtrace.first
                      Lich.log "error: client_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
                    end
                  else
                    $_CLIENT_.write(alt_string)
                  end
                end
              rescue
                $stdout.puts "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
                Lich.log "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
              end
            end
          rescue StandardError
            Lich.log "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            $stdout.puts "error: server_thread: #{$!}\n\t#{$!.backtrace.slice(0..10).join("\n\t")}"
            sleep 0.2
            retry unless $_CLIENT_.closed? or @@socket.closed? or ($!.to_s =~ /invalid argument|A connection attempt failed|An existing connection was forcibly closed|An established connection was aborted by the software in your host machine./i)
          rescue
            Lich.log "error: server_thread: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            $stdout.puts "error: server_thread: #{$!}\n\t#{$!.backtrace..slice(0..10).join("\n\t")}"
            sleep 0.2
            retry unless $_CLIENT_.closed? or @@socket.closed? or ($!.to_s =~ /invalid argument|A connection attempt failed|An existing connection was forcibly closed|An established connection was aborted by the software in your host machine./i)
          end
        }
        @@thread.priority = 4
        $_SERVER_ = @@socket # deprecated
      end

      # Returns the current thread associated with the Game.
      #
      # @return [Thread] the current thread.
      def Game.thread
        @@thread
      end

      # Checks if the socket is closed.
      #
      # @return [Boolean] true if the socket is nil or closed, false otherwise.
      def Game.closed?
        if @@socket.nil?
          true
        else
          @@socket.closed?
        end
      end

      # Closes the socket and kills the associated thread if they exist.
      #
      # @return [nil] returns nothing.
      # @raise [StandardError] if there is an error while closing the socket or killing the thread.
      def Game.close
        if @@socket
          @@socket.close rescue nil
          @@thread.kill rescue nil
        end
      end

      # Sends a string to the socket in a thread-safe manner.
      #
      # @param str [String] the string to be sent to the socket.
      # @return [nil] returns nothing.
      # @note This method uses a mutex to ensure thread safety.
      def Game._puts(str)
        @@mutex.synchronize {
          @@socket.puts(str)
        }
      end

      # Sends a formatted string to the client and logs it.
      #
      # @param str [String] the string to be sent to the client.
      # @return [nil] returns nothing.
      # @example
      #   Game.puts("Hello, World!")
      # @note This method also updates the last upstream message.
      def Game.puts(str)
        $_SCRIPTIDLETIMESTAMP_ = Time.now
        if (script = Script.current)
          script_name = script.name
        else
          script_name = '(unknown script)'
        end
        $_CLIENTBUFFER_.push "[#{script_name}]#{$SEND_CHARACTER}#{$cmd_prefix}#{str}\r\n"
        if script.nil? or not script.silent
          respond "[#{script_name}]#{$SEND_CHARACTER}#{str}\r\n"
        end
        Game._puts "#{$cmd_prefix}#{str}"
        $_LASTUPSTREAM_ = "[#{script_name}]#{$SEND_CHARACTER}#{str}"
      end

      # Reads a line from the buffer.
      #
      # @return [String, nil] the line read from the buffer or nil if the buffer is empty.
      def Game.gets
        @@buffer.gets
      end

      # Returns the current buffer.
      #
      # @return [Buffer] the current buffer.
      def Game.buffer
        @@buffer
      end

      # Reads a line from the internal buffer.
      #
      # @return [String, nil] the line read from the internal buffer or nil if the buffer is empty.
      def Game._gets
        @@_buffer.gets
      end

      # Returns the internal buffer.
      #
      # @return [Buffer] the internal buffer.
      def Game._buffer
        @@_buffer
      end
    end
  end
end