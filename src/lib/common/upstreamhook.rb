# Carve out from lich.rbw
# UpstreamHook class 2024-06-13

module Lich
  module Common
    # A class that manages upstream hooks for processing client strings.
    class UpstreamHook
      @@upstream_hooks ||= Hash.new
      @@upstream_hook_sources ||= Hash.new

      # Adds a new upstream hook with a given name and action.
      #
      # @param name [String] the name of the hook
      # @param action [Proc] the action to be executed when the hook is triggered
      # @return [Boolean] returns false if action is not a Proc, otherwise returns nil
      # @raise [StandardError] raises an error if action is not a Proc
      # @example
      #   UpstreamHook.add("example_hook", Proc.new { |client| client.upcase })
      def UpstreamHook.add(name, action)
        unless action.class == Proc
          echo "UpstreamHook: not a Proc (#{action})"
          return false
        end
        @@upstream_hook_sources[name] = (Script.current.name || "Unknown")
        @@upstream_hooks[name] = action
      end

      # Runs all registered upstream hooks in order, passing the client string through each.
      #
      # @param client_string [String] the client string to be processed
      # @return [String, nil] the processed client string or nil if any hook returns nil
      # @raise [StandardError] raises an error if any hook fails during execution
      # @example
      #   processed_string = UpstreamHook.run("input string")
      def UpstreamHook.run(client_string)
        for key in @@upstream_hooks.keys
          begin
            client_string = @@upstream_hooks[key].call(client_string)
          rescue
            @@upstream_hooks.delete(key)
            respond "--- Lich: UpstreamHook: #{$!}"
            respond $!.backtrace.first
          end
          return nil if client_string.nil?
        end
        return client_string
      end

      # Removes an upstream hook by its name.
      #
      # @param name [String] the name of the hook to be removed
      # @return [nil] returns nil
      # @example
      #   UpstreamHook.remove("example_hook")
      def UpstreamHook.remove(name)
        @@upstream_hook_sources.delete(name)
        @@upstream_hooks.delete(name)
      end

      # Lists all registered upstream hooks.
      #
      # @return [Array<String>] an array of hook names
      # @example
      #   hooks = UpstreamHook.list
      def UpstreamHook.list
        @@upstream_hooks.keys.dup
      end

      # Displays the sources of all registered upstream hooks in a table format.
      #
      # @return [nil] returns nil
      # @example
      #   UpstreamHook.sources
      def UpstreamHook.sources
        info_table = Terminal::Table.new :headings => ['Hook', 'Source'],
                                         :rows     => @@upstream_hook_sources.to_a,
                                         :style    => { :all_separators => true }
        Lich::Messaging.mono(info_table.to_s)
      end

      # Returns a hash of upstream hook sources.
      #
      # @return [Hash<String, String>] a hash mapping hook names to their sources
      # @example
      #   sources = UpstreamHook.hook_sources
      def UpstreamHook.hook_sources
        @@upstream_hook_sources
      end
    end
  end
end
