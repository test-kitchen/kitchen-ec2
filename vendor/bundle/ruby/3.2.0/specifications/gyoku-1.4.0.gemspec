# -*- encoding: utf-8 -*-
# stub: gyoku 1.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "gyoku".freeze
  s.version = "1.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Harrington".freeze]
  s.date = "2022-04-01"
  s.description = "Gyoku translates Ruby Hashes to XML".freeze
  s.email = "me@rubiii.com".freeze
  s.homepage = "https://github.com/savonrb/gyoku".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Translates Ruby Hashes to XML".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<builder>.freeze, [">= 2.1.2"])
  s.add_runtime_dependency(%q<rexml>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
end
