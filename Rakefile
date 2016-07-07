require 'bundler'

require 'coveralls/rake/task'
Coveralls::RakeTask.new

task default: [:spec]

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end
