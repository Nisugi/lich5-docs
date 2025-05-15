# Carve out class SharedBuffer
# 2024-06-13
# has rubocop Lint/HashCompareByIdentity errors that require research - temporarily disabled

module Lich
  module Common
    # A thread-safe buffer that allows multiple threads to read and write data.
    #
    # @!attribute [rw] max_size
    #   @return [Integer] the maximum size of the buffer.
    class SharedBuffer
      attr_accessor :max_size

      # Initializes a new SharedBuffer instance.
      #
      # @param args [Hash] options for initialization.
      # @option args [Integer] :max_size (500) the maximum size of the buffer.
      # @return [SharedBuffer] the instance of SharedBuffer.
      # @example
      #   buffer = Lich::Common::SharedBuffer.new(max_size: 1000)
      def initialize(args = {})
        @buffer = Array.new
        @buffer_offset = 0
        @buffer_index = Hash.new
        @buffer_mutex = Mutex.new
        @max_size = args[:max_size] || 500
        # return self # rubocop does not like this - Lint/ReturnInVoidContext
      end

      # Retrieves the next line from the buffer, blocking if necessary.
      #
      # @return [String, nil] the next line from the buffer or nil if no line is available.
      # @note This method will block until a line is available.
      # @example
      #   line = buffer.gets
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

      # Retrieves the next line from the buffer without blocking.
      #
      # @return [String, nil] the next line from the buffer or nil if no line is available.
      # @example
      #   line = buffer.gets?
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

      # Clears the lines that have been read by the current thread.
      #
      # @return [Array<String>] an array of lines that were cleared.
      # @example
      #   cleared_lines = buffer.clear
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

      # Resets the current thread's read index to the beginning of the buffer.
      #
      # @return [SharedBuffer] the instance of SharedBuffer.
      # @example
      #   buffer.rewind
      #   line = buffer.gets
      def rewind
        @buffer_index[Thread.current.object_id] = @buffer_offset
        return self
      end

      # Updates the buffer with a new line, ensuring the buffer does not exceed max_size.
      #
      # @param line [String] the line to be added to the buffer.
      # @return [SharedBuffer] the instance of SharedBuffer.
      # @example
      #   buffer.update("New line of text")
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

      # Cleans up the buffer by removing entries for threads that no longer exist.
      #
      # @return [SharedBuffer] the instance of SharedBuffer.
      # @example
      #   buffer.cleanup_threads
      def cleanup_threads
        @buffer_index.delete_if { |k, _v| not Thread.list.any? { |t| t.object_id == k } }
        return self
      end
    end
  end
end
