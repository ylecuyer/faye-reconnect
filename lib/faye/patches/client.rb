module Faye
  module Patches

    def stop
      return unless @state == Faye::Client::CONNECTED
      @state = Faye::Client::DISCONNECTED

      info('Disconnecting ?', @dispatcher.client_id)
      @dispatcher.close
      info('Clearing channel listeners for ?', @dispatcher.client_id)
      @channels = Channel::Set.new
      true
    end

    def reconnect(&block)
      @reconnect_callback = block
      connect
    end

    def receive_message(message)
      res = super(message)
      if @reconnect_callback && message['channel'] == '/meta/connect' && message.has_key?('successful')
        @reconnect_callback.call
      end
      res
    end

  end
end

Faye::Client.send(:prepend, Faye::Patches)
