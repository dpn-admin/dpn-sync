source 'https://rubygems.org/'

# App Stack
gem 'sinatra', '~> 1.4'
gem 'sinatra-contrib'

gem 'sidekiq'
gem 'sidekiq-cron', '~> 0.4.0'

# Redis
gem 'hiredis', '~> 0.4'
gem 'redis', '~> 3.0', require: ['redis/connection/hiredis', 'redis']
gem 'redis-namespace'

# DPN
gem 'dpn-client', git: 'https://github.com/dpn-admin/dpn-client.git'

group :development do
  gem 'rake', '~> 10.0'
  gem 'thin' # app server
end

group :development, :test do
  gem 'dpn_cops', git: 'git@github.com:dpn-admin/dpn_cops.git'
  gem 'pry'
  gem 'pry-doc'
  gem 'yard'
end

group :test do
  gem 'fakeredis', '~> 0.4'
  gem 'rspec'
  gem 'rack-test', '~> 0.6'
  gem 'coveralls', require: false
  gem 'simplecov', require: false
  gem 'single_cov'
end

group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-sidekiq'
  gem 'capistrano-bundle_audit', '~> 0.1.0'
  gem 'dlss-capistrano'
end
