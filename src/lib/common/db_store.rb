# frozen_string_literal: true

# Recreating / bridging the design for CharSettings to lift in scripts into lib
# as with infomon rewrite
# Also tuning slightly, to improve / reduce db calls made by CharSettings
# 20240801 - updated to include vars (uservars) settings to support renaming characters

require 'English'

module Lich
  module Common
    # A database storage module for managing script settings and user variables in Lich5.
    # Provides functionality to read and write persistent data scoped by game and character.
    #
    # @author Lich5 Documentation Generator
    module DB_Store
      # Reads stored data for a given scope and script.
      #
      # @param scope [String] The storage scope, defaults to "game:character_name"
      # @param script [String] The script name or 'vars'/'uservars' for user variables
      # @return [Hash] The stored data for the given scope and script
      # @example Reading script settings
      #   DB_Store.read("GemStone:MyCharacter", "script_name")
      # @example Reading user variables
      #   DB_Store.read("GemStone:MyCharacter", "vars")
      #
      # @note Returns an empty hash if no data is found
      def self.read(scope = "#{XMLData.game}:#{XMLData.name}", script)
        case script
        when 'vars', 'uservars'
          get_vars(scope)
        else
          get_data(scope, script)
        end
      end

      # Saves data for a given scope and script.
      #
      # @param scope [String] The storage scope, defaults to "game:character_name"
      # @param script [String] The script name or 'vars'/'uservars' for user variables
      # @param val [Hash] The data to store
      # @return [nil, String] Returns error message string if storage fails
      # @raise [StandardError] Database errors during storage
      # @example Saving script settings
      #   DB_Store.save("GemStone:MyCharacter", "script_name", {setting: "value"})
      # @example Saving user variables
      #   DB_Store.save("GemStone:MyCharacter", "vars", {var: "value"})
      def self.save(scope = "#{XMLData.game}:#{XMLData.name}", script, val)
        case script
        when 'vars', 'uservars'
          store_vars(scope, val)
        else
          store_data(scope, script, val)
        end
      end

      # Retrieves script-specific data from the database.
      #
      # @param scope [String] The storage scope, defaults to "game:character_name"
      # @param script [String] The script name
      # @return [Hash] The stored data for the script
      # @example
      #   DB_Store.get_data("GemStone:MyCharacter", "script_name")
      #
      # @note Returns an empty hash if no data is found
      # @note Data is stored and retrieved using Marshal serialization
      def self.get_data(scope = "#{XMLData.game}:#{XMLData.name}", script)
        hash = Lich.db.get_first_value('SELECT hash FROM script_auto_settings WHERE script=? AND scope=?;', [script.encode('UTF-8'), scope.encode('UTF-8')])
        return {} unless hash
        Marshal.load(hash)
      end

      # Retrieves user variables from the database.
      #
      # @param scope [String] The storage scope, defaults to "game:character_name"
      # @return [Hash] The stored user variables
      # @example
      #   DB_Store.get_vars("GemStone:MyCharacter")
      #
      # @note Returns an empty hash if no variables are found
      # @note Data is stored and retrieved using Marshal serialization
      def self.get_vars(scope = "#{XMLData.game}:#{XMLData.name}")
        hash = Lich.db.get_first_value('SELECT hash FROM uservars WHERE scope=?;', scope.encode('UTF-8'))
        return {} unless hash
        Marshal.load(hash)
      end

      # Stores script-specific data in the database.
      #
      # @param scope [String] The storage scope, defaults to "game:character_name"
      # @param script [String] The script name
      # @param val [Hash] The data to store
      # @return [nil, String] Returns error message if storage fails
      # @raise [SQLite3::BusyException] When database is locked (automatically retries)
      # @raise [StandardError] Other database errors
      # @example
      #   DB_Store.store_data("GemStone:MyCharacter", "script_name", {setting: "value"})
      #
      # @note Uses database mutex to ensure thread safety
      # @note Automatically retries on busy database
      # @note Data is encoded as UTF-8 and serialized using Marshal
      def self.store_data(scope = "#{XMLData.game}:#{XMLData.name}", script, val)
        blob = SQLite3::Blob.new(Marshal.dump(val))
        return 'Error: No data to store.' unless blob

        Lich.db_mutex.synchronize do
          begin
            Lich.db.execute('INSERT OR REPLACE INTO script_auto_settings(script,scope,hash) VALUES(?,?,?);', [script.encode('UTF-8'), scope.encode('UTF-8'), blob])
          rescue SQLite3::BusyException
            sleep 0.05
            retry
          rescue StandardError
            respond "--- Lich: error: #{$ERROR_INFO}"
            respond $ERROR_INFO.backtrace[0..1]
          end
        end
      end

      # Stores user variables in the database.
      #
      # @param scope [String] The storage scope, defaults to "game:character_name"
      # @param val [Hash] The variables to store
      # @return [nil, String] Returns error message if storage fails
      # @raise [SQLite3::BusyException] When database is locked (automatically retries)
      # @raise [StandardError] Other database errors
      # @example
      #   DB_Store.store_vars("GemStone:MyCharacter", {var: "value"})
      #
      # @note Uses database mutex to ensure thread safety
      # @note Automatically retries on busy database
      # @note Data is encoded as UTF-8 and serialized using Marshal
      def self.store_vars(scope = "#{XMLData.game}:#{XMLData.name}", val)
        blob = SQLite3::Blob.new(Marshal.dump(val))
        return 'Error: No data to store.' unless blob

        Lich.db_mutex.synchronize do
          begin
            Lich.db.execute('INSERT OR REPLACE INTO uservars(scope,hash) VALUES(?,?);', [scope.encode('UTF-8'), blob])
          rescue SQLite3::BusyException
            sleep 0.05
            retry
          rescue StandardError
            respond "--- Lich: error: #{$ERROR_INFO}"
            respond $ERROR_INFO.backtrace[0..1]
          end
        end
      end
    end
  end
end