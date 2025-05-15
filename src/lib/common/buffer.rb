# Carve out module Buffer
# 2024-06-13
# has rubocop error Lint/HashCompareByIdentity - cop disabled until reviewed

module Lich
  module Common
    module Buffer
      DOWNSTREAM_STRIPPED = 1
      DOWNSTREAM_RAW      = 2
      DOWNSTREAM_MOD      = 4
      UPSTREAM            = 8
      UPSTREAM_MOD        = 16
      SCRIPT_OUTPUT       = 32
      @@index             = Hash.new
      @@streams           = Hash.new
      @@mutex             = Mutex.new
      @@offset            = 0
      @@buffer            = Array.new
      @@max_size          = 3000

      # Retrieves the next line from the buffer, blocking until a line is available.
      #
      # @return [Object] the next line from the buffer
      # @note This method will block if no line is available until one becomes available.
      # @example
      #   line = Buffer.gets
      def Buffer.gets
        thread_id = Thread.current.object_id
        if @@index[thread_id].nil?
          @@mutex.synchronize {
            @@index[thread_id] = (@@offset + @@buffer.length)
            @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
          }
        end
        line = nil
        loop {
          if (@@index[thread_id] - @@offset) >= @@buffer.length
            sleep 0.05 while ((@@index[thread_id] - @@offset) >= @@buffer.length)
          end
          @@mutex.synchronize {
            if @@index[thread_id] < @@offset
              @@index[thread_id] = @@offset
            end
            line = @@buffer[@@index[thread_id] - @@offset]
          }
          @@index[thread_id] += 1
          break if ((line.stream & @@streams[thread_id]) != 0)
        }
        return line
      end

      # Retrieves the next line from the buffer if available, otherwise returns nil.
      #
      # @return [Object, nil] the next line from the buffer or nil if no line is available
      # @example
      #   line = Buffer.gets?
      def Buffer.gets?
        thread_id = Thread.current.object_id
        if @@index[thread_id].nil?
          @@mutex.synchronize {
            @@index[thread_id] = (@@offset + @@buffer.length)
            @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
          }
        end
        line = nil
        loop {
          if (@@index[thread_id] - @@offset) >= @@buffer.length
            return nil
          end

          @@mutex.synchronize {
            if @@index[thread_id] < @@offset
              @@index[thread_id] = @@offset
            end
            line = @@buffer[@@index[thread_id] - @@offset]
          }
          @@index[thread_id] += 1
          break if ((line.stream & @@streams[thread_id]) != 0)
        }
        return line
      end

      # Resets the index for the current thread to the beginning of the buffer.
      #
      # @return [self] the Buffer instance
      # @example
      #   Buffer.rewind
      def Buffer.rewind
        thread_id = Thread.current.object_id
        @@index[thread_id] = @@offset
        @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
        return self
      end

      # Clears the buffer for the current thread and returns all lines that match the current stream.
      #
      # @return [Array<Object>] an array of lines that match the current stream
      # @example
      #   lines = Buffer.clear
      def Buffer.clear
        thread_id = Thread.current.object_id
        if @@index[thread_id].nil?
          @@mutex.synchronize {
            @@index[thread_id] = (@@offset + @@buffer.length)
            @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
          }
        end
        lines = Array.new
        loop {
          if (@@index[thread_id] - @@offset) >= @@buffer.length
            return lines
          end

          line = nil
          @@mutex.synchronize {
            if @@index[thread_id] < @@offset
              @@index[thread_id] = @@offset
            end
            line = @@buffer[@@index[thread_id] - @@offset]
          }
          @@index[thread_id] += 1
          lines.push(line) if ((line.stream & @@streams[thread_id]) != 0)
        }
        return lines
      end

      # Updates the buffer with a new line and an optional stream identifier.
      #
      # @param line [Object] the line to be added to the buffer
      # @param stream [Integer, nil] the stream identifier for the line (default: nil)
      # @return [self] the Buffer instance
      # @example
      #   Buffer.update(new_line, stream_id)
      def Buffer.update(line, stream = nil)
        @@mutex.synchronize {
          frozen_line = line.dup
          unless stream.nil?
            frozen_line.stream = stream
          end
          frozen_line.freeze
          @@buffer.push(frozen_line)
          while (@@buffer.length > @@max_size)
            @@buffer.shift
            @@offset += 1
          end
        }
        return self
      end

      # Retrieves the current stream identifier for the calling thread.
      #
      # @return [Integer] the current stream identifier
      # @example
      #   current_stream = Buffer.streams
      # @note This method is subject to rubocop error Lint/HashCompareByIdentity.
      def Buffer.streams
        @@streams[Thread.current.object_id]
      end

      # Sets the stream identifier for the calling thread.
      #
      # @param val [Integer] the new stream identifier
      # @return [nil] if the value is invalid
      # @raise [StandardError] if the value is not an Integer or if it does not represent a valid stream
      # @example
      #   Buffer.streams = new_stream_id
      def Buffer.streams=(val)
        if (val.class != Integer) or ((val & 63) == 0)
          respond "--- Lich: error: invalid streams value\n\t#{$!.caller[0..2].join("\n\t")}"
          return nil
        end
        @@streams[Thread.current.object_id] = val
      end

      # Cleans up the index and streams for threads that are no longer active.
      #
      # @return [self] the Buffer instance
      # @example
      #   Buffer.cleanup
      # @note This method will remove entries for threads that are no longer running.
      def Buffer.cleanup
        @@index.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        @@streams.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        return self
      end
    end
  end
end
