# DPN Workers Initializers
Dir.glob('./config/initializers/**/*.rb').each { |r| require r }

namespace :dpn do
  namespace :sync do
    desc "DPN - queue a job to fetch bag meta-data from remote nodes"
    task :bags do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncBags"
    end

    desc "DPN - queue a job to fetch member meta-data from remote nodes"
    task :members do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncMembers"
    end

    desc "DPN - queue a job to fetch node meta-data from remote nodes"
    task :nodes do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncNodes"
    end
  end
end
