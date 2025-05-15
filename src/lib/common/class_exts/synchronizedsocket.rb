# Carve out from lich.rbw
# extension to SynchronizedSocket class 2024-06-13

module Lich
  module Common
    # A thread-safe wrapper around a socket that synchronizes access
    # to the underlying socket object using a mutex.
    class SynchronizedSocket
      # Initializes a new instance of SynchronizedSocket.
      #
      # @param o [Object] the socket object to be synchronized.
      # @return [SynchronizedSocket] the new instance of SynchronizedSocket.
      # @raise [ArgumentError] if the provided object is not a valid socket.
      # @example
      #   socket = SynchronizedSocket.new(TCPSocket.new('localhost', 8080))
      def initialize(o)
        @delegate = o
        @mutex = Mutex.new
        # self # removed by robocop, needs broad testing
      end

      # Writes a line to the socket, ensuring thread safety.
      #
      # @param args [Array] the arguments to be written to the socket.
      # @yield [Block] an optional block to be executed.
      # @return [nil] returns nil after writing to the socket.
      # @example
      #   synchronized_socket.puts("Hello, World!")
      def puts(*args, &block)
        @mutex.synchronize {
          @delegate.puts(*args, &block)
        }
      end

      # Conditionally writes to the socket based on the result of a block.
      #
      # @param args [Array] the arguments to be written to the socket if the block returns true.
      # @yield [Block] a block that determines whether to write to the socket.
      # @return [Boolean] returns true if the block returns true and the write occurs, false otherwise.
      # @example
      #   synchronized_socket.puts_if("Hello, World!") { true }
      def puts_if(*args)
        @mutex.synchronize {
          if yield
            @delegate.puts(*args)
            return true
          else
            return false
          end
        }
      end

      # Writes data to the socket, ensuring thread safety.
      #
      # @param args [Array] the arguments to be written to the socket.
      # @yield [Block] an optional block to be executed.
      # @return [nil] returns nil after writing to the socket.
      # @example
      #   synchronized_socket.write("Data to send")
      def write(*args, &block)
        @mutex.synchronize {
          @delegate.write(*args, &block)
        }
      end

      # Delegates method calls to the underlying socket object.
      #
      # @param method [Symbol] the method name to be called on the delegate.
      # @param args [Array] the arguments to be passed to the method.
      # @yield [Block] an optional block to be executed.
      # @return [Object] the result of the method call on the delegate.
      # @example
      #   synchronized_socket.some_method(arg1, arg2)
      def method_missing(method, *args, &block)
        @delegate.__send__ method, *args, &block
      end
    end
  end
end
