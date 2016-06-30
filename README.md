
[![Build Status](https://travis-ci.org/sul-dlss/dpn-sync.svg?branch=master)](https://travis-ci.org/sul-dlss/dpn-sync) [![Coverage Status](https://coveralls.io/repos/sul-dlss/dpn-sync/badge.png)](https://coveralls.io/r/sul-dlss/dpn-sync) [![Dependency Status](https://gemnasium.com/sul-dlss/dpn-sync.svg)](https://gemnasium.com/sul-dlss/dpn-sync) 

# DPN Synchronization

An application for synchronizing DPN registry data from remote nodes, using the
[Sidekiq](https://github.com/mperham/sidekiq) background jobs framework.

Components:
- the DPN nodes are defined in `config/settings.yml`
  - the settings are handled by `DPN::Workers`
  - a set of DPN nodes is loaded by `DPN::Workers.nodes`
- a set of DPN nodes is modeled by the `DPN::Workers::Nodes` class
  - it requires a `local_namespace` to identify a `local_node`
  - it makes an important distinction between a `local_node` and `remote_nodes`
  - it has methods to `sync` data from `remote_nodes` into the `local_node`
    - various `DPN::Workers::SyncWorker` call the `sync` method
    - various `DPN::Workers::Sync` implement the `sync` details
      - they use `DPN::Workers::JobData` for tracking success
- a node is modeled by the `DPN::Workers::Node` class
  - it requires a node namespace, API URL, and authentication token
  - it contains a `DPN::Client` to access a node's HTTP API
  - the client is from https://github.com/dpn-admin/dpn-client
  - the HTTP API is from https://github.com/dpn-admin/dpn-server

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

The `config` gem provides several layers of specificity for settings, see
https://github.com/railsconfig/config#accessing-the-settings-object

### Configuring Nodes

The most important values in `Settings` are the `nodes` definitions and the
`local_namespace` that should belong to one of the `nodes`.  These values
should be derived from the `Node` table of the `dpn-server` project.
From the `rails c` console of the `dpn-server` project, the nodes data
can be dumped using:

```ruby
require 'yaml'
Node.all.map do |n|
  {
    namespace: n.namespace,
    api_root: n.api_root,
    auth_credential: n.auth_credential
  }
end.to_yaml
```

Note that the `auth_credential` values are private and should be kept secret.

### Configuring Test Cluster

When running in development, the `dpn-server` project can run a test cluster and the nodes data can be set to work with that cluster; the default values in `config/settings.yml` should work with this cluster.  See
- https://github.com/dpn-admin/dpn-server/blob/master/Cluster.md
- https://github.com/dpn-admin/dpn-server/blob/master/script/run_cluster.rb

### Environment Variables

- Environment variables can be set in various places, with the following order
of importance:
  - On deployed apps, running under Apache/Passenger:
    - see `/etc/httpd/conf.d/z*`
    - The content of the config files is managed by puppet
  - Command line values, e.g. `RACK_ENV=production bundle exec rackup`

## Deployment

Capistrano is configured to run all the deployments.  See `cap -T` for all the options.  There are private configuration files in the [DLSS shared-configs](https://github.com/sul-dlss/shared_configs). The following files should be in the `shared_configs`, in a branch like `dpn-*-sync`.  The generic `settings.yml` should contain config parameters that are independent of the deployment `{environment}.yml` (like `development.yml` or `production.yml`), whereas the `settings/{environment}.yml` should contain `nodes` or other details that are specific to the deployment network.

```
config/
├── redis.yml
├── settings
│   └── {environment}.yml
├── settings.yml
└── sidekiq_schedule.yml
```

## Development

- To get a console: `bundle exec rackup -d`
  - if anything goes wrong, look at `log/rack_debug.log`
  - if the `dpn-server` cluster is running, the following works:

```ruby
DPN::Workers.nodes.map(&:alive?)
#=> [true, true, true, true, true]
```

- To see and test jobs:
  - `bundle exec sidekiq -C ./config/sidekiq.yml -r ./config/initializers/sidekiq.rb`
  - in another shell, run `bundle exec rackup`
    - use a browser to open `http://localhost:9292`
    - use the `/test` page to check messages are processed by a worker
    - use the `/sidekiq` dashboard
