# -*- encoding: utf-8 -*-
# stub: httpclient 2.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "httpclient".freeze
  s.version = "2.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hiroshi Nakamura".freeze]
  s.date = "2025-02-22"
  s.email = "nahi@ruby-lang.org".freeze
  s.executables = ["httpclient".freeze]
  s.files = ["bin/httpclient".freeze]
  s.homepage = "https://github.com/nahi/httpclient".freeze
  s.licenses = ["ruby".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "gives something like the functionality of libwww-perl (LWP) in Ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<mutex_m>.freeze, [">= 0"])
end
