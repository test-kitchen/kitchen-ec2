# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mixlib/install/version"

Gem::Specification.new do |spec|
  spec.name          = "mixlib-install"
  spec.version       = Mixlib::Install::VERSION
  spec.authors       = ["Thom May", "Patrick Wright"]
  spec.email         = ["thom@chef.io", "patrick@chef.io"]
  spec.license       = "Apache-2.0"

  spec.summary       = "A library for interacting with Chef Software Inc's software distribution systems."
  spec.homepage      = "https://github.com/chef/mixlib-install"

  spec.files         = %w{LICENSE Gemfile Rakefile} + Dir.glob("*.gemspec") + Dir.glob("{bin,lib,support}/**/*")
  spec.executables   = ["mixlib-install"]
  spec.require_paths = ["lib"]

  spec.add_dependency "mixlib-shellout"
  spec.add_dependency "mixlib-versioning"
  spec.add_dependency "thor"
end
