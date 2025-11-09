require 'rake/testtask'
require 'rubygems/package_task'
require 'bundler/gem_tasks'
require 'rake/extensiontask'
require 'rake/clean'
require 'rdoc/task'
require 'benchmark'
require 'rake_compiler_dock'

CLEAN.add("{ext,lib}/**/*.{o,so}", "pkg")

cross_rubies = ["3.3.0", "3.2.0", "3.1.0", "3.0.0", "2.7.0"]
cross_platforms = [
  "arm64-darwin",
  "x64-mingw-ucrt",
  "x64-mingw32",
  "x86-mingw32",
  "x86_64-darwin",
]
ENV["RUBY_CC_VERSION"] = cross_rubies.join(":")

GEMSPEC = Gem::Specification.load("bcrypt_pbkdf.gemspec")

task :default => [:compile, :spec]

desc "Run all tests"
Rake::TestTask.new do |t|
  #t.pattern =
  t.test_files = FileList['test/**/*_test.rb']
  t.ruby_opts = ['-w']
  t.libs << "test"
  t.verbose = true
end
task :spec => :test

desc 'Generate RDoc'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options += GEMSPEC.rdoc_options
  rdoc.template = ENV['TEMPLATE'] if ENV['TEMPLATE']
  rdoc.rdoc_files.include(*GEMSPEC.extra_rdoc_files)
end

Rake::ExtensionTask.new("bcrypt_pbkdf_ext", GEMSPEC) do |ext|
  ext.ext_dir = 'ext/mri'
  ext.cross_compile = true
  ext.cross_platform = cross_platforms
  ext.cross_config_options << "--enable-cross-build" # so extconf.rb knows we're cross-compiling
end

namespace "gem" do
  cross_platforms.each do |platform|
    desc "build native gem for #{platform}"
    task platform do
      RakeCompilerDock.sh(<<~EOF, platform: platform, verbose: true)
        gem install bundler --no-document &&
        BUNDLE_IGNORE_CONFIG=1 BUNDLE_PATH=.bundle/#{platform} bundle &&
        BUNDLE_IGNORE_CONFIG=1 BUNDLE_PATH=.bundle/#{platform} bundle exec rake gem:#{platform}:buildit
      EOF
    end

    namespace platform do
      # this runs in the rake-compiler-dock docker container
      task "buildit" do
        # use Task#invoke because the pkg/*gem task is defined at runtime
        Rake::Task["native:#{platform}"].invoke
        Rake::Task["pkg/#{GEMSPEC.full_name}-#{Gem::Platform.new(platform)}.gem"].invoke
      end

      task "release" do
        sh "gem push pkg/#{GEMSPEC.full_name}-#{Gem::Platform.new(platform)}.gem"
      end
    end
  end

  desc "build native gem for all platforms"
  task "all" do
    cross_platforms.each do |platform|
      Rake::Task["gem:#{platform}"].invoke
    end
  end

  desc "release native gem for all platforms"
  task "release" do
    cross_platforms.each do |platform|
      Rake::Task["gem:#{platform}:release"].invoke
    end
  end
end

def change_version(&block)
  version = GEMSPEC.version
  version_file = 'bcrypt_pbkdf.gemspec'
  raise "No version found" if version.nil?
  final = version.segments.take_while{ |i| i.is_a?(Integer) }.to_a
  pre = version.segments.drop_while{ |i| i.is_a?(Integer) }.to_a.join("")
  pre = nil if pre.empty?
  tiny = final.last
  result = block[pre: pre, tiny: tiny]
  raise ArgumentError, "Version change logic should always return a pre" unless result.key?(:pre)

  puts "result: #{result.inspect}"

  new_pre = result[:pre] || []
  new_tiny = result[:tiny] || tiny
  final[-1] = new_tiny
  new_version = Gem::Version.new([final, *new_pre].join("."))

  found = false
  File.open("#{version_file}.new", "w") do |f|
    File.readlines(version_file).each do |line|
      match = /^(\s+s\.version\s*=\s*\')[\d[a-z]\.]+(\'\s*)$/.match(line)
      if match
        prefix = match[1]
        postfix = match[2]
        new_line = "#{prefix}#{new_version.to_s}#{postfix}"
        puts "Changing:\n  - #{line}  + #{new_line}"
        line = new_line
        found = true
      end
      f.write(line)
    end
    raise ArgumentError, "Cound not find version line in #{version_file}" unless found
  end

  FileUtils.mv version_file, "#{version_file}.old"
  FileUtils.mv "#{version_file}.new", version_file
  FileUtils.rm_f "#{version_file}.old"
end

namespace :vbump do
  desc "Final release"
  task :final do
    change_version do |pre:, tiny:|
      _ = tiny
      if pre.nil?
        { tiny: tiny + 1, pre: nil }
      else
        raise ArgumentError, "Unexpected pre: #{pre}" if pre.nil?

        { pre: nil }
      end
    end
  end

  desc "Increment prerelease"
  task :pre, [:type] do |_t, args|
    change_version do |pre:, tiny:|
      puts " PRE => #{pre.inspect}"
      match = /^([a-z]+)(\d+)/.match(pre)
      raise ArgumentError, "Unexpected pre: #{pre}" if match.nil? && args[:type].nil?

      if match.nil? || (!args[:type].nil? && args[:type] != match[1])
        if pre.nil?
          { pre: "#{args[:type]}1", tiny: tiny + 1 }
        else
          { pre: "#{args[:type]}1" }
        end
      else
        { pre: "#{match[1]}#{match[2].to_i + 1}" }
      end
    end
  end
end

task "package" => cross_platforms.map { |p| "gem:#{p}" } # "package" task for all the native platforms

Rake::Task["package"].prerequisites.prepend("compile")
