require 'em-hiredis'

module Faye
  module Reconnect
    class ClientExtension

      def self.finalize(redis)
        proc { redis&.close_connection }
      end

      def initialize redis: nil, name:, on_handshake: nil
        @name = name
        @clientIdFetched = false
        @on_handshake = on_handshake
        redis ||= {}
        redis[:host] ||= 'localhost'
        redis[:port] ||= 6379
        redis[:password] ||= ''

        @redis = EventMachine::Hiredis::Client.new(redis[:host], redis[:port], redis[:password], redis[:database])
        EM.schedule do
          @redis.connect
          @redis.client('setname', "faye-reconnect/#{name}[#{Socket.gethostname}][#{Process.pid}]")
          ObjectSpace.define_finalizer(self, self.class.finalize(@redis))
          @redis.errback do |reason|
            raise "Connection to redis failed : #{reason}"
          end
        end
      end

      def clientIdKey
        "#{@name}/client_id"
      end

      def close_redis_connection
        @redis&.close_connection
      end

      def fetch_client_id(&callback)
        if @clientIdFetched == false
          @clientIdFetched = true
          @redis.get(clientIdKey, &callback)
        else
          callback.call(nil)
        end
      end

      def set_client_id(value, &callback)
        @redis.set(clientIdKey, value, &callback).errback(&callback)
      end

      def del_client_id(&callback)
        @redis.del(clientIdKey, &callback).errback(&callback)
      end

      def outgoing(message, callback)
        if message['channel'] == '/meta/disconnect'
          del_client_id { callback.call(message) }
        elsif message['channel'] == '/meta/handshake'
          fetch_client_id do |clientId|
            message['previousClientId'] = clientId if !clientId.nil?
            # Store the clientId sent with the /meta/handshake
            @sent_client_id = clientId
            callback.call(message)
          end
        else
          callback.call(message)
        end
      end

      def incoming(message, callback)
        if message['channel'] == '/meta/handshake'
          @on_handshake&.call(previous_client_id: @sent_client_id, new_client_id: message['clientId'])
          if message['error'] == 'Already connected' && message.key?('clientId')
            message.delete('error')
            message['successful'] = true
            callback.call(message)
          else
            fetch_client_id do |clientId|
              if clientId.nil?
                set_client_id(message['clientId']) { callback.call(message) }
              else
                callback.call(message)
              end
            end
          end
        else
          callback.call(message)
        end
      end

    end
  end
end
