# A thread-safe buffer implementation for managing game text streams
# Provides functionality to read, write and manage different types of text streams
# with thread isolation.
#
# @author Lich5 Documentation Generator
module Lich
  module Common
    module Buffer
      # Stream type for stripped downstream text
      DOWNSTREAM_STRIPPED = 1

      # Stream type for raw downstream text  
      DOWNSTREAM_RAW      = 2

      # Stream type for modified downstream text
      DOWNSTREAM_MOD      = 4

      # Stream type for upstream text
      UPSTREAM            = 8

      # Stream type for modified upstream text
      UPSTREAM_MOD        = 16

      # Stream type for script output
      SCRIPT_OUTPUT       = 32

      @@index             = Hash.new
      @@streams           = Hash.new
      @@mutex             = Mutex.new
      @@offset            = 0
      @@buffer            = Array.new
      @@max_size          = 3000

      # Reads and returns the next line from the buffer for the current thread.
      # Blocks until a line is available if buffer is empty.
      #
      # @return [String] The next line matching the thread's stream filter
      # @example
      #   line = Buffer.gets
      #   puts line
      #
      # @note This method will block/sleep if no matching data is available
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

      # Non-blocking version of gets that returns nil if no data is available
      #
      # @return [String, nil] The next matching line or nil if no data available
      # @example
      #   if line = Buffer.gets?
      #     process_line(line)
      #   end
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

      # Rewinds the buffer position to the start for the current thread
      #
      # @return [Buffer] Returns self for method chaining
      # @example
      #   Buffer.rewind
      def Buffer.rewind
        thread_id = Thread.current.object_id
        @@index[thread_id] = @@offset
        @@streams[thread_id] ||= DOWNSTREAM_STRIPPED
        return self
      end

      # Clears and returns all available lines for the current thread
      #
      # @return [Array<String>] Array of all available matching lines
      # @example
      #   lines = Buffer.clear
      #   lines.each { |line| process_line(line) }
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

      # Updates the buffer with a new line and optional stream type
      #
      # @param line [String] The line to add to the buffer
      # @param stream [Integer, nil] Optional stream type identifier
      # @return [Buffer] Returns self for method chaining
      # @example
      #   Buffer.update("New game text", Buffer::DOWNSTREAM_STRIPPED)
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

      # rubocop:disable Lint/HashCompareByIdentity
      # Gets the current thread's stream filter value
      #
      # @return [Integer] The current thread's stream filter bitmask
      # @example
      #   current_streams = Buffer.streams
      def Buffer.streams
        @@streams[Thread.current.object_id]
      end

      # Sets the stream filter for the current thread
      #
      # @param val [Integer] Bitmask of desired stream types
      # @return [Integer, nil] The new stream value or nil if invalid
      # @raise [RuntimeError] If invalid stream value provided
      # @example
      #   Buffer.streams = Buffer::DOWNSTREAM_STRIPPED | Buffer::SCRIPT_OUTPUT
      #
      # @note Value must be between 1-63 and represent valid stream combination
      def Buffer.streams=(val)
        if (val.class != Integer) or ((val & 63) == 0)
          respond "--- Lich: error: invalid streams value\n\t#{$!.caller[0..2].join("\n\t")}"
          return nil
        end
        @@streams[Thread.current.object_id] = val
      end

      # rubocop:enable Lint/HashCompareByIdentity

      # Removes buffer tracking for dead threads
      #
      # @return [Buffer] Returns self for method chaining
      # @example
      #   Buffer.cleanup
      #
      # @note Should be called periodically to prevent memory leaks
      def Buffer.cleanup
        @@index.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        @@streams.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        return self
      end
    end
  end
end