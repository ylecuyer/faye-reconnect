module Faye
  module Reconnect
    class ServerExtension

      def initialize(app)
        @server = app.instance_variable_get(:@server)
      end

      def incoming(message, callback)
        if message.key?('previousClientId')
          client_id = message['previousClientId']
          @server.engine.client_exists(client_id) do |exists|
            if exists
              @server.engine.ping(client_id)
              message['clientId'] = client_id
              message['error'] = 'Already connected'
            end
            callback.call(message)
          end
        else
          callback.call(message)
        end
      end

    end
  end
end
