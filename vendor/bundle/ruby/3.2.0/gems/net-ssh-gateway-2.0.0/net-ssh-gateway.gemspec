# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'net/ssh/gateway/version'

Gem::Specification.new do |spec|
  spec.name          = "net-ssh-gateway"
  spec.version       = Net::SSH::Gateway::VERSION
  spec.authors       = ["Jamis Buck", "Delano Mandelbaum", "Mikl\u{f3}s Fazekas"]
  spec.email         = ["net-ssh@solutious.com"]

  if ENV['NET_SSH_BUILDGEM_SIGNED']
    spec.cert_chain    = ["net-ssh-public_cert.pem"]
    spec.signing_key   = "/mnt/gem/net-ssh-private_key.pem"
  end

  spec.summary       = %q{A simple library to assist in establishing tunneled Net::SSH connections}
  spec.description   = %q{A simple library to assist in establishing tunneled Net::SSH connections}
  spec.homepage      = "https://github.com/net-ssh/net-ssh-gateway"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.8.4"
  spec.add_development_dependency "mocha", ">= 1.2.1"

  spec.add_runtime_dependency "net-ssh", ">= 4.0.0"
end
