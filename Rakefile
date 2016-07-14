require 'bundler'

Dir.glob('lib/tasks/*.rake').each { |r| load r }

require 'coveralls/rake/task'
Coveralls::RakeTask.new

task default: [:spec]

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  puts 'RSpec is not available'
end
