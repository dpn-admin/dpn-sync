
[![Build Status](https://travis-ci.org/sul-dlss/dpn-sync.svg?branch=master)](https://travis-ci.org/sul-dlss/dpn-sync) [![Coverage Status](https://coveralls.io/repos/sul-dlss/dpn-sync/badge.png)](https://coveralls.io/r/sul-dlss/dpn-sync) [![Dependency Status](https://gemnasium.com/sul-dlss/dpn-sync.svg)](https://gemnasium.com/sul-dlss/dpn-sync) 

# DPN Synchronization

An application for synchronizing DPN registry data from remote nodes, using the [Sidekiq](https://github.com/mperham/sidekiq) background jobs framework.

## Requirements

- [Sidekiq](https://github.com/mperham/sidekiq) requires the [Redis](http://redis.io/) document store.

## Getting Started

  ```sh
  git clone git@github.com:sul-dlss/dpn-sync.git
  cd dpn-sync
  bundle install
  # Start the Sidekiq daemon to run background jobs; some
  # jobs are managed by sidekiq-cron, see config/schedule.yml
  bundle exec sidekiq -d -C config/sidekiq.yml -r ./config/initializers/sidekiq.rb
  # Start the Sidekiq dashboard at http://localhost:9292/
  bundle exec rackup
  ```

## Configuration

- Configuration files are in:
  - `config/*.yml`
  - `config/settings/*.yml`
  - `config/initializers/*.rb`
  - additional configuration details may be in the project wiki pages

- Environment variables can be set in various places, with the following order
of importance:
  - On deployed apps, running under Apache/Passenger:
    - see `/etc/httpd/conf.d/z*`
    - The content of the config files is managed by puppet
  - Command line values, e.g. `RACK_ENV=production bundle exec rackup`

## Deployment

Capistrano is configured to run all the deployments.  See `cap -T` for all the options.  There are private configuration files in the [DLSS shared-configs](https://github.com/sul-dlss/shared_configs).
