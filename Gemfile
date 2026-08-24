source "https://rubygems.org"

# Specify your gem's dependencies in kitchen-ec2.gemspec
gemspec

group :test do
  gem "rake", ">= 11.0"
  gem "rspec", "~> 3.2"
end

# Documentation tooling. CI runs the unit tests with BUNDLE_WITHOUT=development,
# so yard is not installed there and the Rakefile's yard tasks simply do not
# load -- documentation never gates a build.
group :development do
  gem "yard", ">= 0.9"
end

group :cookstyle do
  gem "cookstyle", "~> 8.1"
end
