require 'config'
Config.setup do |config|
  # Name of the constant exposing loaded settings
  config.const_name = 'SyncSettings'

  # Ability to remove elements of the array set in earlier loaded settings file. For example value: '--'.
  #
  # config.knockout_prefix = nil

  # Load environment variables from the `ENV` object and override any settings defined in files.
  #
  # config.use_env = false

  # Define ENV variable prefix deciding which variables to load into config.
  #
  # config.env_prefix = 'Settings'

  # What string to use as level separator for settings loaded from ENV variables. Default value of '.' works well
  # with Heroku, but you might want to change it for example for '__' to easy override settings from command line, where
  # using dots in variable names might not be allowed (eg. Bash).
  #
  # config.env_separator = '.'

  # Ability to process variables names:
  #   * nil  - no change
  #   * :downcase - convert to lower case
  #
  # config.env_converter = :downcase

  # Parse numeric values as integers instead of strings.
  #
  # config.env_parse_values = true
end

# The explicit call to `Config.load_and_set_settings` is required by the
# sidekiq jobs, which run outside of rails/sinatra (which have automated
# calls to load and setup the Config gem).  For sidekiq jobs to get an
# initialized config, they start by loading `config/initializers/sidekiq`.  It
# requires `config/initializers/config` (this file).  It also
# requires `config/initializers/dpn_workers`, which requires
# `lib/dpn/workers/workers` and that requires `lib/dpn/workers/init` and
# it ensures the settings are loade by requiring this file.
# https://github.com/railsconfig/config#installing-on-sinatra
config_files = [
  'config/settings.yml',
  "config/settings/#{ENV['RACK_ENV']}.yml",
  'config/settings.local.yml',
  "config/settings/#{ENV['RACK_ENV']}.local.yml"
]
Config.load_and_set_settings(config_files)
