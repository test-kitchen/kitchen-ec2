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

# Documentation is deliberately absent here: `rake yard` is run on demand, and
# CI invokes `rake test` directly, so neither docs nor doc coverage gate a build.
task default: %i{test style}
