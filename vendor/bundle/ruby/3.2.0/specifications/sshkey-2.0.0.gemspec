# -*- encoding: utf-8 -*-
# stub: sshkey 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "sshkey".freeze
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["James Miller".freeze]
  s.date = "2019-02-11"
  s.description = "Generate private/public SSH keypairs using pure Ruby".freeze
  s.email = ["bensie@gmail.com".freeze]
  s.homepage = "https://github.com/bensie/sshkey".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "SSH private/public key generator in Ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
end
