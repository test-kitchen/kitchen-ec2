# -*- encoding: utf-8 -*-

require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:test)

desc "Display LOC stats"
task :stats do
  puts "\n## Production Code Stats"
  sh "countloc -r lib/kitchen lib/kitchen.rb"
  puts "\n## Test Code Stats"
  sh "countloc -r spec features"
end

require "chefstyle"
require "rubocop/rake_task"
RuboCop::RakeTask.new(:style) do |task|
  task.options << "--display-cop-names"
end

desc "Run all quality tasks"
task :quality => [:style, :stats]

require "yard"
YARD::Rake::YardocTask.new

begin
  task :default => [:test, :quality]

  require "github_changelog_generator/task"
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.future_release = Kitchen::Driver::EC2_VERSION
    config.enhancement_labels = "enhancement,Enhancement,New Feature,Feature".split(",")
    config.bug_labels = "bug,Bug,Improvement".split(",")
    config.exclude_labels = "duplicate,question,invalid,wontfix,no_changelog," \
                            ",Exclude From Changelog,Question,Upstream Bug,Discussion".split(",")
  end
rescue LoadError
  task :changelog do
    raise "github_changelog_generator not installed! gem install github_changelog_generator."
  end
end
