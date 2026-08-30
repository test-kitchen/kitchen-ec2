require "bundler/gem_tasks"
require "rspec/core/rake_task"

desc "Run the unit tests"
RSpec::Core::RakeTask.new(:test)

begin
  require "cookstyle/chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "cookstyle/chefstyle is not available. (sudo) gem install cookstyle to do style checking."
end

begin
  require "yard"

  YARD::Rake::YardocTask.new(:yard) do |task|
    task.stats_options = ["--list-undoc"]
  end

  namespace :yard do
    desc "Report documentation coverage and list undocumented objects"
    task :stats do
      sh "yard stats --list-undoc"
    end

    desc "Serve the documentation locally, reloading as files change"
    task :serve do
      sh "yard server --reload"
    end
  end
rescue LoadError
  puts "yard is not available. (sudo) gem install yard to generate documentation."
end

# Test Kitchen suites that launch real EC2 instances.
#
# Deliberately not wired into `default`: these cost money and need credentials.
# See integration/README.md.
namespace :integration do
  # Run from the repository root with the integration config, so that the
  # `integration/...` paths in it resolve and `.kitchen/` stays in one place.
  def kitchen(command, args)
    sh({ "KITCHEN_YAML" => "integration/kitchen.yml" },
      "bundle", "exec", "kitchen", command, *args)
  end

  desc "List the integration suites (kitchen list [PATTERN])"
  task :list, [:pattern] do |_t, args|
    kitchen("list", Array(args[:pattern]))
  end

  desc "Create, converge, verify and destroy the integration suites (kitchen test [PATTERN])"
  task :test, [:pattern] do |_t, args|
    kitchen("test", Array(args[:pattern]))
  end

  desc "Create the integration suites without converging them (kitchen create [PATTERN])"
  task :create, [:pattern] do |_t, args|
    kitchen("create", Array(args[:pattern]))
  end

  desc "Converge the integration suites, leaving them running (kitchen converge [PATTERN])"
  task :converge, [:pattern] do |_t, args|
    kitchen("converge", Array(args[:pattern]))
  end

  # The one task worth running on its own after a failure: `kitchen test` tears
  # down on success, but a suite that failed leaves its instance running and
  # billing until this is run.
  desc "Destroy every integration instance (kitchen destroy [PATTERN])"
  task :destroy, [:pattern] do |_t, args|
    kitchen("destroy", Array(args[:pattern]))
  end
end

# Documentation is deliberately absent here: `rake yard` is run on demand, and
# CI invokes `rake test` directly, so neither docs nor doc coverage gate a build.
task default: %i{test style}
