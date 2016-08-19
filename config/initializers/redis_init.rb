require 'redis'
require 'redis-namespace'
require 'yaml'

rack_env = ENV['RACK_ENV'] || 'development'

redis_settings = YAML.load_file('config/redis.yml')
REDIS_CONFIG = redis_settings[rack_env].symbolize_keys
REDIS = Redis.new(REDIS_CONFIG)

job_data_ns = REDIS_CONFIG[:namespace] + ':job-data'
REDIS_JOB_DATA = Redis::Namespace.new(job_data_ns, redis: REDIS)
