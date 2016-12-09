require 'bundler'
Bundler.require
require 'json'
require 'logger'

# Ensure that SyncSettings is initialized from config files
require_relative '../../config/initializers/config'

# DPN nodes
require_relative 'workers/node'
require_relative 'workers/nodes'

# DPN bag replication
require_relative 'workers/bag_paths'
require_relative 'workers/bag_rsync'
require_relative 'workers/bag_replication'
require_relative 'workers/bag_replications'
require_relative 'workers/bag_retrieve'
require_relative 'workers/bag_store'
require_relative 'workers/replication'

# Sidekiq worker libraries
require_relative 'workers/job_data'

require_relative 'workers/sync'
require_relative 'workers/sync_content'

require_relative 'workers/sync_bag'
require_relative 'workers/sync_bags'

require_relative 'workers/sync_digest'
require_relative 'workers/sync_digests'

require_relative 'workers/sync_fixity'
require_relative 'workers/sync_fixities'

require_relative 'workers/sync_ingest'
require_relative 'workers/sync_ingests'

require_relative 'workers/sync_member'
require_relative 'workers/sync_members'

require_relative 'workers/sync_nodes'

require_relative 'workers/sync_replication'
require_relative 'workers/sync_replications'

require_relative 'workers/test_messages'

# Sidekiq workers
require_relative 'workers/sync_worker'
require_relative 'workers/test_worker'

# /status monitor
require_relative 'monitor'
