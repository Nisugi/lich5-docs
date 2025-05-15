# Carve out class WatchFor
# 2024-06-13
# has rubocop Lint issues (return nil) - overriding until it can be further researched

module Lich
  module Common
    # A class that watches for specific patterns in a script and executes a block of code when a match is found.
    class Watchfor
      # Initializes a new Watchfor instance.
      #
      # @param line [String, Regexp] The string or regular expression to watch for.
      # @param theproc [Proc, nil] An optional Proc to execute when the pattern is matched.
      # @param block [Proc] A block of code to execute when the pattern is matched.
      # @return [nil] Returns nil if the script is not current, if the line is not a string or regexp, or if no block or proc is provided.
      # @raise [ArgumentError] Raises an error if the line is neither a String nor a Regexp.
      # @example
      #   watch = Watchfor.new("error") { puts "An error occurred!" }
      #   watch = Watchfor.new(/warning/, some_proc) { puts "A warning occurred!" }
      # @note This method disables a Rubocop linting rule regarding returning nil in a void context.
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

      # Enables the Rubocop linting rule regarding returning nil in a void context.
      # rubocop:enable Lint/ReturnInVoidContext

      # Clears all watchfor patterns from the current script.
      #
      # @return [nil] Returns nil after clearing the patterns.
      # @example
      #   Watchfor.clear
      # @note This method resets the watchfor hash to a new empty hash.
      def Watchfor.clear
        script.watchfor = Hash.new
      end
    end
  end
end
