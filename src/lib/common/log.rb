# Provides contextual logging functionality for the Lich system
# @author Lich5 Documentation Generator
module Lich
  module Common
    module Log
      @@log_enabled = nil
      @@log_filter  = nil

      # Enables logging with an optional filter pattern
      #
      # @param filter [Regexp] Regular expression pattern to filter log messages (default: //)
      # @return [nil]
      # @raise [SQLite3::BusyException] When database is locked, will retry automatically
      # @example Enable all logging
      #   Lich::Common::Log.on
      # @example Enable logging with filter
      #   Lich::Common::Log.on(/combat/)
      #
      # @note Persists the logging state to the database
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

      # Disables logging functionality
      #
      # @return [nil]
      # @raise [SQLite3::BusyException] When database is locked, will retry automatically
      # @example
      #   Lich::Common::Log.off
      #
      # @note Resets filter to default and persists state to database
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

      # Checks if logging is currently enabled
      #
      # @return [Boolean] true if logging is enabled, false otherwise
      # @raise [SQLite3::BusyException] When database is locked, will retry automatically
      # @example
      #   if Lich::Common::Log.on?
      #     # perform logging
      #   end
      #
      # @note Lazy loads setting from database on first access
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

      # Retrieves the current log filter pattern
      #
      # @return [Regexp] Current filter regular expression
      # @raise [SQLite3::BusyException] When database is locked, will retry automatically
      # @example
      #   current_filter = Lich::Common::Log.filter
      #
      # @note Lazy loads filter from database on first access
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

      # Outputs a message to the log if logging is enabled and message matches filter
      #
      # @param msg [Object, Exception] Message or exception to log
      # @param label [Symbol] Label to categorize the log message (default: :debug)
      # @return [void]
      # @example Log a message
      #   Log.out("Player entered combat", label: :combat)
      # @example Log an exception
      #   begin
      #     # some code
      #   rescue => e
      #     Log.out(e)
      #   end
      #
      # @note For exceptions, includes message and first 6 stack frames
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

      # Internal method for writing log lines
      #
      # @param line [String] The formatted log line to write
      # @return [void]
      # @private
      def self._write(line)
        if Script.current.vars.include?("--headless") or not defined?(:_respond)
          $stdout.write(line + "\n")
        elsif line.include?("<") and line.include?(">")
          respond(line)
        else
          _respond Preset.as(:debug, line)
        end
      end

      # Internal method for formatting log messages
      #
      # @param msg [Object] Message to format
      # @param label [Symbol] Category label
      # @return [String] Formatted log line
      # @private
      def self._view(msg, label)
        label = [Script.current.name, label].flatten.compact.join(".")
        safe = msg.inspect
        # safe = safe.gsub("<", "&lt;").gsub(">", "&gt;") if safe.include?("<") and safe.include?(">")
        "[#{label}] #{safe}"
      end

      # Pretty prints a message to the log with formatting
      #
      # @param msg [Object] Message to print
      # @param label [Symbol] Category label for the message (default: :debug)
      # @return [void]
      # @example
      #   Log.pp({ status: "ready" }, :system)
      #
      # @note Alias method for debugging/inspection purposes
      def self.pp(msg, label = :debug)
        respond _view(msg, label)
      end

      # Alias for pp method
      #
      # @param args [Array] Arguments to pass to pp
      # @return [void]
      # @example
      #   Log.dump(complex_object)
      #
      # @note Convenience method for debugging
      def self.dump(*args)
        pp(*args)
      end

      # Nested module for handling preset formatting
      module Preset
        # Wraps content in XML-style preset tags
        #
        # @param kind [Symbol] The preset identifier
        # @param body [String] Content to wrap in preset tags
        # @return [String] Formatted preset string
        # @example
        #   Preset.as(:error, "Invalid input")
        #   # => "<preset id="error">Invalid input</preset>"
        def self.as(kind, body)
          %[<preset id="#{kind}">#{body}</preset>]
        end
      end
    end
  end
end