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
    # Replicate a bag in the staging path
    class BagRetrieve < BagReplication

      # @return [Boolean] success of bag retrieval
      def transfer
        return false if replication.cancelled
        return true  if replication.store_requested
        retrieve
      end

      private

        # @return [Boolean] success of retrieval
        def retrieve
          retrieve_rsync &&
            retrieve_validate &&
            retrieve_fixity &&
            retrieve_success?
        end

        # @return [Boolean] success of rsync transfer
        def retrieve_rsync
          src = replication.link
          DPN::Workers::BagRsync.new(src, staging_path, 'stage').rsync
        end

        # Validate the DPN bag retrieved
        # @return [Boolean] success of validating a retrieved bag
        # @raise [RuntimeError] when bagit.valid? is false
        def retrieve_validate
          bagit.valid? || raise("Bag invalid: #{bagit.errors}")
        end

        # Calculate bag fixity to set the replication fixity_value
        # @return [String] fixity value
        def retrieve_fixity
          alg = replication.fixity_algorithm.to_sym
          replication.fixity_value = bagit.fixity(alg)
        end

        # Update the replication status to 'received' and
        # verify the fixity with the admin node.
        # @return [Boolean] success of retrieval
        def retrieve_success?
          replication.update_admin
          success = replication.store_requested
          raise "Admin node did not accept fixity: #{replication.fixity_value}" unless success
          replication.update_local
        end

        # @return [String]
        def retrieve_path
          @retrieve_path ||= begin
            path = File.join(staging_path, replication.file)
            raise "Failed to retrieve" unless File.exist? path
            path
          end
        end

        # @return [DPN::Bagit::Bag] a bagit from a replication transfer
        # @raise [RuntimeError]
        def bagit
          @bagit ||= begin
            if File.directory?(retrieve_path)
              DPN::Bagit::Bag.new(retrieve_path)
            else
              case File.extname retrieve_path
              when ".tar"
                serialized_bag = DPN::Bagit::SerializedBag.new(retrieve_path)
                serialized_bag.unserialize!
              else
                raise "Could not unpack file type: #{retrieve_path}"
              end
            end
          end
        end
    end
  end
end
