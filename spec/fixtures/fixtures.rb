module DPN
  ##
  # Simple fixture data for common specs
  module Fixtures
    extend RSpec::SharedContext

    # This logger replaces most logging files with /dev/null
    let(:null_logger) { Logger.new(File::NULL) }

    # Nodes are defined in SyncSettings.nodes
    # @see config/settings.yml, config/settings/test.yml
    let(:nodes) { DPN::Workers.nodes }
    let(:local_node) { nodes.local_node }
    let(:remote_node) { nodes.remote_nodes.first }

    # This example_node is used for specs where a node should fail to respond
    let(:example_node) do
      DPN::Workers::Node.new(
        namespace: 'example',
        api_root: 'http://node.example.org',
        auth_credential: 'example_token'
      )
    end

    # A DPN replication request
    # @see https://github.com/dpn-admin/DPN-REST-Wiki/blob/master/Replication-Transfer-Resource.md
    # @see https://github.com/dpn-admin/dpn-server/blob/master/app/models/replication_transfer.rb
    # @see https://wiki.duraspace.org/display/DPNC/BagIt+Specification
    let(:replication) do
      {
        # String of the unique (UUIDv4) identifier for this replication request
        replication_id: '20000000-0000-4000-a000-000000000007',
        # String of the namespace of the node sending the bag
        from_node: 'chron',
        # String of the namespace of the node receiving the bag
        to_node: 'aptrust',
        # The bag ID (UUIDv4) to be transferred
        bag: '00000000-0000-4000-a000-000000000002',
        # String of the fixity algorithm expected for the receipt
        fixity_algorithm: 'sha256',
        # null or a string of the nonce to be used for verification
        fixity_nonce: nil,
        # null or string of the fixity calculated by the to_node after
        # transferring the bag to its staging area. Calculated on the
        # serialized bag file received from the from_node
        fixity_value: nil,
        # null or boolean set by the from_node to indicate whether the
        # to_node's fixity digest was correct
        fixity_accept: nil,
        # null or boolean set by to_node to record results of bag validation
        bag_valid: nil,
        # status - String status of the transfer:
        #  'requested' - set by the from_node to indicate the bag is staged for transfer and awaiting response from to_node.
        #  'rejected' - set by the to_node to indicate it will not perform the transfer.
        #  'received' - set by the to_node to indicate it has performed the transfer.
        #  'confirmed' - set by the from_node after it receives all data to confirm a good transfer.
        #  'stored' - set by the to_node to indicate the bag has been transferred into its storage repository from the staging area. The to_node promises to fulfill replicating node duties by setting this status.
        #  'cancelled' - set by either node to indicate the transfer was cancelled.
        status: 'requested',
        # String used to identify the transfer protocol
        protocol: 'rsync',
        # String of transfer link to be used for the specified protocol
        link: '/data/src/dlss/dpn/dpn-server/test/fixtures/integration/testbags/00000000-0000-4000-a000-000000000002.tar',
        # String in DPN DateTime Format of the record creation date
        created_at: '2015-09-15T19:38:31Z',
        # String in DPN DateTime Format of last record update
        updated_at: '2015-09-15T19:38:31Z',
      }
    end
  end
end
