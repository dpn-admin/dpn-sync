# This class adapts some state and logic from dpn-server, i.e.
# https://github.com/dpn-admin/dpn-server
# The code in dpn-server is governed by the following copyright notice:
# Copyright (c) 2015 The Regents of the University of Michigan.
# All Rights Reserved.
# Licensed according to the terms of the Revised BSD License
# See LICENSE.md for details.

require_relative 'bag_paths'
require_relative 'bag_rsync'

require 'forwardable'

module DPN
  module Workers
    ##
    # A Bag Replication-Transfer-Resource
    # @see https://github.com/dpn-admin/DPN-REST-Wiki/blob/master/Replication-Transfer-Resource.md
    # @see https://wiki.duraspace.org/display/DPNC/BagIt+Specification
    class BagReplication
      extend Forwardable

      # @param [Hash] replication transfer resource
      def initialize(replication)
        @_replication = OpenStruct.new(replication)
        @_paths = DPN::Workers::BagPaths.new
      end

      # Replication Request ID - the unique (UUIDv4) identifier for this replication request
      # @return [String] replication_id
      def id
        replication_id
      end

      # Replication Bag ID - the unique (UUIDv4) identifier for the DPN bag
      # @return [String] bag_id
      def bag_id
        # The DPN REST spec uses 'bag' but some implementations use 'uuid', so
        # provide a fall-back to 'bagit.uuid'.
        @_bag_id ||= bag
        @_bag_id ||= bagit.uuid if bagit
        @_bag_id
      end

      # @return [Boolean] success of replication transfer
      def replicate
        return false if cancelled
        return true if stored
        retrieve && preserve
      end

      # @return [Hash]
      def to_h
        @_replication.to_h
      end

      private

        def_delegators :@_replication,
          :replication_id,
          :bag,
          :cancelled, :cancel_reason, :cancel_reason_detail,
          :created_at, :updated_at,
          :fixity_algorithm, :fixity_nonce, :fixity_value,
          :link,
          :from_node, :to_node,
          :protocol,
          :store_requested,
          :stored

        def bagit
          @_bagit
        end

        def bagit_path
          bagit.location + File::SEPARATOR
        end

        def paths
          @_paths
        end

        # Replication file - the basename for the replication link
        # @return [String] file
        def file
          @_file ||= File.basename(link)
        end

        # @return [Boolean] success of preservation
        def preserve
          return false if cancelled
          return true if stored
          raise 'Replication transfer - storage is not requested' unless store_requested
          preserve_rsync && preserve_validate
          update_replication
        end

        # @return [Boolean] success of rsync transfer
        def preserve_rsync
          DPN::Workers::BagRsync.new(bagit_path, storage_path, 'preserve').rsync
        end

        # @return [Boolean] validity of preserved bag
        def preserve_validate
          @_bagit = DPN::Bagit::Bag.new(storage_path)
          @_replication[:stored] = true if validate
          # TODO: cleanup the staging path?
        end

        # Administrative node that issued the replication transfer request
        # @return [DPN::Workers::Node] remote node
        def remote_node
          @_remote_node ||= begin
            DPN::Workers.nodes.remote_node from_node
          end
        end

        # @return [Boolean] success of retrieval
        def retrieve
          retrieve_rsync &&
            retrieve_validate &&
            retrieve_fixity &&
            retrieve_success?
        end

        # Update the replication status to 'received' and
        # verify the fixity with the admin node.
        # @return [Boolean] success of retrieval
        def retrieve_success?
          update_replication
          raise "Admin node did not accept fixity: #{fixity_value}" unless store_requested
          store_requested
        end

        # Calculate bag fixity to set the replication fixity_value
        # @return [String] fixity value
        def retrieve_fixity
          raise 'There is no bagit to calculate fixity' unless bagit
          @_replication[:fixity_value] = bagit.fixity(:sha256)
        end

        # @return [String]
        def retrieve_path
          @_retrieve_path ||= begin
            path = File.join(staging_path, file)
            raise "Failed to retrieve" unless File.exist? path
            path
          end
        end

        # @return [Boolean] success of rsync transfer
        def retrieve_rsync
          DPN::Workers::BagRsync.new(link, staging_path, 'retrieve').rsync
        end

        # @return [Boolean] success of unpacking a bagit from a replication .tar archive
        # @raise [RuntimeError]
        def retrieve_bagit
          if File.directory?(retrieve_path)
            @_bagit = DPN::Bagit::Bag.new(retrieve_path)
          else
            case File.extname retrieve_path
            when ".tar"
              serialized_bag = DPN::Bagit::SerializedBag.new(retrieve_path)
              @_bagit = serialized_bag.unserialize!
            else
              raise "Could not unpack file type: #{retrieve_path}"
            end
          end
          true
        end

        # @return [Boolean] success of validating a retrieved bag
        def retrieve_validate
          retrieve_bagit && validate
        end

        # @return [String] staging_path
        def staging_path
          @_staging ||= paths.staging(replication_id)
        end

        # @return [String] storage_path
        def storage_path
          @_storage ||= paths.storage(bag_id)
        end

        # Update the replication transfer resource on the remote node
        # @return [Boolean]
        def update_replication
          response = remote_node.client.update_replication(to_h)
          data = response.body
          raise "Failed to update replication: #{data}" unless response.success?
          @_replication = OpenStruct.new(data)
          true
        end

        # Validate the DPN bag
        # @return [Boolean] true when bagit.valid? is true
        # @raise [RuntimeError] if bagit.valid? is false
        def validate
          bagit.valid? || raise("Bag invalid: #{bagit.errors}")
        end
    end
  end
end
