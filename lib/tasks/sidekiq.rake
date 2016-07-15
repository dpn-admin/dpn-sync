require 'json'
require 'yaml'
require 'sidekiq/api'

# Usage: bundle exec rake sidekiq:restart RACK_ENV=<environment name>
namespace :sidekiq do
  namespace :service do
    sidekiq_config_file = File.join('config', 'sidekiq.yml')
    sidekiq_config_file = File.expand_path(sidekiq_config_file)
    if File.exist? sidekiq_config_file
      sidekiq_config = YAML.load(File.read(sidekiq_config_file))
      sidekiq_pid_file = sidekiq_config[:pidfile]
      sidekiq_log_file = sidekiq_config[:logfile]
    end

    rack_env = ENV["RACK_ENV"] || 'development'
    if sidekiq_config[rack_env]
      config = sidekiq_config[rack_env]
      sidekiq_pid_file = config[:pidfile]
      sidekiq_log_file = config[:logfile]
    end

    sidekiq_pid_file ||= File.join('tmp', 'pids', 'sidekiq.pid')
    sidekiq_log_file ||= File.join('log', 'sidekiq.log')
    sidekiq_pid_file = File.expand_path(sidekiq_pid_file)
    sidekiq_log_file = File.expand_path(sidekiq_log_file)

    sidekiq_init_file = File.expand_path(File.join('config', 'initializers', 'sidekiq.rb'))

    desc "Sidekiq - restart"
    task :restart do
      Rake::Task['sidekiq:stop'].invoke
      Rake::Task['sidekiq:start'].invoke
    end

    desc "Sidekiq - start"
    task :start do
      puts 'Using files:'
      puts "  #{sidekiq_init_file}"
      puts "  #{sidekiq_config_file}"
      puts "  #{sidekiq_pid_file}"
      puts "  #{sidekiq_log_file}"
      options = "--daemon"
      options += " --environment #{rack_env}"
      options += " --config #{sidekiq_config_file}"
      options += " --pidfile #{sidekiq_pid_file}"
      options += " --logfile #{sidekiq_log_file}"
      options += " --require #{sidekiq_init_file}"
      system "bundle exec sidekiq #{options}" # starts sidekiq process here
      sleep(3)
      puts "Sidekiq started #PID-#{File.read(sidekiq_pid_file)}."
    end

    desc "Sidekiq - stop"
    task :stop do
      if File.exist? sidekiq_pid_file
        puts "Stopping sidekiq now #PID-#{File.read(sidekiq_pid_file)}..."
        system "sidekiqctl stop #{sidekiq_pid_file}"
        system "rm -f #{sidekiq_pid_file}"
      else
        puts "Sidekiq not running"
      end
    end
  end

  namespace :clear do
    desc "Sidekiq - clear the queue[id] (id is 'default' by default)"
    task :queue, :id do |_t, args|
      args.with_defaults(id: 'default')
      Sidekiq::Queue.new(args[:id]).clear
    end

    desc "Sidekiq - clear the retry set"
    task :retry_set do
      Sidekiq::RetrySet.new.clear
    end

    desc "Sidekiq - clear the scheduled set"
    task :scheduled_set do
      Sidekiq::ScheduledSet.new.clear
    end
  end

  namespace :default_queue do
    queue = Sidekiq::Queue.new('default')

    desc "Sidekiq - clear the default queue"
    task :clear do
      queue.clear
    end

    desc 'Sidekiq - default queue entries'
    task :entries do
      queue.entries.each do |entry|
        puts JSON.pretty_generate(JSON.parse(entry.value))
      end
    end
  end

  namespace :stats do
    def stats_data
      stats = Sidekiq::Stats.new
      stats.instance_variable_get('@stats')
    end

    desc "Sidekiq - statistics - all"
    task :all do
      puts JSON.pretty_generate(stats_data)
    end

    desc "Sidekiq - statistics - reset"
    task :reset do
      Sidekiq::Stats.new.reset
    end

    desc "Sidekiq - statistics - history[days]"
    task :history, :days do |_t, args|
      args.with_defaults(days: '5')
      s = Sidekiq::Stats::History.new(args[:days].to_i)
      puts JSON.pretty_generate(
        processed: s.processed,
        failed: s.failed
      )
    end
  end
end
