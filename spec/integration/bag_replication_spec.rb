# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagReplication, :vcr do
  let(:admin_node) { nodes.node('chron') }

  # let(:settings) { SyncSettings.replication }

  def replication_transfer
    admin_node.client.replications do |response|
      rep = response.body
      return rep if rep[:to_node] == local_node.namespace
    end
  end

  it 'works' do
    # Get a replication from an admin node for this local node.
    repl = replication_transfer
    # Ensure that this test replication transfer has logical fields that
    # require the bag to be transferred.
    expect(repl[:store_requested]).to be true
    expect(repl[:stored]).to be false
    expect(repl[:cancelled]).to be false
    if ENV['TRAVIS']
      # Replace the replication file :link with a fixture file; this is
      # required for an integration test to pass on travis.ci
      tar_filename = File.basename repl[:link]
      local_tarfile = File.join(Dir.pwd, 'fixtures', 'testbags', tar_filename)
      expect(File.exist?(local_tarfile)).to be true
      repl[:link] = local_tarfile
    end
    # Replicate the bag
    subject = described_class.new repl
    expect(subject.replicate).to be true
    bagit = subject.send(:bagit)
    expect(File.exist?(bagit.location)).to be true
  end
end
