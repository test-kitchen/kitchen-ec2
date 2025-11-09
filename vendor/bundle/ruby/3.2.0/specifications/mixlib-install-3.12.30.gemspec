# -*- encoding: utf-8 -*-
# stub: mixlib-install 3.12.30 ruby lib

Gem::Specification.new do |s|
  s.name = "mixlib-install".freeze
  s.version = "3.12.30"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Thom May".freeze, "Patrick Wright".freeze]
  s.date = "2024-02-14"
  s.email = ["thom@chef.io".freeze, "patrick@chef.io".freeze]
  s.executables = ["mixlib-install".freeze]
  s.files = ["bin/mixlib-install".freeze]
  s.homepage = "https://github.com/chef/mixlib-install".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A library for interacting with Chef Software Inc's software distribution systems.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<mixlib-shellout>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<mixlib-versioning>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<thor>.freeze, [">= 0"])
end
