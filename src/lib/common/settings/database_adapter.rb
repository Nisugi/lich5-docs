module Lich
  module Common
    # Database adapter to separate database concerns
    class DatabaseAdapter
      # Initializes a new DatabaseAdapter instance.
      #
      # @param data_dir [String] the directory where the database file is located.
      # @param table_name [String] the name of the table to be used in the database.
      # @return [DatabaseAdapter] the instance of the DatabaseAdapter.
      # @raise [Sequel::DatabaseError] if there is an error connecting to the database.
      # @example
      #   adapter = Lich::Common::DatabaseAdapter.new('/path/to/data', 'settings_table')
      def initialize(data_dir, table_name)
        @file = File.join(data_dir, "lich.db3")
        @db = Sequel.sqlite(@file)
        @table_name = table_name
        setup!
      end

      # Sets up the database table if it does not already exist.
      #
      # @return [void]
      # @note This method is called during initialization.
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

      # Returns the database table object.
      #
      # @return [Sequel::Dataset] the dataset representing the table.
      # @example
      #   table = adapter.table
      def table
        @table
      end

      # Retrieves settings for a given script and scope.
      #
      # @param script_name [String] the name of the script for which settings are retrieved.
      # @param scope [String] the scope of the settings (default is ":").
      # @return [Hash] the settings associated with the script and scope, or an empty hash if none found.
      # @raise [Sequel::DatabaseError] if there is an error querying the database.
      # @example
      #   settings = adapter.get_settings('my_script', 'my_scope')
      def get_settings(script_name, scope = ":")
        entry = @table.first(script: script_name, scope: scope)
        entry.nil? ? {} : Marshal.load(entry[:hash])
      end

      # Saves settings for a given script and scope.
      #
      # @param script_name [String] the name of the script for which settings are saved.
      # @param settings [Hash] the settings to be saved.
      # @param scope [String] the scope of the settings (default is ":").
      # @return [void]
      # @raise [Sequel::DatabaseError] if there is an error saving to the database.
      # @example
      #   adapter.save_settings('my_script', { key: 'value' }, 'my_scope')
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
