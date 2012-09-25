module Push
  module Daemon
    module C2dmSupport
      class ConnectionError < StandardError; end

      class ConnectionC2dm
        attr_reader :response, :name, :provider
        AUTH_URL = "https://www.google.com/accounts/ClientLogin"
        PUSH_URL = "https://android.apis.google.com/c2dm/send"
        IDLE_PERIOD = 5.minutes

        def initialize(provider, i)
          @provider = provider
          @name = "#{@provider.configuration[:name]}: ConnectionC2dm #{i}"

          @email = @provider.configuration[:email]
          @password = @provider.configuration[:password]
        end

        def connect
          @auth_token = fetch_auth_token
          @last_use = Time.now
          uri = URI.parse(PUSH_URL)
          @connection = open_http(uri.host, uri.port)
          @connection.start
          Push::Daemon.logger.info("[#{@name}] Connected to #{PUSH_URL}")
        end

        def write(data)
          @response = notification_request(data)

          # the response can be one of three codes:
          #   200 (success)
          #   401 (auth failed)
          #   503 (retry later with exponential backoff)
          #   see more documentation here:  http://code.google.com/android/c2dm/#testing
          if @response.code.eql? "200"
            # look for the header 'Update-Client-Auth' in the response you get after sending
            # a message. It indicates that this is the token to be used for the next message to send.
            @response.header.each_header do |key, value|
              if key.capitalize == "Update-Client-Auth".capitalize
                Push::Daemon.logger.info("[#{@name}] Received new authentication token")
                @auth_token = value
              end
            end

          elsif @response.code.eql? "401"
            # auth failed.  Refresh auth key and requeue
            @auth_token = fetch_auth_token
            @response = notification_request(data)

          elsif response.code.eql? "503"
            # service un-available.
          end
        end

        private

        def open_http(host, port)
          http = Net::HTTP.new(host, port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          return http
        end

        def fetch_auth_token
          data = "accountType=HOSTED_OR_GOOGLE&Email=#{@email}&Passwd=#{@password}&service=ac2dm&source=push"
          headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
          uri = URI.parse(AUTH_URL)
          http = open_http(uri.host, uri.port)
          response = http.post(uri.path, data, headers)
          return response.body[/Auth=(.*)/, 1]
        end

        def notification_request(data)
          headers = { "Authorization" => "GoogleLogin auth=#{@auth_token}",
                     "Content-type" => "application/x-www-form-urlencoded",
                     "Content-length" => "#{data.length}" }
          uri = URI.parse(PUSH_URL)
          post(uri, data, headers)
        end

        def post(uri, data, headers)
          reconnect_idle if idle_period_exceeded?

          retry_count = 0

          begin
            response = @connection.post(uri.path, data, headers)
            @last_use = Time.now
          rescue EOFError, Errno::ECONNRESET, Timeout::Error => e
            retry_count += 1

            Push::Daemon.logger.error("[#{@name}] Lost connection to #{PUSH_URL} (#{e.class.name}), reconnecting ##{retry_count}...")

            if retry_count <= 3
              reconnect
              sleep 1
              retry
            else
              raise ConnectionError, "#{@name} tried #{retry_count-1} times to reconnect but failed (#{e.class.name})."
            end
          end

          response
        end

        def idle_period_exceeded?
          # Timeout on the http connection is 5 minutes, reconnect after 5 minutes
          @last_use + IDLE_PERIOD < Time.now
        end

        def reconnect_idle
          Push::Daemon.logger.info("[#{@name}] Idle period exceeded, reconnecting...")
          reconnect
        end

        def reconnect
          @connection.finish
          @last_use = Time.now
          @connection.start
        end
      end
    end
  end
end