require 'redis'
require 'redis-namespace'
require 'yaml'

rack_env = ENV['RACK_ENV'] || 'development'

redis_settings = YAML.load_file('config/redis.yml')
REDIS_CONFIG = redis_settings[rack_env].symbolize_keys
REDIS = Redis.new(REDIS_CONFIG)
