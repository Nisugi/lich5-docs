require 'tempfile'
require 'json'
require 'fileutils'

# Provides frontend session management functionality for the Lich game client
# 
# @author Lich5 Documentation Generator
module Lich

  # Common utilities and shared functionality
  module Common

    # Handles creation and management of game session files
    #
    # This module provides functionality to create, manage and cleanup temporary session files
    # that store connection information for game sessions.
    module Frontend
      @session_file = nil
      @tmp_session_dir = File.join Dir.tmpdir, "simutronics", "sessions"

      # Creates a session file containing connection information for a game session
      #
      # @param name [String] The name of the session/character
      # @param host [String] The hostname or IP address of the game server
      # @param port [Integer] The port number to connect to
      # @param display_session [Boolean] Whether to print session details to stdout (defaults to true)
      # @return [nil] Returns nil if name is nil, otherwise creates the session file
      # @raise [SystemCallError] If unable to create directory or write file
      # @example
      #   Lich::Common::Frontend.create_session_file("MyCharacter", "game.example.com", 4901)
      #   # Creates a session file: /tmp/simutronics/sessions/Mycharacter.session
      #   # With contents: {"name":"MyCharacter","host":"game.example.com","port":4901}
      #
      # @note Session files are stored in a temporary directory and contain JSON-formatted connection details
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

      # Returns the full path to the current session file
      #
      # @return [String, nil] Path to the current session file, or nil if no session file exists
      # @example
      #   path = Lich::Common::Frontend.session_file_location
      #   # Returns something like "/tmp/simutronics/sessions/Mycharacter.session"
      def self.session_file_location
        @session_file
      end

      # Removes the current session file if it exists
      #
      # @return [nil]
      # @example
      #   Lich::Common::Frontend.cleanup_session_file
      #   # Deletes the session file if it exists
      #
      # @note Safe to call even if no session file exists - will simply return nil
      def self.cleanup_session_file
        return if @session_file.nil?
        File.delete(@session_file) if File.exist? @session_file
      end
    end
  end
end