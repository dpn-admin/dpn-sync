# DPN Workers Initializers
Dir.glob('./config/initializers/**/*.rb').each { |r| require r }

namespace :dpn do
  namespace :sync do
    desc "DPN - queue a job to fetch node meta-data from remote nodes"
    task :nodes do
      DPN::Workers::SyncWorker.perform_async "nodes"
    end

    desc "DPN - queue a job to fetch bags meta-data from remote nodes"
    task :bags_meta_data do
      DPN::Workers::SyncWorker.perform_async "bags"
    end
  end
end
