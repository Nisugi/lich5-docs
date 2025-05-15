# A module containing common Lich functionality
# @author Lich5 Documentation Generator
module Lich

  # Common utilities and helper classes
  module Common

    # Watches for specific text patterns in the game stream and executes callbacks when matched
    # @author Lich5 Documentation Generator
    class Watchfor
      # Creates a new text pattern watcher that executes a callback when matched
      #
      # @param line [String, Regexp] The text pattern to watch for - can be a string (exact match) or regexp
      # @param theproc [Proc, nil] Optional proc to use as the callback
      # @param block [Proc] Block to execute when pattern matches (alternative to theproc)
      # @return [nil] Returns nil if initialization fails
      # @raise [RuntimeError] When no valid callback (proc or block) is provided
      # @raise [RuntimeError] When line parameter is neither String nor Regexp
      #
      # @example Watch for exact text match
      #   Watchfor.new("You see a dragon") { |line| echo "Dragon spotted!" }
      #
      # @example Watch with regexp
      #   Watchfor.new(/dragon/i) { |line| echo "Dragon mentioned!" }
      #
      # @example Using a proc
      #   my_proc = Proc.new { |line| echo "Match found!" }
      #   Watchfor.new("pattern", my_proc)
      #
      # @note Requires a current script context to function
      # @note String patterns are automatically escaped and converted to Regexp
      # rubocop:disable Lint/ReturnInVoidContext
      def initialize(line, theproc = nil, &block)
        return nil unless (script = Script.current)

        if line.class == String
          line = Regexp.new(Regexp.escape(line))
        elsif line.class != Regexp
          echo 'watchfor: no string or regexp given'
          return nil
        end
        if block.nil?
          if theproc.respond_to? :call
            block = theproc
          else
            echo 'watchfor: no block or proc given'
            return nil
          end
        end
        script.watchfor[line] = block
      end

      # rubocop:enable Lint/ReturnInVoidContext

      # Removes all registered watch patterns for the current script
      #
      # @return [Hash] Returns empty hash representing cleared watchfor patterns
      #
      # @example Clear all watchers
      #   Watchfor.clear
      #
      # @note Only affects watchers for the current script context
      def Watchfor.clear
        script.watchfor = Hash.new
      end
    end
  end
end