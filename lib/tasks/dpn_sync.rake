# DPN Workers Initializers
Dir.glob('./config/initializers/**/*.rb').each { |r| require r }

namespace :dpn do
  namespace :sync do
    desc "DPN - fetch bag meta-data from remote nodes"
    task :bags do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncBags"
    end

    desc "DPN - queue bag retrievals"
    task :bag_retrievals do
      DPN::Workers::BagRetrievals.perform_async
    end

    desc "DPN - queue bag stores"
    task :bag_stores do
      DPN::Workers::BagStores.perform_async
    end

    desc "DPN - fetch digest meta-data from remote nodes"
    task :digests do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncDigests"
    end

    desc "DPN - fetch fixity meta-data from remote nodes"
    task :fixities do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncFixities"
    end

    desc "DPN - fetch ingest meta-data from remote nodes"
    task :ingests do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncIngests"
    end

    desc "DPN - fetch member meta-data from remote nodes"
    task :members do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncMembers"
    end

    desc "DPN - fetch node meta-data from remote nodes"
    task :nodes do
      DPN::Workers::SyncWorker.perform_async "DPN::Workers::SyncNodes"
    end

    desc "DPN - fetch replication request meta-data from remote nodes"
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
