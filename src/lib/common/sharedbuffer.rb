# A thread-safe shared buffer implementation that allows multiple threads to read from
# and write to a common buffer with automatic size management.
#
# @author Lich5 Documentation Generator
module Lich
  module Common
    # Implements a thread-safe circular buffer with per-thread read positions
    # and automatic size management.
    #
    # @attr_accessor max_size [Integer] Maximum number of lines the buffer can hold
    class SharedBuffer
      attr_accessor :max_size

      # Initializes a new shared buffer.
      #
      # @param args [Hash] Configuration options
      # @option args [Integer] :max_size (500) Maximum number of lines to store in buffer
      # @return [SharedBuffer] New buffer instance
      #
      # @example
      #   buffer = SharedBuffer.new(max_size: 1000)
      def initialize(args = {})
        @buffer = Array.new
        @buffer_offset = 0
        @buffer_index = Hash.new
        @buffer_mutex = Mutex.new
        @max_size = args[:max_size] || 500
        # return self # rubocop does not like this - Lint/ReturnInVoidContext
      end

      # Reads the next line from the buffer for the current thread.
      # Blocks if no data is available.
      #
      # @return [String, nil] The next line in the buffer or nil if empty
      # @note Blocks until data becomes available
      #
      # @example
      #   line = buffer.gets
      #   puts line if line
      def gets
        thread_id = Thread.current.object_id
        if @buffer_index[thread_id].nil?
          @buffer_mutex.synchronize { @buffer_index[thread_id] = (@buffer_offset + @buffer.length) }
        end
        if (@buffer_index[thread_id] - @buffer_offset) >= @buffer.length
          sleep 0.05 while ((@buffer_index[thread_id] - @buffer_offset) >= @buffer.length)
        end
        line = nil
        @buffer_mutex.synchronize {
          if @buffer_index[thread_id] < @buffer_offset
            @buffer_index[thread_id] = @buffer_offset
          end
          line = @buffer[@buffer_index[thread_id] - @buffer_offset]
        }
        @buffer_index[thread_id] += 1
        return line
      end

      # Non-blocking version of gets that returns nil if no data is available.
      #
      # @return [String, nil] The next line in the buffer or nil if no data
      #
      # @example
      #   if line = buffer.gets?
      #     process_line(line)
      #   end
      def gets?
        thread_id = Thread.current.object_id
        if @buffer_index[thread_id].nil?
          @buffer_mutex.synchronize { @buffer_index[thread_id] = (@buffer_offset + @buffer.length) }
        end
        if (@buffer_index[thread_id] - @buffer_offset) >= @buffer.length
          return nil
        end

        line = nil
        @buffer_mutex.synchronize {
          if @buffer_index[thread_id] < @buffer_offset
            @buffer_index[thread_id] = @buffer_offset
          end
          line = @buffer[@buffer_index[thread_id] - @buffer_offset]
        }
        @buffer_index[thread_id] += 1
        return line
      end

      # Retrieves and removes all unread lines for the current thread.
      #
      # @return [Array<String>] Array of unread lines
      #
      # @example
      #   unread_lines = buffer.clear
      #   unread_lines.each { |line| process_line(line) }
      def clear
        thread_id = Thread.current.object_id
        if @buffer_index[thread_id].nil?
          @buffer_mutex.synchronize { @buffer_index[thread_id] = (@buffer_offset + @buffer.length) }
          return Array.new
        end
        if (@buffer_index[thread_id] - @buffer_offset) >= @buffer.length
          return Array.new
        end

        lines = Array.new
        @buffer_mutex.synchronize {
          if @buffer_index[thread_id] < @buffer_offset
            @buffer_index[thread_id] = @buffer_offset
          end
          lines = @buffer[(@buffer_index[thread_id] - @buffer_offset)..-1]
          @buffer_index[thread_id] = (@buffer_offset + @buffer.length)
        }
        return lines
      end

      # Resets the read position to the beginning of the buffer for the current thread.
      #
      # @return [SharedBuffer] self for method chaining
      #
      # @example
      #   buffer.rewind.gets
      # rubocop:disable Lint/HashCompareByIdentity
      def rewind
        @buffer_index[Thread.current.object_id] = @buffer_offset
        return self
      end

      # Adds a new line to the buffer.
      # Automatically removes oldest entries if buffer exceeds max_size.
      #
      # @param line [String] Line to add to the buffer
      # @return [SharedBuffer] self for method chaining
      #
      # @example
      #   buffer.update("New line of text")
      # rubocop:enable Lint/HashCompareByIdentity
      def update(line)
        @buffer_mutex.synchronize {
          fline = line.dup
          fline.freeze
          @buffer.push(fline)
          while (@buffer.length > @max_size)
            @buffer.shift
            @buffer_offset += 1
          end
        }
        return self
      end

      # Removes thread entries from the buffer index for threads that no longer exist.
      #
      # @return [SharedBuffer] self for method chaining
      #
      # @example
      #   buffer.cleanup_threads
      #
      # @note Should be called periodically to prevent memory leaks from dead threads
      def cleanup_threads
        @buffer_index.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        return self
      end
    end
  end
end