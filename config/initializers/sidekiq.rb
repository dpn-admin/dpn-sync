# Sidekiq Configuration
require_relative 'redis'
require_relative '../../lib/dpn/workers'

require 'sidekiq'
require 'sidekiq/cron'

host = REDIS_CONFIG[:host]
port = REDIS_CONFIG[:port]
db   = REDIS_CONFIG[:db]
REDIS_URL = "redis://#{host}:#{port}/#{db}".freeze

Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_URL, namespace: REDIS_CONFIG[:namespace] }
end

Sidekiq.configure_server do |config|
  config.redis = { url: REDIS_URL, namespace: REDIS_CONFIG[:namespace] }
end

schedule_file = 'config/schedule.yml'
if File.exist?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end
