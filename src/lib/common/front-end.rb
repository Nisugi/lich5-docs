require 'tempfile'
require 'json'
require 'fileutils'

module Lich
  module Common
    module Frontend
      @session_file = nil
      @tmp_session_dir = File.join Dir.tmpdir, "simutronics", "sessions"

      # Creates a session file with the given name, host, and port.
      #
      # @param name [String] the name of the session
      # @param host [String] the host for the session
      # @param port [Integer] the port for the session
      # @param display_session [Boolean] whether to display the session descriptor (default: true)
      # @return [nil] returns nothing
      # @raise [Errno::EACCES] if the session file cannot be created due to permission issues
      # @raise [JSON::GeneratorError] if there is an error generating the JSON for the session descriptor
      # @example
      #   Lich::Common::Frontend.create_session_file("MySession", "localhost", 8080)
      def self.create_session_file(name, host, port, display_session: true)
        return if name.nil?
        FileUtils.mkdir_p @tmp_session_dir
        @session_file = File.join(@tmp_session_dir, "%s.session" % name.downcase.capitalize)
        session_descriptor = { name: name, host: host, port: port }.to_json
        puts "writing session descriptor to %s\n%s" % [@session_file, session_descriptor] if display_session
        File.open(@session_file, "w") do |fd|
          fd << session_descriptor
        end
      end

      # Returns the location of the current session file.
      #
      # @return [String, nil] the path to the session file or nil if not set
      # @example
      #   location = Lich::Common::Frontend.session_file_location
      def self.session_file_location
        @session_file
      end

      # Cleans up (deletes) the current session file if it exists.
      #
      # @return [nil] returns nothing
      # @note This method will do nothing if there is no session file set.
      # @example
      #   Lich::Common::Frontend.cleanup_session_file
      def self.cleanup_session_file
        return if @session_file.nil?
        File.delete(@session_file) if File.exist? @session_file
      end
    end
  end
end
