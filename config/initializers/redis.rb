require 'redis'
require 'yaml'

redis_settings = YAML.load_file('config/redis.yml')
REDIS_CONFIG = redis_settings[ENV['RACK_ENV']].symbolize_keys
REDIS = Redis.new(REDIS_CONFIG)
