require 'faye'
require 'faye/reconnect'
require 'rspec/em'

ReconnectSteps = RSpec::EM.async_steps do

  def client(name, channels, &callback)
    @clients ||= {}
    @inboxes ||= {}
    @clients[name] = Faye::Client.new('http://localhost:9876/faye')
    @clients[name].add_extension(Faye::Reconnect::Extension.new(name: name, redis: {database: 9}))
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
      subscription.errback do |e|
        raise e.to_s
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
    @inboxes.delete(name)
    client.stop
    EM.add_timer(0.1, &callback)
  end

  def disconnect_client(name, &callback)
    client = @clients[name]
    @clients.delete(name)
    @inboxes.delete(name)
    client.disconnect
    EM.add_timer(0.1, &callback)
  end

  def flushdb(&callback)
    @clients = {}
    @inboxes = {}
    @redis = EventMachine::Hiredis::Client.new('localhost', 6379, '', 9)
    @redis.connect
    @redis.errback do |reason|
      raise "Connection to redis failed : #{reason}"
    end
    @redis.flushdb(&callback)
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

  def wait(time, &callback)
    EM.add_timer(time, &callback)
  end

end

describe Faye::Reconnect do
  include ReconnectSteps

  before { launch_server }
  before { flushdb }

  it 'fetches messages sent while disconnected' do
    client 'foo', ['/foo']
    client 'bar', ['/bar']
    kill_client 'foo'
    publish 'bar', '/foo', {'hello' => 'world'}
    client 'foo', ['/foo']
    wait 0.2
    check_inbox 'foo', '/foo', [{'hello' => 'world'}]
  end

  it 'does not re-use clientId when issuing a legal disconnect' do
    client 'foo', ['/foo']
    client 'bar', ['/bar']
    disconnect_client 'foo'
    publish 'bar', '/foo', {'hello' => 'world'}
    client 'foo', ['/foo']
    wait 0.2
    check_inbox 'foo', '/foo', []
  end

  it 'is scoped by name' do
    client 'foo', ['/foo']
    client 'baz', ['/baz']
    client 'bar', ['/bar']
    kill_client 'foo'
    kill_client 'baz'
    publish 'bar', '/foo', {'hello' => 'foo'}
    publish 'bar', '/baz', {'hello' => 'baz'}
    client 'foo', ['/foo']
    client 'baz', ['/baz']
    wait 0.2
    check_inbox 'foo', '/foo', [{'hello' => 'foo'}]
    check_inbox 'baz', '/baz', [{'hello' => 'baz'}]
  end

end
