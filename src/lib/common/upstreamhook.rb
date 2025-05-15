# The main Lich namespace containing core functionality
#
# @author Lich5 Documentation Generator
module Lich

  # Common functionality shared across the Lich system
  module Common

    # Manages upstream hooks that can modify client input before it's processed
    #
    # UpstreamHook allows scripts to intercept and modify text sent from the client
    # before it reaches the game server.
    class UpstreamHook
      # @!attribute [r] upstream_hooks
      #   @return [Hash] internal storage of hook name to Proc mappings
      @@upstream_hooks ||= Hash.new

      # @!attribute [r] upstream_hook_sources  
      #   @return [Hash] internal storage of hook name to source script mappings
      @@upstream_hook_sources ||= Hash.new

      # Adds a new upstream hook to process client input
      #
      # @param name [Symbol, String] unique identifier for this hook
      # @param action [Proc] the code block to process the client string
      # @return [Boolean] false if action is not a Proc, true if hook was added successfully
      # @raise [StandardError] if the hook execution fails
      # @example
      #   UpstreamHook.add(:my_hook, proc { |client_string| client_string.upcase })
      #
      # @note The hook source is automatically tracked using the current script name
      def UpstreamHook.add(name, action)
        unless action.class == Proc
          echo "UpstreamHook: not a Proc (#{action})"
          return false
        end
        @@upstream_hook_sources[name] = (Script.current.name || "Unknown")
        @@upstream_hooks[name] = action
      end

      # Processes client input through all registered hooks
      #
      # @param client_string [String] the original input from the client
      # @return [String, nil] the modified string after processing through all hooks, or nil if any hook returns nil
      # @raise [StandardError] if any hook raises an error (hook will be removed)
      # @example
      #   modified_string = UpstreamHook.run("look")
      #
      # @note Hooks are processed in order. If any hook returns nil, processing stops
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

      # Removes a hook from the system
      #
      # @param name [Symbol, String] the identifier of the hook to remove
      # @return [void]
      # @example
      #   UpstreamHook.remove(:my_hook)
      def UpstreamHook.remove(name)
        @@upstream_hook_sources.delete(name)
        @@upstream_hooks.delete(name)
      end

      # Lists all registered hook names
      #
      # @return [Array<Symbol, String>] array of hook identifiers
      # @example
      #   hooks = UpstreamHook.list
      #
      # @note Returns a duplicate of the internal list to prevent modification
      def UpstreamHook.list
        @@upstream_hooks.keys.dup
      end

      # Displays a formatted table of hooks and their sources
      #
      # @return [void]
      # @example
      #   UpstreamHook.sources
      #
      # @note Uses Terminal::Table for formatting and Lich::Messaging for output
      def UpstreamHook.sources
        info_table = Terminal::Table.new :headings => ['Hook', 'Source'],
                                         :rows     => @@upstream_hook_sources.to_a,
                                         :style    => { :all_separators => true }
        Lich::Messaging.mono(info_table.to_s)
      end

      # Returns the raw mapping of hooks to their source scripts
      #
      # @return [Hash] mapping of hook names to source script names
      # @example
      #   sources = UpstreamHook.hook_sources
      #
      # @note Primarily used for debugging and inspection purposes
      def UpstreamHook.hook_sources
        @@upstream_hook_sources
      end
    end
  end
end