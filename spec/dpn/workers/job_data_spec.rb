# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::JobData do
  let(:name) { 'job_name' }
  let(:namespace) { 'namespace' }
  subject { described_class.new(name) }

  describe '#new' do
    it 'works' do
      expect(subject).to be_an described_class
    end
  end

  describe '#last_success' do
    let(:result) { subject.last_success(namespace) }

    it 'works' do
      expect(result).not_to be_nil
    end

    it 'returns a Time' do
      expect(result).to be_an Time
    end

    it 'returns a saved Time' do
      subject.last_success_update(namespace)
      time_saved = Time.now.utc
      expect(result.to_f).to be_within(1.0).of(time_saved.to_f)
    end

    it 'defaults to the year 2000' do
      year_2000 = Time.utc(2000, 01, 01, 0, 0, 0)
      expect(subject).to receive(:data_get).and_return({})
      expect(result).to eq year_2000
    end
  end

  describe '#last_success_update' do
    let(:result) { subject.last_success_update(namespace) }
    it 'works' do
      expect(result).not_to be_nil
    end

    it 'returns True on success' do
      expect(result).to be true
    end

    it 'returns False on failure' do
      expect(REDIS).to receive(:set).and_raise(Redis::BaseError)
      expect(result).to be false
    end
  end
end
