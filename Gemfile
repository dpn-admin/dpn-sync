source 'https://rubygems.org/'

# App Stack
gem 'sinatra'
gem 'config'

# Background Processing Stack
gem 'sidekiq'
gem 'sidekiq-cron'

gem 'hiredis'
gem 'redis', require: ['redis/connection/hiredis', 'redis']
gem 'redis-namespace'

# DPN
gem 'dpn-client', git: 'https://github.com/dpn-admin/dpn-client.git'

group :development do
  gem 'thin' # app server
  gem 'reek'
  gem 'yard'
  gem 'redcarpet'
  gem 'github-markup'
end

group :development, :test do
  gem 'dpn_cops', git: 'https://github.com/dpn-admin/dpn_cops.git'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-stack_explorer'
  gem 'rake'
end

group :test do
  gem 'rspec'
  gem 'fakeredis', require: 'fakeredis/rspec'
  gem 'rack-test'
  gem 'coveralls', require: false
  gem 'simplecov', require: false
  gem 'single_cov'
  gem 'vcr'
  gem 'webmock'
end

group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-sidekiq'
  gem 'capistrano-bundle_audit', '~> 0.1'
  gem 'dlss-capistrano'
end
