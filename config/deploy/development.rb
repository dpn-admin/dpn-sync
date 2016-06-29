server 'dpn-dev.stanford.edu', user: 'dpn', roles: %w(app db web)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'development'
set :bundle_without, 'test'

##
# Sidekiq defaults:
#
# :sidekiq_default_hooks => true
# :sidekiq_pid => File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid')
# :sidekiq_env => fetch(:rack_env, fetch(:rails_env, fetch(:stage)))
# :sidekiq_log => File.join(shared_path, 'log', 'sidekiq.log')
# :sidekiq_options => nil
# :sidekiq_require => nil
# :sidekiq_tag => nil
# :sidekiq_config => nil # if you have a config/sidekiq.yml, do not forget to set this.
# :sidekiq_queue => nil
# :sidekiq_timeout => 10
# :sidekiq_role => :app
# :sidekiq_processes => 1
# :sidekiq_options_per_process => nil
# :sidekiq_concurrency => nil
# :sidekiq_monit_templates_path => 'config/deploy/templates'
# :sidekiq_monit_conf_dir => '/etc/monit/conf.d'
# :sidekiq_monit_use_sudo => true
# :monit_bin => '/usr/bin/monit'
# :sidekiq_monit_default_hooks => true
# :sidekiq_service_name => "sidekiq_#{fetch(:application)}_#{fetch(:sidekiq_env)}"
# :sidekiq_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiq" # Only for capistrano2.5
# :sidekiqctl_cmd => "#{fetch(:bundle_cmd, "bundle")} exec sidekiqctl" # Only for capistrano2.5
# :sidekiq_user => nil #user to run sidekiq as
