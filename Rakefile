require "bundler/gem_tasks"

require 'rake'
require 'rake/testtask'
require 'fileutils'

task :default => [:test_units]

Rake::TestTask.new("test_units") do |t|
  t.pattern = 'test/*.rb'
  t.verbose = false
  t.warning = false
end

desc 'Build the optional native rtsafe extension into lib/xirr'
task :compile do
  Dir.chdir('ext/xirr') { ruby 'extconf.rb'; sh 'make' }
  built = Dir['ext/xirr/xirr_native.{so,bundle}'].first
  raise 'native build produced no library (compiler missing?)' unless built
  FileUtils.cp built, 'lib/xirr/'
  puts "compiled #{File.basename(built)} -> lib/xirr/"
end
