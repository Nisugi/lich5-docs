# A module containing common functionality for the Lich system
# @author Lich5 Documentation Generator
module Lich

  # Common utilities and classes used throughout Lich
  module Common

    # A thread-safe wrapper around a socket that synchronizes write operations
    # This class decorates an existing socket with mutex-based synchronization
    #
    # @author Lich5 Documentation Generator
    class SynchronizedSocket

      # Creates a new synchronized socket wrapper around an existing socket
      #
      # @param o [Object] The socket object to wrap with synchronization
      # @return [SynchronizedSocket] A new synchronized socket instance
      # @example
      #   socket = TCPSocket.new(host, port)
      #   sync_socket = SynchronizedSocket.new(socket)
      def initialize(o)
        @delegate = o
        @mutex = Mutex.new
        # self # removed by robocop, needs broad testing
      end

      # Writes one or more strings to the socket with a newline appended, in a thread-safe manner
      #
      # @param args [Array<String>] The strings to write to the socket
      # @param block [Proc] Optional block that can modify the output
      # @return [nil]
      # @example
      #   sync_socket.puts "Hello world"
      #   sync_socket.puts "Line 1", "Line 2"
      def puts(*args, &block)
        @mutex.synchronize {
          @delegate.puts(*args, &block)
        }
      end

      # Conditionally writes strings to the socket if a condition is met
      #
      # @param args [Array<String>] The strings to potentially write
      # @yield Block that determines if writing should occur
      # @yieldreturn [Boolean] True if the strings should be written, false otherwise
      # @return [Boolean] True if strings were written, false if condition was not met
      # @example
      #   sync_socket.puts_if("Ready!") { game.ready? }
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

      # Writes data to the socket in a thread-safe manner
      #
      # @param args [Array<String>] The data to write to the socket
      # @param block [Proc] Optional block that can modify the output
      # @return [Integer] Number of bytes written
      # @example
      #   sync_socket.write "Raw data"
      def write(*args, &block)
        @mutex.synchronize {
          @delegate.write(*args, &block)
        }
      end

      # Delegates any unknown methods to the underlying socket object
      #
      # @param method [Symbol] The method name to delegate
      # @param args [Array] Arguments to pass to the delegated method
      # @param block [Proc] Optional block to pass to the delegated method
      # @return [Object] The return value from the delegated method call
      # @note This allows the synchronized socket to act as a transparent wrapper
      def method_missing(method, *args, &block)
        @delegate.__send__ method, *args, &block
      end
    end
  end
end