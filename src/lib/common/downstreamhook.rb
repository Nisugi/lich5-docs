# Carve out from lich.rbw
# class DownstreamHook 2024-06-13

module Lich
  module Common
    # A class that manages downstream hooks for processing strings.
    class DownstreamHook
      @@downstream_hooks ||= Hash.new
      @@downstream_hook_sources ||= Hash.new

      # Adds a new downstream hook with a given name and action.
      #
      # @param name [String] the name of the hook
      # @param action [Proc] the action to be executed when the hook is triggered
      # @return [Boolean] returns false if the action is not a Proc, otherwise returns nil
      # @example
      #   DownstreamHook.add("example_hook", Proc.new { |str| str.upcase })
      def DownstreamHook.add(name, action)
        unless action.class == Proc
          echo "DownstreamHook: not a Proc (#{action})"
          return false
        end
        @@downstream_hook_sources[name] = (Script.current.name || "Unknown")
        @@downstream_hooks[name] = action
      end

      # Runs all registered downstream hooks on the provided server string.
      #
      # @param server_string [String] the string to be processed by the hooks
      # @return [String, nil] the processed string or nil if the input is nil
      # @raise [StandardError] if an error occurs during the execution of a hook
      # @example
      #   processed_string = DownstreamHook.run("example string")
      def DownstreamHook.run(server_string)
        for key in @@downstream_hooks.keys
          return nil if server_string.nil?
          begin
            server_string = @@downstream_hooks[key].call(server_string.dup) if server_string.is_a?(String)
          rescue
            @@downstream_hooks.delete(key)
            respond "--- Lich: DownstreamHook: #{$!}"
            respond $!.backtrace.first
          end
        end
        return server_string
      end

      # Removes a downstream hook by its name.
      #
      # @param name [String] the name of the hook to be removed
      # @return [nil] returns nil
      # @example
      #   DownstreamHook.remove("example_hook")
      def DownstreamHook.remove(name)
        @@downstream_hook_sources.delete(name)
        @@downstream_hooks.delete(name)
      end

      # Lists all registered downstream hooks.
      #
      # @return [Array<String>] an array of hook names
      # @example
      #   hooks = DownstreamHook.list
      def DownstreamHook.list
        @@downstream_hooks.keys.dup
      end

      # Displays the sources of all registered downstream hooks in a table format.
      #
      # @return [String] a formatted string representation of the hook sources
      # @example
      #   DownstreamHook.sources
      def DownstreamHook.sources
        info_table = Terminal::Table.new :headings => ['Hook', 'Source'],
                                         :rows     => @@downstream_hook_sources.to_a,
                                         :style    => { :all_separators => true }
        Lich::Messaging.mono(info_table.to_s)
      end

      # Retrieves the sources of all registered downstream hooks.
      #
      # @return [Hash] a hash mapping hook names to their sources
      # @example
      #   sources = DownstreamHook.hook_sources
      def DownstreamHook.hook_sources
        @@downstream_hook_sources
      end
    end
  end
end
