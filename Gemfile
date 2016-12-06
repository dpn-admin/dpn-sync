source 'https://rubygems.org/'

# App Stack
gem 'rack'
gem 'sinatra'
gem 'config'
gem 'app_version_tasks', '~> 0.2.0'

# Background Processing Stack
gem 'sidekiq'
gem 'sidekiq-cron'

gem 'hiredis'
gem 'redis', require: ['redis/connection/hiredis', 'redis']
gem 'redis-namespace'

# Console utils (also required in production)
gem 'pry'
gem 'pry-doc'
gem 'pry-stack_explorer'
gem 'rake'

# DPN
gem 'dpn-bagit', '~>0.3'
gem 'dpn-client', '~>2.0'
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
  gem 'rubocop'
  gem 'rubocop-rspec'
end

group :test do
  gem 'codacy-coverage', require: false
  gem 'rspec'
  gem 'fakeredis', require: 'fakeredis/rspec'
  gem 'rack-test'
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
