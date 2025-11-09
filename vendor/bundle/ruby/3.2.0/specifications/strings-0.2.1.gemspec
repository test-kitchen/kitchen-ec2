# -*- encoding: utf-8 -*-
# stub: strings 0.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "strings".freeze
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "changelog_uri" => "https://github.com/piotrmurach/strings/blob/master/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/strings", "homepage_uri" => "https://github.com/piotrmurach/strings", "source_code_uri" => "https://github.com/piotrmurach/strings" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Piotr Murach".freeze]
  s.date = "2021-03-09"
  s.description = "A set of methods for working with strings such as align, truncate, wrap and many more.".freeze
  s.email = ["piotr@piotrmurach.com".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "CHANGELOG.md".freeze, "LICENSE.txt".freeze]
  s.files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/piotrmurach/strings".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A set of methods for working with strings.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<strings-ansi>.freeze, ["~> 0.2"])
  s.add_runtime_dependency(%q<unicode_utils>.freeze, ["~> 1.4"])
  s.add_runtime_dependency(%q<unicode-display_width>.freeze, [">= 1.5", "< 3.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.0"])
end
