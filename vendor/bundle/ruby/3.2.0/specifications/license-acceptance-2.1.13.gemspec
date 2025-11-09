# -*- encoding: utf-8 -*-
# stub: license-acceptance 2.1.13 ruby lib

Gem::Specification.new do |s|
  s.name = "license-acceptance".freeze
  s.version = "2.1.13"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["tyler-ball".freeze]
  s.date = "2020-12-07"
  s.description = "Chef End User License Agreement Acceptance for Ruby products".freeze
  s.email = ["tball@chef.io".freeze]
  s.homepage = "https://github.com/chef/license-acceptance/".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Chef End User License Agreement Acceptance".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<pastel>.freeze, ["~> 0.7"])
  s.add_runtime_dependency(%q<tomlrb>.freeze, [">= 1.2", "< 3.0"])
  s.add_runtime_dependency(%q<tty-box>.freeze, ["~> 0.6"])
  s.add_runtime_dependency(%q<tty-prompt>.freeze, ["~> 0.20"])
end
