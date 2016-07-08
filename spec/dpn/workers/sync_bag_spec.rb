# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::SyncBag, :vcr do
  let(:bag) do
    {
      :uuid=>"00000000-0000-4000-a000-000000000002",
      :local_id=>"Chronopolis Bag 1",
      :size=>71680,
      :version=>1,
      :created_at=>"2015-09-15T17:56:03Z",
      :updated_at=>"2015-09-15T17:56:03Z",
      :ingest_node=>"chron",
      :admin_node=>"chron",
      :member=>"9a000000-0000-4000-a000-000000000001",
      :interpretive=>[],
      :rights=>[],
      :replicating_nodes=>[],
      :bag_type=>"D",
      :first_version_uuid=>"00000000-0000-4000-a000-000000000002",
      :fixities=>{:sha256=>"cd9c918c4ca76842febfc70ed27873c70a7e98f436bd2061e4b714092ffcae5b"}
    }
  end
  let(:local_client) { local_node.client }
  let(:logger) { Logger.new(File::NULL) }
  subject { described_class.new bag, local_client, logger }

  describe '#create_or_update' do
    it 'calls #create_bag' do
      expect(subject).to receive(:create_bag).and_return(true)
      expect(subject).not_to receive(:update_bag)
      subject.create_or_update
    end
    it 'calls #update_bag when #create_bag fails' do
      expect(subject).to receive(:create_bag).and_return(false)
      expect(subject).to receive(:update_bag).and_return(true)
      subject.create_or_update
    end
    it 'logs exceptions' do
      error = RuntimeError.new 'create bag failure'
      expect(subject).to receive(:create_bag).and_raise(error)
      expect(subject).not_to receive(:update_bag)
      expect(logger).to receive(:error).with(/FAILED/)
      expect(logger).to receive(:error).with(/create bag failure/)
      subject.create_or_update
    end
  end

  ##
  # PRIVATE

  describe '#bag_id' do
    it 'returns a bag UUID' do
      id = subject.send(:bag_id)
      expect(id).to be_an String
      expect(id).to eq bag[:uuid]
    end
  end

  describe '#create_bag' do
    context 'success' do
      before do
        response = double('response')
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return('horray!')
        allow(response).to receive(:status).and_return(200)
        allow(local_client).to receive(:create_bag).and_return(response)
      end
      it 'returns true for successful requests to local_client.create_bag' do
        expect(subject.send(:create_bag)).to be true
      end
      it 'logs info from requests to local_client.create_bag' do
        expect(logger).to receive(:info).at_least(:once).and_call_original
        expect(subject.send(:create_bag)).to be true
      end
    end
    context 'failure' do
      before do
        response = double('response')
        allow(response).to receive(:success?).and_return(false)
        allow(response).to receive(:body).and_return('error message')
        allow(response).to receive(:status).and_return(400)
        allow(local_client).to receive(:create_bag).and_return(response)
      end
      it 'returns false for failing requests to local_client.create_bag' do
        expect(subject.send(:create_bag)).to be false
      end
      it 'logs errors from requests to local_client.create_bag' do
        expect(logger).to receive(:error).at_least(:once).and_call_original
        expect(subject.send(:create_bag)).to be false
      end
    end
  end

  describe '#update_bag' do
    context 'success' do
      before do
        response = double('response')
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return('horray!')
        allow(response).to receive(:status).and_return(200)
        allow(local_client).to receive(:update_bag).and_return(response)
      end
      it 'returns true for successful requests to local_client.update_bag' do
        expect(subject.send(:update_bag)).to be true
      end
      it 'logs info from requests to local_client.update_bag' do
        expect(logger).to receive(:info).at_least(:once).and_call_original
        expect(subject.send(:update_bag)).to be true
      end
    end
    context 'failure' do
      before do
        response = double('response')
        allow(response).to receive(:success?).and_return(false)
        allow(response).to receive(:body).and_return('error message')
        allow(response).to receive(:status).and_return(400)
        allow(local_client).to receive(:update_bag).and_return(response)
      end
      it 'returns false for failing requests to local_client.update_bag' do
        expect(subject.send(:update_bag)).to be false
      end
      it 'logs errors from requests to local_client.update_bag' do
        expect(logger).to receive(:error).at_least(:once).and_call_original
        expect(subject.send(:update_bag)).to be false
      end
    end
  end
end
