# -*- encoding: utf-8 -*-
# stub: nori 2.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "nori".freeze
  s.version = "2.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Harrington".freeze, "John Nunemaker".freeze, "Wynn Netherland".freeze]
  s.date = "2024-07-28"
  s.description = "XML to Hash translator".freeze
  s.email = "me@rubiii.com".freeze
  s.homepage = "https://github.com/savonrb/nori".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "XML to Hash translator".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.3.3"])
  s.add_development_dependency(%q<nokogiri>.freeze, [">= 1.4.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.11.0"])
end
