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

end
