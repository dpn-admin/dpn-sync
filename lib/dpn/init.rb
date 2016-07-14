require 'bundler'
Bundler.setup
Bundler.require

##
# Initialize Settings from config files
require 'config'
config_files = [
  'config/settings.yml',
  "config/settings/#{ENV['RACK_ENV']}.yml",
  'config/settings.local.yml',
  "config/settings/#{ENV['RACK_ENV']}.local.yml"
]
Config.load_and_set_settings(config_files)

require 'json'
require 'logger'
require_relative 'workers/sync'
require_relative 'workers/sync_bags'
require_relative 'workers/sync_nodes'
require_relative 'workers/node'
require_relative 'workers/nodes'
require_relative 'workers/sync_worker'
require_relative 'workers/test_worker'
