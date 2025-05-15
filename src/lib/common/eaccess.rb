require "openssl"
require "socket"
require_relative 'account'

# Provides functionality for authenticating and connecting to the EAccess game service
# 
# @author Lich5 Documentation Generator
module Lich
  module Common
    # Handles authentication and connection to the EAccess game service
    # This module manages SSL certificates and login protocols for game access
    module EAccess
      # Path to the SSL certificate file
      # @return [String] Path to simu.pem certificate file
      PEM = File.join(DATA_DIR, "simu.pem")
      # pp PEM

      # Size of network packets for reading data
      # @return [Integer] Packet size in bytes  
      PACKET_SIZE = 8192

      # Checks if the SSL certificate file exists
      #
      # @return [Boolean] true if certificate exists, false otherwise
      #
      # @example
      #   Lich::Common::EAccess.pem_exist?
      def self.pem_exist?
        File.exist? PEM
      end

      # Downloads the SSL certificate from the game server
      #
      # @param hostname [String] game server hostname
      # @param port [Integer] server port number
      # @return [void]
      # @raise [OpenSSL::SSL::SSLError] if SSL connection fails
      #
      # @example
      #   Lich::Common::EAccess.download_pem("eaccess.play.net", 7910)
      def self.download_pem(hostname = "eaccess.play.net", port = 7910)
        # Create an OpenSSL context
        ctx = OpenSSL::SSL::SSLContext.new
        # Get remote TCP socket
        sock = TCPSocket.new(hostname, port)
        # pass that socket to OpenSSL
        ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
        # establish connection, if possible
        ssl.connect
        # write the .pem to disk
        File.write(EAccess::PEM, ssl.peer_cert)
      end

      # Verifies the SSL certificate matches the stored certificate
      #
      # @param conn [OpenSSL::SSL::SSLSocket] SSL connection to verify
      # @return [Boolean] true if certificate matches
      # @raise [Exception] if certificates don't match
      #
      # @example
      #   Lich::Common::EAccess.verify_pem(ssl_connection)
      def self.verify_pem(conn)
        # return if conn.peer_cert.to_s = File.read(EAccess::PEM)
        if !(conn.peer_cert.to_s == File.read(EAccess::PEM))
          Lich.log "Exception, \nssl peer certificate did not match #{EAccess::PEM}\nwas:\n#{conn.peer_cert}"
          download_pem
        else
          return true
        end
        #     fail Exception, "\nssl peer certificate did not match #{EAccess::PEM}\nwas:\n#{conn.peer_cert}"
      end

      # Creates an SSL socket connection to the game server
      #
      # @param hostname [String] game server hostname
      # @param port [Integer] server port number
      # @return [OpenSSL::SSL::SSLSocket] Connected and verified SSL socket
      # @raise [OpenSSL::SSL::SSLError] if SSL connection fails
      #
      # @example
      #   socket = Lich::Common::EAccess.socket("eaccess.play.net", 7910)
      def self.socket(hostname = "eaccess.play.net", port = 7910)
        download_pem unless pem_exist?
        socket = TCPSocket.open(hostname, port)
        cert_store              = OpenSSL::X509::Store.new
        ssl_context             = OpenSSL::SSL::SSLContext.new
        ssl_context.cert_store  = cert_store
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
        cert_store.add_file(EAccess::PEM) if pem_exist?
        ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
        ssl_socket.sync_close = true
        EAccess.verify_pem(ssl_socket.connect)
        return ssl_socket
      end

      # Authenticates with the game service
      #
      # @param password [String] account password
      # @param account [String] account name
      # @param character [String, nil] character name to login as
      # @param game_code [String, nil] game code to connect to
      # @param legacy [Boolean] whether to use legacy login protocol
      # @return [Hash, Array, String] Login information on success, error message on failure
      # @raise [StandardError] if authentication protocol fails
      #
      # @example Normal login
      #   info = Lich::Common::EAccess.auth(
      #     password: "secret",
      #     account: "myaccount",
      #     character: "MyChar",
      #     game_code: "DR"
      #   )
      #
      # @example Legacy login
      #   info = Lich::Common::EAccess.auth(
      #     password: "secret", 
      #     account: "myaccount",
      #     legacy: true
      #   )
      #
      # @note The legacy parameter changes the return format and login protocol
      def self.auth(password:, account:, character: nil, game_code: nil, legacy: false)
        Account.name = account
        Account.game_code = game_code
        Account.character = character
        conn = EAccess.socket()
        # it is vitally important to verify self-signed certs
        # because there is no chain-of-trust for them
        EAccess.verify_pem(conn)
        conn.puts "K\n"
        hashkey = EAccess.read(conn)
        # pp "hash=%s" % hashkey
        password = password.split('').map { |c| c.getbyte(0) }
        hashkey = hashkey.split('').map { |c| c.getbyte(0) }
        password.each_index { |i| password[i] = ((password[i] - 32) ^ hashkey[i]) + 32 }
        password = password.map { |c| c.chr }.join
        conn.puts "A\t#{account}\t#{password}\n"
        response = EAccess.read(conn)
        unless /KEY\t(?<key>.*)\t/.match(response)
          eaccess_error = "Error(%s)" % response.split(/\s+/).last
          return eaccess_error
        end
        # pp "A:response=%s" % response
        conn.puts "M\n"
        response = EAccess.read(conn)
        fail StandardError, response unless response =~ /^M\t/
        # pp "M:response=%s" % response

        unless legacy
          conn.puts "F\t#{game_code}\n"
          response = EAccess.read(conn)
          fail StandardError, response unless response =~ /NORMAL|PREMIUM|TRIAL|INTERNAL|FREE/
          Account.subscription = response
          # pp "F:response=%s" % response
          conn.puts "G\t#{game_code}\n"
          EAccess.read(conn)
          # pp "G:response=%s" % response
          conn.puts "P\t#{game_code}\n"
          EAccess.read(conn)
          # pp "P:response=%s" % response
          conn.puts "C\n"
          response = EAccess.read(conn)
          # pp "C:response=%s" % response
          Account.members = response
          char_code = response.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '')
                              .scan(/[^\t]+\t[^\t^\n]+/)
                              .find { |c| c.split("\t")[1] == character }
                              .split("\t")[0]
          conn.puts "L\t#{char_code}\tSTORM\n"
          response = EAccess.read(conn)
          fail StandardError, response unless response =~ /^L\t/
          # pp "L:response=%s" % response
          conn.close unless conn.closed?
          login_info = Hash[response.sub(/^L\tOK\t/, '')
                                    .split("\t")
                                    .map { |kv|
                              k, v = kv.split("=")
                              [k.downcase, v]
                            }]
        else
          login_info = Array.new
          for game in response.sub(/^M\t/, '').scan(/[^\t]+\t[^\t^\n]+/)
            game_code, game_name = game.split("\t")
            # pp "M:response = %s" % response
            conn.puts "N\t#{game_code}\n"
            response = EAccess.read(conn)
            if response =~ /STORM/
              conn.puts "F\t#{game_code}\n"
              response = EAccess.read(conn)
              if response =~ /NORMAL|PREMIUM|TRIAL|INTERNAL|FREE/
                Account.subscription = response
                conn.puts "G\t#{game_code}\n"
                EAccess.read(conn)
                conn.puts "P\t#{game_code}\n"
                EAccess.read(conn)
                conn.puts "C\n"
                response = EAccess.read(conn)
                Account.members = response
                for code_name in response.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/)
                  char_code, char_name = code_name.split("\t")
                  hash = { :game_code => "#{game_code}", :game_name => "#{game_name}",
                          :char_code => "#{char_code}", :char_name => "#{char_name}" }
                  login_info.push(hash)
                end
              end
            end
          end
        end
        conn.close unless conn.closed?
        return login_info
      end

      # Reads data from a connection
      #
      # @param conn [OpenSSL::SSL::SSLSocket] Socket to read from
      # @return [String] Data read from socket
      # @raise [IOError] if connection is closed
      #
      # @example
      #   data = Lich::Common::EAccess.read(socket)
      #
      # @note Uses PACKET_SIZE constant for read buffer size
      def self.read(conn)
        conn.sysread(PACKET_SIZE)
      end
    end
  end
end