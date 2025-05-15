# Module containing core Lich functionality
module Lich
  # Module containing common utilities and shared functionality 
  module Common
    # Database adapter class that handles persistence of script settings using SQLite
    # through the Sequel gem. Provides a simple interface for storing and retrieving
    # script-specific settings with scope support.
    #
    # @author Lich5 Documentation Generator
    class DatabaseAdapter
      # Initializes a new database adapter instance
      #
      # @param data_dir [String] Directory path where the SQLite database file will be stored
      # @param table_name [String] Name of the table to store settings in
      # @return [DatabaseAdapter] New database adapter instance
      # @example
      #   adapter = DatabaseAdapter.new("/path/to/data", "settings")
      #
      # @note Creates a new SQLite database file if it doesn't exist
      def initialize(data_dir, table_name)
        @file = File.join(data_dir, "lich.db3")
        @db = Sequel.sqlite(@file)
        @table_name = table_name
        setup!
      end

      # Sets up the database table structure
      #
      # @return [void]
      # @note Creates the table if it doesn't exist with columns: script (text), scope (text), hash (blob)
      # @example
      #   adapter.setup!
      def setup!
        @db.create_table?(@table_name) do
          text :script
          text :scope
          blob :hash
        end
        @table = @db[@table_name]
      end

      # Returns the database table object
      #
      # @return [Sequel::Dataset] The database table object for direct access
      # @example
      #   table = adapter.table
      def table
        @table
      end

      # Retrieves settings for a specific script and scope
      #
      # @param script_name [String] Name of the script whose settings to retrieve
      # @param scope [String] Settings scope identifier (defaults to ":")
      # @return [Hash] Hash containing the script's settings, empty hash if no settings exist
      # @example
      #   settings = adapter.get_settings("my_script")
      #   settings = adapter.get_settings("my_script", "custom_scope")
      #
      # @note Uses Marshal to deserialize stored settings
      def get_settings(script_name, scope = ":")
        entry = @table.first(script: script_name, scope: scope)
        entry.nil? ? {} : Marshal.load(entry[:hash])
      end

      # Saves settings for a specific script and scope
      #
      # @param script_name [String] Name of the script whose settings to save
      # @param settings [Hash] Hash containing the settings to save
      # @param scope [String] Settings scope identifier (defaults to ":")
      # @return [void]
      # @example
      #   adapter.save_settings("my_script", {setting1: "value1"})
      #   adapter.save_settings("my_script", {setting1: "value1"}, "custom_scope")
      #
      # @note Uses Marshal to serialize settings
      # @note Will update existing settings if they exist, otherwise creates new entry
      # @note Uses SQLite's REPLACE conflict strategy for updates
      def save_settings(script_name, settings, scope = ":")
        blob = Sequel::SQL::Blob.new(Marshal.dump(settings))

        if @table.where(script: script_name, scope: scope).count > 0
          @table
            .where(script: script_name, scope: scope)
            .insert_conflict(:replace)
            .update(hash: blob)
        else
          @table.insert(
            script: script_name,
            scope: scope,
            hash: blob
          )
        end
      end
    end
  end
end