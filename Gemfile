source 'https://rubygems.org/'

# App Stack
gem 'rack'
gem 'sinatra'
gem 'config'

# Background Processing Stack
gem 'sidekiq'
gem 'sidekiq-cron'

gem 'hiredis'
gem 'redis', require: ['redis/connection/hiredis', 'redis']
gem 'redis-namespace'

# DPN
gem 'dpn-client', '~> 1.3'
gem 'dpn-bagit', git: 'https://github.com/dpn-admin/dpn-bagit.git', tag: 'v0.3.1'
gem 'rpairtree'
gem 'rsync'

group :development do
  gem 'thin' # app server
  gem 'reek'
  gem 'yard'
  gem 'redcarpet'
  gem 'github-markup'
end

group :development, :test do
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-stack_explorer'
  gem 'rake'
  gem 'rubocop'
  gem 'rubocop-rspec'
end

group :test do
  gem 'rspec'
  gem 'fakeredis', require: 'fakeredis/rspec'
  gem 'rack-test'
  gem 'codeclimate-test-reporter', require: nil
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
