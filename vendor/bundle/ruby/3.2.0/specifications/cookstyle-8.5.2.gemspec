# -*- encoding: utf-8 -*-
# stub: cookstyle 8.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "cookstyle".freeze
  s.version = "8.5.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/chef/cookstyle/issues", "changelog_uri" => "https://github.com/chef/cookstyle/blob/main/CHANGELOG.md", "documentation_uri" => "https://docs.chef.io/workstation/cookstyle/", "homepage_uri" => "https://github.com/chef/cookstyle", "source_code_uri" => "https://github.com/chef/cookstyle" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Thom May".freeze, "Tim Smith".freeze]
  s.date = "2025-10-27"
  s.email = ["thom@chef.io".freeze, "tsmith84@gmail.com".freeze]
  s.executables = ["cookstyle".freeze]
  s.files = ["bin/cookstyle".freeze]
  s.homepage = "https://docs.chef.io/workstation/cookstyle/".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Cookstyle is a code linting tool that helps you to write better Chef Infra cookbooks by detecting and automatically correcting style, syntax, and logic mistakes in your code.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rubocop>.freeze, ["= 1.81.6"])
end
