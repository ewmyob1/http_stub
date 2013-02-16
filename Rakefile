require 'bundler'
require 'rspec/core/rake_task'
require File.expand_path('../lib/http/stub/start_server_rake_task', __FILE__)

directory "pkg"

Bundler::GemHelper.install_tasks

desc "Removed generated artefacts"
task :clobber do
  %w{ coverage pkg }.each { |dir| rm_rf dir }
  rm Dir.glob("**/coverage.data"), force: true
  puts "Clobbered"
end

desc "Complexity analysis"
task :metrics do
  print " Complexity Metrics ".center(80, "*") + "\n"
  print `find lib -name \\*.rb | xargs flog --continue`
  print "*" * 80+ "\n"
end

desc "Exercises specifications"
::RSpec::Core::RakeTask.new(:spec)

desc "Exercises specifications with coverage analysis"
task :coverage => "coverage:generate"

namespace :coverage do

  desc "Shows specification coverage results in browser"
  task :show => :spec do
    require 'cover_me'
    CoverMe.complete!
  end

  desc "Generates specification coverage results"
  task :generate => :spec do
    require 'cover_me'
    CoverMe.config.at_exit = Proc.new {
      index = File.join(CoverMe.config.html_formatter.output_path, 'index.html')
      print " Coverage Analysis ".center(80, "*") + "\n"
      print "Report: #{index}\n"
      print "*" * 80+ "\n"
    }
    CoverMe.complete!
  end

end

task :validate do
  print " Travis CI Validation ".center(80, "*") + "\n"
  result = `travis-lint #{File.expand_path('../travis.yml', __FILE__)}`
  puts result
  print "*" * 80+ "\n"
  raise "Travis CI validation failed" unless result =~ /^Hooray/
end

Http::Stub::StartServerRakeTask.new(name: :test_server, port: 8001)

task :default => [:clobber, :metrics, :coverage]

task :pre_commit => [:clobber, :metrics, "coverage:show", :validate]
