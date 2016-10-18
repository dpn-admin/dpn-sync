# DPN Workers Initializers
Dir.glob('./config/initializers/**/*.rb').each { |r| require r }

namespace :dpn do
  namespace :sync do
    desc "DPN - queue a job to fetch bag meta-data from remote nodes"
    task :bags do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncBags"
    end

    desc "DPN - queue a job to fetch digest meta-data from remote nodes"
    task :digests do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncDigests"
    end

    desc "DPN - queue a job to fetch fixity meta-data from remote nodes"
    task :fixities do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncFixities"
    end

    desc "DPN - queue a job to fetch member meta-data from remote nodes"
    task :members do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncMembers"
    end

    desc "DPN - queue a job to fetch node meta-data from remote nodes"
    task :nodes do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncNodes"
    end

    desc "DPN - queue a job to fetch replication request meta-data from remote nodes"
    task :replications do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncReplications"
    end

    namespace :redis do
      desc "DPN - reset redis store for job data"
      task :reset_job_data do
        keys = REDIS_JOB_DATA.keys
        keys.each { |k| REDIS_JOB_DATA.del(k) }
      end
    end
  end
end
