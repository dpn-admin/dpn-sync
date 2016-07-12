server 'dpn-dev.stanford.edu', user: 'dpn', roles: %w(app db web)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'development'
set :bundle_without, 'test'

