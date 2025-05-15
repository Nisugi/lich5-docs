## hot module reloading
module Lich
  module Common
    module HMR
      # Clears the gem cache by calling `Gem.clear_paths`.
      #
      # @return [void] This method does not return a value.
      #
      # @example
      #   Lich::Common::HMR.clear_cache
      def self.clear_cache
        Gem.clear_paths
      end

      # Sends a message to the appropriate output method.
      #
      # If `_respond` is defined and the message contains "<b>", it will call `_respond`.
      # If `respond` is defined, it will call `respond`. Otherwise, it will print the message.
      #
      # @param message [String] The message to be sent or printed.
      # @return [void] This method does not return a value.
      #
      # @example
      #   Lich::Common::HMR.msg("Hello, World!")
      def self.msg(message)
        return _respond message if defined?(:_respond) && message.include?("<b>")
        return respond message if defined?(:respond)
        puts message
      end

      # Retrieves a list of loaded Ruby files.
      #
      # @return [Array<String>] An array of paths to loaded Ruby files.
      #
      # @example
      #   loaded_files = Lich::Common::HMR.loaded
      def self.loaded
        $LOADED_FEATURES.select { |path| path.end_with?(".rb") }
      end

      # Reloads files that match the given pattern.
      #
      # This method clears the cache, finds files matching the pattern, and attempts to load them.
      # If loading fails, it captures and reports the exception.
      #
      # @param pattern [Regexp] The pattern to match file paths against.
      # @return [void] This method does not return a value.
      #
      # @raise [LoadError] If the file cannot be loaded.
      #
      # @example
      #   Lich::Common::HMR.reload(/my_file/)
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
