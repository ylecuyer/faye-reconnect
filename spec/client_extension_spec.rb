require 'faye'
require 'faye/reconnect'
require 'spec_helper'

describe Faye::Reconnect::ClientExtension do
  it 'requires a name option' do
    expect {
      Faye::Reconnect::ClientExtension.new
    }.to raise_error(ArgumentError, "missing keyword: name")
    expect {
      Faye::Reconnect::ClientExtension.new(name: 'foobar')
    }.to_not raise_error
  end

  describe '#close_redis_connection' do
    it 'calls #close_connection on the redis client' do
      faye_reconnect = Faye::Reconnect::ClientExtension.new(name: 'foobar')
      expect_any_instance_of(EventMachine::Hiredis::Client).to receive(:close_connection).and_return(true)
      faye_reconnect.close_redis_connection
    end
  end
end
