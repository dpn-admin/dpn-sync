require 'bundler'
Bundler.require
require 'json'
require 'logger'

# Initialize SyncSettings from config files
require_relative '../../config/initializers/config'

# DPN nodes
require_relative 'workers/node'
require_relative 'workers/nodes'
# DPN bag replication
require_relative 'workers/bag_paths'
require_relative 'workers/bag_rsync'
require_relative 'workers/bag_replication'
# Sidekiq worker libraries
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
# Sidekiq workers
require_relative 'workers/bag_worker'
require_relative 'workers/sync_worker'
require_relative 'workers/test_worker'
# /is_it_working monitor
require_relative 'monitor'
