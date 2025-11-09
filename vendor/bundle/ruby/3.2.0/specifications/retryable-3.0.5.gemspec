# -*- encoding: utf-8 -*-
# stub: retryable 3.0.5 ruby lib

Gem::Specification.new do |s|
  s.name = "retryable".freeze
  s.version = "3.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/nfedyashev/retryable/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/nfedyashev/retryable/tree/master" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nikita Fedyashev".freeze, "Carlo Zottmann".freeze, "Chu Yeow".freeze]
  s.date = "2019-11-11"
  s.description = "Retrying code blocks in Ruby".freeze
  s.email = ["nfedyashev@gmail.com".freeze]
  s.homepage = "http://github.com/nfedyashev/retryable".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Retrying code blocks in Ruby".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
end
