# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'faye/reconnect/version'

Gem::Specification.new do |spec|
  spec.name          = "faye-reconnect"
  spec.version       = Faye::Reconnect::VERSION
  spec.authors       = ["Adrien Jarthon", "Adrien Siami"]
  spec.email         = ["jobs@adrienjarthon.com"]
  spec.summary       = "Allow a long running faye client to reconnect to a faye server with the same client ID"
  spec.description   = "Allow a long running faye client to reconnect to a faye server with the same client ID"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'em-hiredis', '~> 0.3'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-eventmachine'
  spec.add_development_dependency 'thin'
  spec.add_development_dependency 'pry-byebug'

end
