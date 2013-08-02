require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'

# load bundler's gem publishing tasks
Bundler::GemHelper.install_tasks

# load rspec testing task (default)
RSpec::Core::RakeTask.new("spec")
task :default => "spec"