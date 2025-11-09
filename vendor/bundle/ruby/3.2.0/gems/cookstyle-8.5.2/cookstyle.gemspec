# frozen_string_literal: true
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cookstyle/version'

Gem::Specification.new do |spec|
  spec.name          = 'cookstyle'
  spec.version       = Cookstyle::VERSION
  spec.authors       = ['Thom May', 'Tim Smith']
  spec.email         = ['thom@chef.io', 'tsmith84@gmail.com']
  spec.summary       = 'Cookstyle is a code linting tool that helps you to write better Chef Infra cookbooks by detecting and automatically correcting style, syntax, and logic mistakes in your code.'
  spec.license       = 'Apache-2.0'
  spec.homepage      = 'https://docs.chef.io/workstation/cookstyle/'
  spec.required_ruby_version = '>= 2.7'

  # the gemspec and Gemfile are necessary for appbundling of the gem
  spec.files = %w(LICENSE cookstyle.gemspec Gemfile) + Dir.glob('{lib,bin,config}/**/*')
  spec.executables = %w(cookstyle)
  spec.require_paths = ['lib']

  spec.add_dependency('rubocop', Cookstyle::RUBOCOP_VERSION)

  spec.metadata = {
    'homepage_uri' => 'https://github.com/chef/cookstyle',
    'changelog_uri' => 'https://github.com/chef/cookstyle/blob/main/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/chef/cookstyle',
    'documentation_uri' => 'https://docs.chef.io/workstation/cookstyle/',
    'bug_tracker_uri' => 'https://github.com/chef/cookstyle/issues',
  }
end
