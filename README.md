# Faye::Reconnect

This extension allows a faye client to retrieve its client id when restarting, after a crash, etc; thus retrieving all the messages addresses to it sent during the disconnection.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faye-reconnect'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install faye-reconnect

## Usage

To require it in your application :

```ruby
require 'faye/reconnect'
```

``Faye::Reconnect`` is actually two faye extensions, one for the Faye server and one for the clients.

### Server Side

You just need to add the extension and pass your faye server to it :

```ruby
server = Faye::RackAdapter.new(:mount => '/faye', :timeout => 15)
server.add_extension Faye::Reconnect::ServerExtension.new(server)
```

### Client Side

The client extension has a dependency on redis. 
It uses redis to persist the client id after each successful handshake so it can re-use it when trying to reconnect.

Add the extension to your faye client :

```ruby
client = Faye::Client.new('http://localhost:9292/faye')
client.add_extension Faye::Reconnect::ClientExtension.new({
        name: 'your_client_name',
        redis: {
            host: 'localhost',
            port: 6379,
            password: '',
            database: 0
        }
    })
```

``:name`` is mandatory, it is used to distinct clients.

If you don't specify redis options, the ones provided in the above example will be used.

### Shutting down and catching signals

You may already have something along the lines of :

```ruby
trap('TERM') do 
    client.disconnect
end
```

If you plan on reconnecting with the same client id and get missing messages, you have to use the ``stop!`` method provided by this gem :

```ruby
trap('TERM') do 
    client.stop!
end
```

Instead of sending a ``/meta/disconnect`` message to the server, it will cleanly stop the Event Machine reactor, so the faye server is not aware you are disconnected and it will keep incoming messages until you handshake again.


## Contributing

1. Fork it ( https://github.com/dimelo/faye-reconnect/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
