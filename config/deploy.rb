# config valid only for current version of Capistrano
lock '3.6.0'

set :application, 'dpn_sync'
set :repo_url, 'https://github.com/dpn-admin/dpn-sync.git'

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/opt/app/dpn/dpn-sync'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set :linked_files, fetch(:linked_files, []).push(
  'config/redis.yml',
  'config/settings/development.yml',
  'config/settings.yml',
  'config/sidekiq_schedule.yml'
)

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

##
# https://github.com/seuros/capistrano-sidekiq#usage
# Sidekiq defaults and explicit settings
# See also config/sidekiq.yml
#
# :sidekiq_default_hooks => true
# :sidekiq_pid => File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid')
# :sidekiq_env => fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
# :sidekiq_log => File.join(shared_path, 'log', 'sidekiq.log')
# :sidekiq_options => nil
set :sidekiq_require, -> { File.join(current_path, 'config', 'initializers', 'sidekiq.rb') }
# :sidekiq_tag => nil
set :sidekiq_config, -> { File.join(current_path, 'config', 'sidekiq.yml') }
# :sidekiq_queue => nil
# :sidekiq_timeout => 10
# :sidekiq_role => :app
# set :sidekiq_processes, 2
# set :sidekiq_options_per_process, ["--queue sync_bags", "--queue sync_nodes"]
# :sidekiq_concurrency => nil
# :sidekiq_service_name => "sidekiq_#{fetch(:application)}_#{fetch(:sidekiq_env)}"
# :sidekiq_user => nil #user to run sidekiq as
