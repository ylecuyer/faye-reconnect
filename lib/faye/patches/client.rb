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

  end
end

Faye::Client.send(:include, Faye::Patches)
