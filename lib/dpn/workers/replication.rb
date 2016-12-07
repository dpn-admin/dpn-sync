# This class adapts some state and logic from dpn-server, i.e.
# https://github.com/dpn-admin/dpn-server
# The code in dpn-server is governed by the following copyright notice:
# Copyright (c) 2015 The Regents of the University of Michigan.
# All Rights Reserved.
# Licensed according to the terms of the Revised BSD License
# See LICENSE.md for details.

require 'forwardable'

module DPN
  module Workers
    ##
    # A Bag Replication-Transfer-Resource
    # @see https://github.com/dpn-admin/DPN-REST-Wiki/blob/master/Replication-Transfer-Resource.md
    # @see https://wiki.duraspace.org/display/DPNC/BagIt+Specification
    class Replication
      extend Forwardable

      # Most of the replication fields are read-only fields, but some of them
      # are updated during the bag replication process and those have setters.
      def_delegators :@replication,
        :replication_id,
        :bag,
        :cancelled, :cancelled=,
        :cancel_reason, :cancel_reason=,
        :cancel_reason_detail, :cancel_reason_detail=,
        :created_at, :updated_at,
        :fixity_algorithm,
        :fixity_nonce,
        :fixity_value, :fixity_value=,
        :link,
        :from_node, :to_node,
        :protocol,
        :store_requested,
        :stored, :stored=

      # @param [Hash] replication transfer resource
      def initialize(replication)
        @replication = OpenStruct.new(replication)
      end

      # Replication Request ID - the unique (UUIDv4) identifier for this replication request
      # @return [String] replication_id
      def id
        replication_id
      end

      # Replication Bag ID - the unique (UUIDv4) identifier for the DPN bag
      # @return [String] bag_id
      def bag_id
        @bag_id ||= bag
      end

      # Replication file - the basename for the replication link
      # @return [String] file
      def file
        @file ||= File.basename(link)
      end

      # @return [Hash]
      def to_h
        @replication.to_h
      end

      # Administrative from_node that issued the replication transfer request
      # @return [DPN::Workers::Node] admin node
      def admin_node
        @admin_node ||= DPN::Workers.nodes.node(from_node)
      end

      # Administrative from_node client
      # @return [DPN::Client::Agent] admin client
      def admin_client
        admin_node.client
      end

      # Local to_node responding to the replication transfer request
      # @return [DPN::Workers::Node] local node
      def local_node
        @local_node ||= DPN::Workers.nodes.node(to_node)
      end

      # Local to_node client
      # @return [DPN::Client::Agent] local client
      def local_client
        local_node.client
      end

      # Update the replication transfer resource on the remote node
      # @return [Boolean]
      def update_admin
        update admin_client
      end

      # Update the replication transfer resource on the local node
      # @return [Boolean]
      def update_local
        # create it, if necessary, and update it
        create(local_client) && update(local_client)
      end

      # Update the replication transfer resource on a node
      # @param [DPN::Client::Agent] node client
      # @return [Boolean]
      # @raise [RuntimeError]
      def update(client = admin_client)
        # assume the replication exists, try to update it
        response = client.update_replication(to_h)
        data = response.body
        raise "Failed to update replication: #{data}" unless response.success?
        @replication = OpenStruct.new(data)
        true
      end

      # Create the replication transfer resource on a node
      # @param [DPN::Client::Agent] node client
      # @return [Boolean]
      # @raise [RuntimeError]
      def create(client)
        # to create a replication, first the bag record must be present
        return true if client.replication(id).status == 200
        bag_record_create(client)
        response = client.create_replication(to_h)
        raise "Failed to create replication: #{response.body}" unless response.success?
        true
      end

      # Retrieve the bag record from the admin node
      def bag_record
        @bag_record ||= begin
          response = admin_client.bag(bag)
          data = response.body
          raise "Failed to retrieve bag record: #{data}" unless response.success?
          OpenStruct.new(data)
        end
      end

      # Create the bag record on a node
      # @param [DPN::Client::Agent] node client
      # @return [Boolean]
      # @raise [RuntimeError]
      def bag_record_create(client)
        return true if client.bag(bag).status == 200
        response = client.create_bag bag_record.to_h
        raise "Failed to create bag record: #{response.body}" unless response.success?
        true
      end
    end
  end
end
