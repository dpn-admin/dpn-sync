module DPN
  module Workers
    ##
    # DPN worker to replicate a bag
    class BagWorker
      include Sidekiq::Worker
      sidekiq_options backtrace: 10

      # Worker called from DPN::Workers::SyncReplications#save_replication
      # @see DPN::Workers::SyncReplications#save_replication
      # @see https://github.com/dpn-admin/DPN-REST-Wiki/blob/master/Replication-Transfer-Resource.md
      # @param [Hash] replication transfer request
      # @return [Boolean]
      def perform(replication)
        DPN::Workers::BagReplication.new(replication).replicate
      end
    end
  end
end
