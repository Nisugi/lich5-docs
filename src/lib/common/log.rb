##
## contextual logging
##

module Lich
  module Common
    module Log
      @@log_enabled = nil
      @@log_filter  = nil

      ##
      # Enables logging with an optional filter.
      #
      # @param filter [Regexp] the filter to apply to log messages (default: //)
      # @return [nil] always returns nil
      # @raise [SQLite3::BusyException] if the database is busy
      # @example
      #   Log.on(/error/)
      def self.on(filter = //)
        @@log_enabled = true
        @@log_filter = filter
        begin
          Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('log_enabled',?);", [@@log_enabled.to_s.encode('UTF-8')])
          Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('log_filter',?);", [@@log_filter.to_s.encode('UTF-8')])
        rescue SQLite3::BusyException
          sleep 0.1
          retry
        end
        return nil
      end

      ##
      # Disables logging.
      #
      # @return [nil] always returns nil
      # @raise [SQLite3::BusyException] if the database is busy
      # @example
      #   Log.off
      def self.off
        @@log_enabled = false
        @@log_filter = //
        begin
          Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('log_enabled',?);", [@@log_enabled.to_s.encode('UTF-8')])
          Lich.db.execute("INSERT OR REPLACE INTO lich_settings(name,value) values('log_filter',?);", [@@log_filter.to_s.encode('UTF-8')])
        rescue SQLite3::BusyException
          sleep 0.1
          retry
        end
        return nil
      end

      ##
      # Checks if logging is enabled.
      #
      # @return [Boolean] true if logging is enabled, false otherwise
      # @raise [SQLite3::BusyException] if the database is busy
      # @example
      #   if Log.on?
      #     puts "Logging is enabled"
      #   end
      def self.on?
        if @@log_enabled.nil?
          begin
            val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='log_enabled';")
          rescue SQLite3::BusyException
            sleep 0.1
            retry
          end
          val = false if val.nil?
          @@log_enabled = (val.to_s =~ /on|true|yes/ ? true : false) if !val.nil?
        end
        return @@log_enabled
      end

      ##
      # Retrieves the current log filter.
      #
      # @return [Regexp] the current log filter
      # @raise [SQLite3::BusyException] if the database is busy
      # @example
      #   filter = Log.filter
      def self.filter
        if @@log_filter.nil?
          begin
            val = Lich.db.get_first_value("SELECT value FROM lich_settings WHERE name='log_filter';")
          rescue SQLite3::BusyException
            sleep 0.1
            retry
          end
          val = // if val.nil?
          @@log_filter = Regexp.new(val)
        end
        return @@log_filter
      end

      ##
      # Outputs a log message if logging is enabled and the message matches the filter.
      #
      # @param msg [String, Exception] the message to log
      # @param label [Symbol] the label for the log message (default: :debug)
      # @return [nil] always returns nil
      # @example
      #   Log.out("This is a debug message")
      def self.out(msg, label: :debug)
        return unless Script.current.vars.include?("--debug") || Log.on?
        return if msg.to_s !~ Log.filter
        if msg.is_a?(Exception)
          ## pretty-print exception
          _write _view(msg.message, label)
          msg.backtrace.to_a.slice(0..5).each do |frame| _write _view(frame, label) end
        else
          self._write _view(msg, label) # if Script.current.vars.include?("--debug")
        end
      end

      ##
      # Writes a line to the appropriate output based on the current environment.
      #
      # @param line [String] the line to write
      # @return [nil] always returns nil
      # @example
      #   Log._write("This is a log line")
      def self._write(line)
        if Script.current.vars.include?("--headless") or not defined?(:_respond)
          $stdout.write(line + "\n")
        elsif line.include?("<") and line.include?(">")
          respond(line)
        else
          _respond Preset.as(:debug, line)
        end
      end

      ##
      # Formats a message for logging with a label.
      #
      # @param msg [String] the message to format
      # @param label [Symbol] the label for the message
      # @return [String] the formatted log message
      # @example
      #   formatted_message = Log._view("An error occurred", :error)
      def self._view(msg, label)
        label = [Script.current.name, label].flatten.compact.join(".")
        safe = msg.inspect
        # safe = safe.gsub("<", "&lt;").gsub(">", "&gt;") if safe.include?("<") and safe.include?(">")
        "[#{label}] #{safe}"
      end

      ##
      # Responds with a formatted log message.
      #
      # @param msg [String] the message to log
      # @param label [Symbol] the label for the log message (default: :debug)
      # @return [nil] always returns nil
      # @example
      #   Log.pp("This is a pretty printed message")
      def self.pp(msg, label = :debug)
        respond _view(msg, label)
      end

      ##
      # Dumps a message to the log.
      #
      # @param args [*Object] the messages to log
      # @return [nil] always returns nil
      # @example
      #   Log.dump("Dumping this message")
      def self.dump(*args)
        pp(*args)
      end

      module Preset
        ##
        # Formats a message as a preset for logging.
        #
        # @param kind [Symbol] the kind of preset
        # @param body [String] the body of the preset
        # @return [String] the formatted preset
        # @example
        #   preset_message = Preset.as(:info, "This is an info message")
        def self.as(kind, body)
          %[<preset id="#{kind}">#{body}</preset>]
        end
      end
    end
  end
end
