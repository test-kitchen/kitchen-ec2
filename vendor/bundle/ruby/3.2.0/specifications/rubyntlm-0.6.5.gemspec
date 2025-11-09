# -*- encoding: utf-8 -*-
# stub: rubyntlm 0.6.5 ruby lib

Gem::Specification.new do |s|
  s.name = "rubyntlm".freeze
  s.version = "0.6.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kohei Kajimoto".freeze, "Paul Morton".freeze]
  s.date = "2024-06-12"
  s.description = "Ruby/NTLM provides message creator and parser for the NTLM authentication.".freeze
  s.email = ["koheik@gmail.com".freeze, "paul.e.morton@gmail.com".freeze]
  s.homepage = "https://github.com/winrb/rubyntlm".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Ruby/NTLM library.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<github_changelog_generator>.freeze, ["= 1.14.3"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 2.11"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<base64>.freeze, [">= 0"])
end
