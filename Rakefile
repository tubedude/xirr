require "bundler/gem_tasks"

require 'rake'
require 'rake/testtask'

task :default => [:test_units]

Rake::TestTask.new("test_units") do |t|
  t.pattern = 'test/*.rb'
  t.verbose = false
  t.warning = false
end
