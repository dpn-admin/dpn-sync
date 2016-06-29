
# install redis with persistence

bundle install

bundle exec sidekiq -d -C config/sidekiq.yml -r ./config/initializers/sidekiq.rb

bundle exec rackup
