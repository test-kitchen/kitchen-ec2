# -*- encoding: utf-8 -*-
# stub: chef-utils 18.8.54 ruby lib

Gem::Specification.new do |s|
  s.name = "chef-utils".freeze
  s.version = "18.8.54"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/chef/chef/issues", "changelog_uri" => "https://github.com/chef/chef/blob/main/CHANGELOG.md", "documentation_uri" => "https://github.com/chef/chef/tree/main/chef-utils/README.md", "homepage_uri" => "https://github.com/chef/chef/tree/main/chef-utils", "source_code_uri" => "https://github.com/chef/chef/tree/main/chef-utils" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chef Software, Inc".freeze]
  s.date = "2025-11-03"
  s.email = ["oss@chef.io".freeze]
  s.homepage = "https://github.com/chef/chef/tree/main/chef-utils".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Basic utility functions for Core Chef Infra development".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, [">= 0"])
end
