# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagReplication, :vcr do
  let(:admin_node) { nodes.node('hathi') }

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
    if ENV['TRAVIS']
      # Replace the replication file :link with a fixture file; this is
      # required for an integration test to pass on travis.ci
      local_tarfile = File.join(Dir.pwd, 'fixtures', 'testbags', '00000000-0000-4000-a000-000000000003.tar')
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
