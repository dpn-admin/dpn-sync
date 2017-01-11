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

begin
  spec = Gem::Specification.find_by_name 'app_version_tasks'
  load "#{spec.gem_dir}/lib/tasks/app_version_tasks.rake"
  require 'app_version_tasks'
  AppVersionTasks.configure do |config|
    cwd = File.expand_path(File.dirname(__FILE__))
    config.application_name = 'DpnSync'
    config.git_working_directory = cwd
    config.version_file_path = File.join(cwd, 'app', 'dpn_sync.rb')
  end
rescue LoadError
  puts 'app_version_tasks is not available' if ENV['RACK_ENV'] == 'development'
end
