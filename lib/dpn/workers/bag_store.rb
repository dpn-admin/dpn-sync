# This class adapts some state and logic from dpn-server, i.e.
# https://github.com/dpn-admin/dpn-server
# The code in dpn-server is governed by the following copyright notice:
# Copyright (c) 2015 The Regents of the University of Michigan.
# All Rights Reserved.
# Licensed according to the terms of the Revised BSD License
# See LICENSE.md for details.

module DPN
  module Workers
    ##
    # Replicate a bag in the storage path
    class BagStore < BagReplication

      # @return [Boolean] success
      def transfer
        return true if replication.stored
        return false if replication.cancelled
        return false unless replication.store_requested
        store
      end

      private

        def bagit
          @bagit ||= begin
            bag_path = File.join(storage_path, replication.bag)
            DPN::Bagit::Bag.new(bag_path)
          end
        end

        # @return [Boolean] success of preservation
        def store
          # TODO: consider whether or not to mark a replication as
          #       cancelled when this fails.  Or try again?
          preserve_rsync &&
            preserve_validate &&
            update_replication
        end

        # @return [Boolean] success of rsync transfer
        def preserve_rsync
          bag_path = File.join(staging_path, replication.bag)
          DPN::Workers::BagRsync.new(bag_path, storage_path, 'store').rsync
        end

        # @return [Boolean] validity of preserved bag
        def preserve_validate
          bagit.valid? || raise("Bag invalid: #{bagit.errors}")
        end

        # Update the replication transfer resource on the remote node
        # @return [Boolean]
        def update_replication
          replication.stored = true
          replication.update_admin
          replication.update_local
        end
    end
  end
end
