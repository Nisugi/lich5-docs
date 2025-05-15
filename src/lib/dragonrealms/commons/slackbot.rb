# Module for the Lich game scripting system
module Lich
  # Module containing DragonRealms specific functionality
  module DragonRealms
    # Handles Slack integration for sending messages from the game to Slack
    #
    # @author Lich5 Documentation Generator
    class SlackBot
      # Initializes a new SlackBot instance by authenticating with Slack and loading user data
      #
      # @raise [StandardError] if authentication fails and no valid token can be found
      # @example
      #   bot = SlackBot.new
      #
      # @note Requires a valid Slack API token either stored in UserVars or obtainable from a LichBot
      def initialize
        @api_url = 'https://slack.com/api/'
        @lnet = (Script.running + Script.hidden).find { |val| val.name == 'lnet' }
        find_token unless authed?(UserVars.slack_token)

        params = { 'token' => UserVars.slack_token }
        res = post('users.list', params)
        @users_list = JSON.parse(res.body)
      end

      # Verifies if a Slack API token is valid
      #
      # @param token [String] The Slack API token to verify
      # @return [Boolean] true if token is valid, false otherwise
      # @example
      #   bot.authed?("xoxb-123456789")
      def authed?(token)
        params = { 'token' => token }
        res = post('auth.test', params)
        body = JSON.parse(res.body)
        body['ok']
      end

      # Requests a Slack token from a LichBot
      #
      # @param lichbot [String] The name of the LichBot to request token from
      # @return [String, false] The Slack token if found, false if not found or timeout
      # @example
      #   token = bot.request_token("Quilsilgas")
      #
      # @note Times out after 10 seconds
      def request_token(lichbot)
        ttl = 10
        send_time = Time.now
        @lnet.unique_buffer.push("chat to #{lichbot} RequestSlackToken")
        loop do
          line = get
          pause 0.05
          return false if Time.now - send_time > ttl

          case line
          when /\[Private\]-.*:#{lichbot}: "slack_token: (.*)"/
            msg = Regexp.last_match(1)
            return msg != 'Not Found' ? msg : false
          when /\[server\]: "no user .*/
            return false
          end
        end
      end

      # Attempts to find a valid Slack token by querying known LichBots
      #
      # @raise [SystemExit] if no valid token can be found
      # @example
      #   bot.find_token
      #
      # @note Will exit the script if no valid token is found
      def find_token
        lichbots = %w[Quilsilgas]
        echo 'Looking for a token...'
        return if lichbots.any? do |bot|
          token = request_token(bot)
          authed = authed?(token) if token
          UserVars.slack_token = token if authed
          authed
        end

        echo 'Unable to locate a token :['
        exit
      end

      # Makes a POST request to the Slack API
      #
      # @param method [String] The Slack API method to call
      # @param params [Hash] Parameters to send with the request
      # @return [Net::HTTPResponse] The response from the Slack API
      # @example
      #   response = bot.post("chat.postMessage", {"token" => "xyz", "channel" => "general"})
      #
      # @note Uses SSL but does not verify certificates
      def post(method, params)
        uri = URI.parse("#{@api_url}#{method}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        req = Net::HTTP::Post.new(uri.path)
        req.set_form_data(params)
        http.request(req)
      end

      # Sends a direct message to a Slack user
      #
      # @param username [String] The Slack username to send message to
      # @param message [String] The message content to send
      # @return [Net::HTTPResponse] The response from the Slack API
      # @example
      #   bot.direct_message("user123", "Hello from DragonRealms!")
      #
      # @note Prepends the sender's checkname to the message
      def direct_message(username, message)
        dm_channel = get_dm_channel(username)

        params = { 'token' => UserVars.slack_token, 'channel' => dm_channel, 'text' => "#{checkname}: #{message}", 'as_user' => true }
        post('chat.postMessage', params)
      end

      # Gets the direct message channel ID for a Slack user
      #
      # @param username [String] The Slack username to get channel ID for
      # @return [String] The direct message channel ID
      # @raise [KeyError] if the username is not found
      # @example
      #   channel_id = bot.get_dm_channel("user123")
      #
      # @note Requires users list to be loaded during initialization
      def get_dm_channel(username)
        user = @users_list['members'].find { |u| u['name'] == username }
        user['id']
      end
    end
  end
end