require 'em-hiredis'

module Faye
  module Reconnect
    class Extension

      def initialize(options)
        @name = options[:name]
        @clientId = nil
        @clientIdFetched = false
        redis = options[:redis] || {}
        redis[:host] ||= 'localhost'
        redis[:port] ||= 6379
        redis[:password] ||= ''

        @redis = EventMachine::Hiredis::Client.new(redis[:host], redis[:port], redis[:password], redis[:database])
        EM.schedule do
          @redis.connect
          @redis.errback do |reason|
            raise "Connection to redis failed : #{reason}"
          end
        end
      end

      def clientIdKey
        "#{@name}/client_id"
      end

      def fetch_client_id(&callback)
        return callback.call(@clientId) if @clientId
        if @clientIdFetched == false
          @clientIdFetched = true
          @redis.get(clientIdKey, &callback)
        else
          callback.call(nil)
        end
      end

      def set_client_id(value, &callback)
        @redis.set(clientIdKey, value, &callback)
      end

      def del_client_id(&callback)
        @redis.del(clientIdKey, &callback)
      end

      def outgoing(message, callback)
        if message['channel'] == '/meta/disconnect'
          del_client_id { callback.call(message) }
        else
          callback.call(message)
        end
      end

      def incoming(message, callback)
        if message['channel'] == '/meta/handshake'
          fetch_client_id do |clientId|
            if clientId.nil?
              set_client_id(message['clientId']) { callback.call(message) }
            else
              message['clientId'] = clientId
              callback.call(message)
            end
          end
        else
          callback.call(message)
        end
      end

    end
  end
end
