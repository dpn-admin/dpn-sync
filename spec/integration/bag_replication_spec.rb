# -*- encoding: utf-8 -*-
require 'spec_helper'

# Note: to run this integration test properly, there are some manual steps
# involved to ensure it's not using some old VCR cassettes, i.e.
# rm -rf fixtures/vcr_cassettes/Bag_Replication

# # In the dpn-server project, run:
# git checkout master
# bundle install
# bundle exec rake config
# bundle exec rm db/*.sqlite3
# bundle exec ./script/setup_cluster.rb
# bundle exec ./script/run_cluster.rb -f

describe 'Bag_Replication', :vcr do
  it 'is able to transfer a bag to staging and storage' do
    # Get a replication from an admin node for this local node.
    repl = replication
    # Ensure that this test replication transfer has logical fields that
    # require the bag to be transferred.
    expect(repl[:store_requested]).to be false
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
    # Retrieve the bag
    bag_transfer = DPN::Workers::BagRetrieve.new repl
    expect(bag_transfer.transfer).to be true
    bagit = bag_transfer.send(:bagit)
    expect(File.exist?(bagit.location)).to be true
    # Retrieve the updated replication and store the bag
    repl = local_node.client.replication(repl[:replication_id]).body
    expect(repl[:store_requested]).to be true
    bag_store = DPN::Workers::BagStore.new repl
    expect(bag_store.transfer).to be true
    bagit = bag_store.send(:bagit)
    expect(File.exist?(bagit.location)).to be true
  end
end
