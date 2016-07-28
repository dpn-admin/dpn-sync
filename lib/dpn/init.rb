require 'bundler'
Bundler.require
require 'json'
require 'logger'

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

require_relative 'workers/job_data'
require_relative 'workers/sync'
require_relative 'workers/sync_content'
require_relative 'workers/sync_bag'
require_relative 'workers/sync_bags'
require_relative 'workers/sync_member'
require_relative 'workers/sync_members'
require_relative 'workers/sync_nodes'
require_relative 'workers/sync_replication'
require_relative 'workers/sync_replications'
require_relative 'workers/node'
require_relative 'workers/nodes'
require_relative 'workers/sync_worker'
require_relative 'workers/test_worker'
require_relative 'monitor'
