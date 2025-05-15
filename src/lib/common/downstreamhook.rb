# Module containing core Lich functionality
# @author Lich5 Documentation Generator
module Lich

  # Common functionality shared across Lich systems
  module Common

    # Manages downstream hooks that can modify server output before it reaches the client
    # Hooks are stored as Proc objects that can transform text streams
    #
    # @author Lich5 Documentation Generator
    class DownstreamHook
      # @!attribute [r] downstream_hooks
      #   @return [Hash] internal storage of hook name to Proc mappings
      #   @api private
      @@downstream_hooks ||= Hash.new

      # @!attribute [r] downstream_hook_sources
      #   @return [Hash] internal storage of hook name to source script mappings
      #   @api private
      @@downstream_hook_sources ||= Hash.new

      # Adds a new downstream hook to process server output
      #
      # @param name [Symbol, String] unique identifier for this hook
      # @param action [Proc] the code block that will process the server string
      # @return [Boolean] false if action is not a Proc, true if hook was added successfully
      # @raise [TypeError] if action is not a Proc
      # @example
      #   DownstreamHook.add(:my_hook, proc { |server_string| server_string.upcase })
      #
      # @note The hook source is automatically tracked using the current script name
      def DownstreamHook.add(name, action)
        unless action.class == Proc
          echo "DownstreamHook: not a Proc (#{action})"
          return false
        end
        @@downstream_hook_sources[name] = (Script.current.name || "Unknown")
        @@downstream_hooks[name] = action
      end

      # Processes server output through all registered hooks
      #
      # @param server_string [String] the original text from the server
      # @return [String, nil] the processed string after running through all hooks, or nil if input becomes nil
      # @raise [StandardError] if any hook raises an error (hook will be removed)
      # @example
      #   result = DownstreamHook.run("You see a goblin.")
      #
      # @note Hooks are processed in order. If any hook returns nil, processing stops
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

      # Removes a hook from the system
      #
      # @param name [Symbol, String] identifier of the hook to remove
      # @return [void]
      # @example
      #   DownstreamHook.remove(:my_hook)
      def DownstreamHook.remove(name)
        @@downstream_hook_sources.delete(name)
        @@downstream_hooks.delete(name)
      end

      # Lists all registered hook names
      #
      # @return [Array<Symbol, String>] array of hook identifiers
      # @example
      #   hooks = DownstreamHook.list
      #   puts "Active hooks: #{hooks.join(', ')}"
      def DownstreamHook.list
        @@downstream_hooks.keys.dup
      end

      # Displays a formatted table of hooks and their sources
      #
      # @return [void]
      # @example
      #   DownstreamHook.sources
      #
      # @note Requires the terminal-table gem for formatting
      def DownstreamHook.sources
        info_table = Terminal::Table.new :headings => ['Hook', 'Source'],
                                         :rows     => @@downstream_hook_sources.to_a,
                                         :style    => { :all_separators => true }
        Lich::Messaging.mono(info_table.to_s)
      end

      # Returns the raw mapping of hooks to their source scripts
      #
      # @return [Hash] mapping of hook names to source script names
      # @example
      #   sources = DownstreamHook.hook_sources
      #   puts "My hook came from: #{sources[:my_hook]}"
      def DownstreamHook.hook_sources
        @@downstream_hook_sources
      end
    end
  end
end