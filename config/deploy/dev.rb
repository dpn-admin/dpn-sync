server 'dpn-dev.stanford.edu', user: 'dpn', roles: %w(app db web)

Capistrano::OneTimeKey.generate_one_time_key!

set :rails_env, 'production'

# https://github.com/capistrano/bundler options.
# These are the default values, unless indicated otherwise.
# set :bundle_roles, :all
# set :bundle_servers, -> { release_roles(fetch(:bundle_roles)) }
set :bundle_binstubs, -> { shared_path.join('bin') } # default: nil
# set :bundle_gemfile, -> { release_path.join('MyGemfile') } # default: nil
# this is the default for :bundle_path, use nil to skip the --path flag.
# set :bundle_path, -> { shared_path.join('bundle') }
# set :bundle_without, %w{development test}.join(' ')
# set :bundle_flags, '--deployment --quiet'
# set :bundle_env_variables, {}
