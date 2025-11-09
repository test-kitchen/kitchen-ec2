# frozen_string_literal: true
source 'https://rubygems.org'

# Specify your gem's dependencies in cookstyle.gemspec
gemspec
gem 'appbundler'
group :debug do
  gem 'pry'
end

group :docs do
  gem 'yard'
end

group :profiling do
  platforms :ruby do
    gem 'memory_profiler'
    gem 'stackprof'
  end
end

group :development do
  gem 'rake'
  gem 'rspec', '>= 3.4'
end
