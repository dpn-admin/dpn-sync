# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::Sync do
  subject { described_class.new(local_node, remote_node) }

  describe '#new' do
    it 'works' do
      expect(subject).not_to be_nil
    end
    it 'provides accessor for local_node' do
      expect(subject.local_node).to be_an DPN::Workers::Node
    end
    it 'provides accessor for remote_node' do
      expect(subject.remote_node).to be_an DPN::Workers::Node
    end
    it 'provides accessor for local_client' do
      expect(subject.local_client).to be_an DPN::Client::Agent
    end
    it 'provides accessor for remote_client' do
      expect(subject.remote_client).to be_an DPN::Client::Agent
    end
  end

  describe '#sync' do
    it 'is an abstract method that raises NotImplementedError' do
      expect { subject.sync }.to raise_error(NotImplementedError)
    end
  end

  context 'private' do
    describe '#job_data' do
      let(:job_data) { subject.send(:job_data) }
      it 'works' do
        expect(job_data).to be_an DPN::Workers::JobData
      end
      it 'is used to read job data' do
        expect(subject).to receive(:job_data).and_return(job_data)
        expect(job_data).to receive(:last_success).with(remote_node.namespace)
        subject.send(:last_success)
      end
      it 'is used to write job data' do
        expect(subject).to receive(:job_data).and_return(job_data)
        expect(job_data).to receive(:last_success_update).with(remote_node.namespace)
        subject.send(:last_success_update)
      end
    end

    describe '#logger' do
      let(:logger) { subject.send(:logger) }
      it 'works' do
        expect(logger).to be_an Logger
      end
    end
  end
end
