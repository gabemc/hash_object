$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift File.expand_path("../spec", __FILE__)

require 'rubygems'
require 'fileutils'
require 'rspec/core/rake_task'

task :default => :spec

desc "Run the RSpec tests"
RSpec::Core::RakeTask.new(:spec) 

desc "Cleans the gem files up."
task :clean => ['gem:clean']

desc "Show the documentation"
task :doc => ['doc:yardoc']
namespace :doc do
  desc "Build the documentation"
  task :gen do
    sh "yardoc"
  end

  desc "Open the docs in a browser" 
  task :view => :gen do
    sh "open doc/_index.html"
  end

  desc "Cleans up the doc directory"
  task :clean do 
    sh "rm -rf doc"
  end
end

