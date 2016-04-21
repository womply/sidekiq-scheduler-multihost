require 'spec_helper'

describe SidekiqSchedulerMultihost::Workers::Defibrillator do
  describe '#perform' do
    it 'calls SideKiqSchedulerMultihost::Heartbeat#start' do
      runner = double('heartbeat_runner')
      expect(SidekiqSchedulerMultihost::Heartbeat).to receive(:new).and_return(runner)
      expect(runner).to receive(:start)
      SidekiqSchedulerMultihost::Workers::Defibrillator.new.perform
    end
  end

  describe '.clear_jobs!' do
    let(:scheduled_set){ double Sidekiq::ScheduledSet }
    let(:hard_worker){ OpenStruct.new(klass: 'HardWorker') }
    let(:slow_worker){ OpenStruct.new(klass: 'SlowWorker') }
    let(:defibrillator){ OpenStruct.new(klass: 'SidekiqSchedulerMultihost::Workers::Defibrillator') }

    before do
      expect(Sidekiq::ScheduledSet).to receive(:new).and_return(scheduled_set)
      expect(scheduled_set).to receive(:each)
        .and_yield(hard_worker)
        .and_yield(slow_worker)
        .and_yield(defibrillator)
    end

    it 'removes all Defibrillator jobs from the list' do
      expect(defibrillator).to receive(:delete)
      expect(hard_worker).not_to receive(:delete)
      expect(slow_worker).not_to receive(:delete)
      SidekiqSchedulerMultihost::Workers::Defibrillator.clear_jobs!
    end
  end
end
