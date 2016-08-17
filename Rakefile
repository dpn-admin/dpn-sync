require 'bundler'
Bundler.require

# Tasks
Dir.glob('lib/tasks/*.rake').each { |r| load r }

task default: [:spec]

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  puts 'RSpec is not available' if ENV['RACK_ENV'] == 'test'
end
