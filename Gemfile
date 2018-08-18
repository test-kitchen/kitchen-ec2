source "https://rubygems.org"

# Specify your gem"s dependencies in kitchen-ec2.gemspec
gemspec

gem "winrm-fs"

group :test do
  gem "rake"
  gem "pry"
  gem "test-kitchen", ">= 1.23" # defined here and in the gemspec to match sure we have lifecycle hooks for testing
end

group :changelog do
  gem "github_changelog_generator"
end
