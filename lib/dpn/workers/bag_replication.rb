# This class adapts some state and logic from dpn-server, i.e.
# https://github.com/dpn-admin/dpn-server
# The code in dpn-server is governed by the following copyright notice:
# Copyright (c) 2015 The Regents of the University of Michigan.
# All Rights Reserved.
# Licensed according to the terms of the Revised BSD License
# See LICENSE.md for details.

require_relative 'bag_paths'
require_relative 'bag_rsync'

module DPN
  module Workers
    ##
    # A Bag Replication-Transfer-Resource
    # @see https://github.com/dpn-admin/DPN-REST-Wiki/blob/master/Replication-Transfer-Resource.md
    # @see https://wiki.duraspace.org/display/DPNC/BagIt+Specification
    class BagReplication

      # @param [Hash] replication transfer resource
      def initialize(replication)
        @replication = DPN::Workers::Replication.new(replication)
        @paths = DPN::Workers::BagPaths.new
      end

      # @return [Boolean] success
      def transfer
        raise NotImplementedError, "This #{self.class} cannot respond to: transfer"
      end

      private

        attr_reader :paths
        attr_reader :replication

        #
        # Utils
        #

        # @return [String] staging_path
        def staging_path
          @staging_path ||= paths.staging(replication.id)
        end

        # @return [String] storage_path
        def storage_path
          @storage_path ||= paths.storage(replication.bag)
        end
    end
  end
end
