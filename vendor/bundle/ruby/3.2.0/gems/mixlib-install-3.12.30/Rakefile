require "bundler/gem_tasks"
require "rspec/core/rake_task"

[:unit, :functional].each do |type|
  RSpec::Core::RakeTask.new(type) do |t|
    t.pattern = "spec/#{type}/**/*_spec.rb"
    t.rspec_opts = [].tap do |a|
      a.push("--color")
      a.push("--format progress")
    end.join(" ")
  end
end

begin
  require "chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "chefstyle gem is not installed"
end

desc "Render product matrix documentation"
task "matrix" do
  require "mixlib/install/product_matrix"

  doc_file = File.join(File.dirname(__FILE__), "PRODUCT_MATRIX.md")
  puts "Updating doc file at: #{doc_file}"

  File.open(doc_file, "w+") do |f|
    f.puts("| Product | Product Key  |")
    f.puts("| ------- | ------------ |")
    PRODUCT_MATRIX.products.sort.each do |p_key|
      product = PRODUCT_MATRIX.lookup(p_key)
      f.puts("| #{product.product_name} | #{p_key} |")
    end
    f.puts("")
    f.puts("Do not modify this file manually. It is automatically rendered via a rake task.")
  end
end

task :console do
  require "irb"
  require "irb/completion"
  require "mixlib/install"
  ARGV.clear
  IRB.start
end

task default: %w{unit functional}
