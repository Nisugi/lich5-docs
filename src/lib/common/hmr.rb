# Provides hot module reloading functionality for the Lich framework
# Allows dynamic reloading of Ruby files during runtime
#
# @author Lich5 Documentation Generator
module Lich
  module Common
    # Implements Hot Module Reloading (HMR) functionality
    # Provides methods to reload Ruby files dynamically during runtime
    module HMR
      # Clears the Ruby Gem paths cache
      # This ensures newly added gems are discoverable after reloading
      #
      # @return [void]
      #
      # @example
      #   Lich::Common::HMR.clear_cache
      def self.clear_cache
        Gem.clear_paths
      end

      # Outputs a message through the appropriate channel
      # Attempts to use _respond for HTML-formatted messages,
      # falls back to respond, then puts
      #
      # @param message [String] The message to output
      # @return [void]
      #
      # @example
      #   Lich::Common::HMR.msg("Regular message")
      #   Lich::Common::HMR.msg("<b>Bold message</b>")
      def self.msg(message)
        return _respond message if defined?(:_respond) && message.include?("<b>")
        return respond message if defined?(:respond)
        puts message
      end

      # Returns an array of loaded Ruby files
      #
      # @return [Array<String>] Array of paths to loaded .rb files
      #
      # @example
      #   loaded_files = Lich::Common::HMR.loaded
      #   # => ["/path/to/file1.rb", "/path/to/file2.rb"]
      def self.loaded
        $LOADED_FEATURES.select { |path| path.end_with?(".rb") }
      end

      # Reloads Ruby files matching the given pattern
      # First clears the gem cache, then attempts to reload each matching file
      #
      # @param pattern [Regexp] Regular expression pattern to match files for reloading
      # @return [void]
      # @raise [StandardError] If there's an error loading any of the files
      #
      # @example
      #   # Reload all files containing 'script'
      #   Lich::Common::HMR.reload(/script/)
      #
      # @note This will attempt to reload ALL matching files in $LOADED_FEATURES
      #       Failed reloads will output the exception and stack trace
      #       If no files match the pattern, a message will be displayed
      def self.reload(pattern)
        self.clear_cache
        loaded_paths = self.loaded.grep(pattern)
        unless loaded_paths.empty?
          loaded_paths.each { |file|
            begin
              load(file)
              self.msg "<b>[lich.hmr] reloaded %s</b>" % file
            rescue => exception
              self.msg exception
              self.msg exception.backtrace.join("\n")
            end
          }
        else
          self.msg "<b>[lich.hmr] nothing matching regex pattern: %s</b>" % pattern.source
        end
      end
    end
  end
end