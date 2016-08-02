# This class adapts some state and logic from dpn-server, i.e.
# https://github.com/dpn-admin/dpn-server
# The code in dpn-server is governed by the following copyright notice:
# Copyright (c) 2015 The Regents of the University of Michigan.
# All Rights Reserved.
# Licensed according to the terms of the Revised BSD License
# See LICENSE.md for details.

require 'rsync'

module DPN
  module Workers
    ##
    # A Bag Replication-Transfer-Resource
    # @see https://github.com/dpn-admin/DPN-REST-Wiki/blob/master/Replication-Transfer-Resource.md
    # @see https://wiki.duraspace.org/display/DPNC/BagIt+Specification
    class BagReplication

      attr_reader :status

      # @param [Hash] replication transfer resource
      def initialize(replication)
        create_attributes(replication)
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
        return false if status =~ /cancelled|rejected/
        return true if status =~ /confirmed|stored/
        retrieve && preserve
      end

      # @return [Hash]
      def to_h
        attributes.map do |var|
          key = var.to_s.delete('@').to_sym
          [key, instance_variable_get(var)]
        end.to_h
      end

      private

        attr_reader :replication_id,
                    :bag, :bag_valid,
                    :created_at, :updated_at,
                    :fixity_accept, :fixity_algorithm, :fixity_nonce, :fixity_value,
                    :link,
                    :from_node, :to_node,
                    :protocol

        def bagit
          @_bagit
        end

        def bagit_path
          bagit.location + File::SEPARATOR
        end

        def paths
          @_paths
        end

        # @return [Array] instance variable symbols
        def attributes
          instance_variables.select { |var| !var.to_s.start_with?('@_') }
        end

        # @param [Hash] opts
        def create_attributes(opts)
          opts.each { |key, val| instance_variable_set("@#{key}", val) }
        end

        # Replication file - the basename for the replication link
        # @return [String] file
        def file
          @_file ||= File.basename(link)
        end

        # @return [Boolean] success of preservation
        def preserve
          return true if status =~ /stored/i
          raise "Replication transfer status is not 'received' (status=#{status})" unless status =~ /received/i
          preserve_rsync && preserve_validate
          update_replication 'stored'
        end

        # @return [Boolean] success of rsync transfer
        def preserve_rsync
          Rsync.run(bagit_path, storage_path, preserve_rsync_options) do |result|
            raise "Failed to preserve: #{result.error}" unless result.success?
          end
          true
        end

        # @return [String] rsync options for preservation
        def preserve_rsync_options
          [
            '--copy-dirlinks',
            '--copy-unsafe-links',
            '--partial',
            '--quiet',
            '--recursive'
          ].join(' ')
        end

        # @return [Boolean] validity of preserved bag
        def preserve_validate
          @_bagit = DPN::Bagit::Bag.new(storage_path)
          validate
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
          return true if status =~ /confirmed|received|stored/i
          raise "Replication transfer status is not 'requested' (status=#{status})" unless status =~ /requested/i
          retrieve_rsync && retrieve_validate && retrieve_fixity
          update_replication 'received'
        end

        # Calculate bag fixity to set the replication fixity_value
        # and verify the fixity with the admin node
        # @return [Boolean] fixity accepted
        def retrieve_fixity
          @_fixity ||= begin
            raise 'There is no bagit to calculate fixity' unless bagit
            # TODO: confirm whether to calculate fixity using the bagit or
            #       calculate a fixity on the .tar transfer file.
            @fixity_value = bagit.fixity(:sha256)
            update_replication
            raise 'Admin node did not accept fixity' unless fixity_accept
            fixity_accept
          end
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
          Rsync.run(link, staging_path, retrieve_rsync_options) do |result|
            raise "Failed to retrieve: #{result.error}" unless result.success?
          end
          true
        end

        # @return [String] rsync options for retrieval
        def retrieve_rsync_options
          [
            '--archive',
            '--copy-dirlinks',
            '--copy-unsafe-links',
            '--partial',
            '--quiet',
            retrieve_ssh
          ].join(' ')
        end

        # Construct an ssh command for rsync, if an ssh identity file is
        # provided in the SyncSettings.replication configuration.
        # @return [String] ssh command
        def retrieve_ssh
          @_retrieve_ssh ||= begin
            ssh_id_file = paths.ssh_identity_file
            return '' unless File.exist? ssh_id_file
            ssh_cmd = [
              'ssh',
              '-o PasswordAuthentication=no',
              '-o UserKnownHostsFile=/dev/null',
              '-o StrictHostKeyChecking=no',
              "-i #{ssh_id_file}"
            ].join(' ')
            "-e '#{ssh_cmd}'"
          end
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

        # Update the replication transfer resource status on the remote node
        # @param [String|nil] status of replication transfer
        #   'requested' - set by the from_node to indicate the bag is staged for
        #                 transfer and awaiting response from to_node.
        #   'rejected' - set by the to_node to indicate it will not perform the transfer.
        #   'received' - set by the to_node to indicate it has performed the transfer.
        #   'confirmed' - set by the from_node after it receives all data to confirm a good transfer.
        #   'stored' - set by the to_node to indicate the bag has been transferred into
        #              its storage repository from the staging area. The to_node promises
        #              to fulfill replicating node duties by setting this status.
        #   'cancelled' - set by either node to indicate the transfer was cancelled.
        # @return [Boolean]
        def update_replication(status = nil)
          @status = status if status
          response = remote_node.client.update_replication(to_h)
          raise "Failed to update replication: #{response.body}" unless response.success?
          # TODO: check the response.body can be assigned OK here
          create_attributes(response.body)
          true
        end

        # Validate the DPN bag
        # @return [Boolean] true when bagit.valid? is true
        # @raise [RuntimeError] if bagit.valid? is false
        def validate
          @bag_valid = bagit.valid?
          raise "Bag invalid: #{bagit.errors}" unless bag_valid
          bag_valid
        end
    end
  end
end
