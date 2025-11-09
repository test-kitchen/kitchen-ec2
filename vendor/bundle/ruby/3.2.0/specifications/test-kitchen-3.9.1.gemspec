# -*- encoding: utf-8 -*-
# stub: test-kitchen 3.9.1 ruby lib

Gem::Specification.new do |s|
  s.name = "test-kitchen".freeze
  s.version = "3.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Fletcher Nichol".freeze]
  s.date = "2025-10-17"
  s.description = "Test Kitchen is an integration tool for developing and testing infrastructure code and software on isolated target platforms.".freeze
  s.email = ["fnichol@nichol.ca".freeze]
  s.executables = ["kitchen".freeze]
  s.files = ["bin/kitchen".freeze]
  s.homepage = "https://kitchen.ci/".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Test Kitchen is an integration tool for developing and testing infrastructure code and software on isolated target platforms.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<bcrypt_pbkdf>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<chef-utils>.freeze, [">= 16.4.35"])
  s.add_runtime_dependency(%q<csv>.freeze, ["~> 3.3"])
  s.add_runtime_dependency(%q<ed25519>.freeze, ["~> 1.3"])
  s.add_runtime_dependency(%q<irb>.freeze, ["~> 1.15"])
  s.add_runtime_dependency(%q<mixlib-install>.freeze, ["~> 3.6"])
  s.add_runtime_dependency(%q<mixlib-shellout>.freeze, [">= 1.2", "< 4.0"])
  s.add_runtime_dependency(%q<net-scp>.freeze, [">= 1.1", "< 5.0"])
  s.add_runtime_dependency(%q<net-ssh>.freeze, [">= 2.9", "< 8.0"])
  s.add_runtime_dependency(%q<net-ssh-gateway>.freeze, [">= 1.2", "< 3.0"])
  s.add_runtime_dependency(%q<ostruct>.freeze, ["~> 0.6"])
  s.add_runtime_dependency(%q<syslog>.freeze, ["~> 0.3"])
  s.add_runtime_dependency(%q<thor>.freeze, [">= 0.19", "< 2.0"])
  s.add_runtime_dependency(%q<winrm>.freeze, ["~> 2.0"])
  s.add_runtime_dependency(%q<winrm-elevated>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<winrm-fs>.freeze, ["~> 1.1"])
  s.add_runtime_dependency(%q<license-acceptance>.freeze, [">= 1.0.11", "< 3.0"])
end
