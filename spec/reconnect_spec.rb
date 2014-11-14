require 'faye'
require 'faye/reconnect'
require 'rspec/em'

ReconnectSteps = RSpec::EM.async_steps do

  def client(name, channels, &callback)
    @clients ||= {}
    @inboxes ||= {}
    @clients[name] = Faye::Client.new('http://localhost:9876/faye')
    @inboxes[name] = {}

    n = channels.size
    return @clients[name].connect(&callback) if n.zero?

    channels.each do |channel|
      subscription = @clients[name].subscribe(channel) do |message|
        @inboxes[name][channel] ||= []
        @inboxes[name][channel] << message
      end
      subscription.callback do
        n -= 1
        callback.call if n.zero?
      end
    end
  end

  def publish(name, channel, message, &callback)
    @clients[name].publish(channel, message)
    EM.add_timer(0.1, &callback)
  end

  def check_inbox(name, channel, messages, &callback)
    inbox = @inboxes[name][channel] || []
    expect(inbox).to eq(messages)
    callback.call
  end

  def kill_client(name, &callback)
    client = @clients[name]
    @clients.delete(name)
    client.instance_variable_get(:@dispatcher).close
    client.instance_variable_set(:@state, Faye::Client::DISCONNECTED)
    EM.add_timer(0.1, &callback)
  end

  def flushdb(&callback)
    @clients = {}
    @inboxes = {}
    callback.call
  end

  def launch_server(&callback)
    Faye::WebSocket.load_adapter('thin')
    app = Faye::RackAdapter.new(:mount => '/faye', :timeout => 25)
    Thin::Logging.silent = true
    @server = Thin::Server.new('127.0.0.1', 9876, app)
    @server.start
    callback.call
  end

  def stop_server(&callback)
    @server.stop
    # Hack EM to stop the timers
    EM.instance_variable_get(:@timers).each { |t,_| EM.cancel_timer(t) }
    EM.add_timer(0.1, &callback)
  end

end

describe Faye::Reconnect do
  include ReconnectSteps

  before { launch_server }
  before { flushdb }

  it 'fetches messages sent while disconnected' do
    client 'foo', ['/foo']
    client 'bar', []
    kill_client 'foo'
    publish 'bar', 'foo', {'hello' => 'world'}
    client 'foo', ['/foo']
    check_inbox 'foo', '/foo', [{'hello' => 'world'}]
  end

end
