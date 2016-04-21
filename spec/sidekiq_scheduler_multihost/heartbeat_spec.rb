require 'spec_helper'

describe SidekiqSchedulerMultihost::Heartbeat do
  subject{SidekiqSchedulerMultihost::Heartbeat.new}

  describe('#start') do
    before do
      Timecop.freeze
      t = time.to_f.to_s
      Sidekiq.redis{|r| r.set SidekiqSchedulerMultihost::Heartbeat::CACHE_KEY, t}
    end

    after{ Timecop.return }

    context 'when someone else is managing the schedule' do
      context "but the heartbeat hasn't happened in longer than the timeout threshold" do
        let(:time){ Time.now - (SidekiqSchedulerMultihost::Heartbeat::TIMEOUT + 1) }
        it 'takes over running the schedule' do
          expect(subject).to receive(:take_over_scheduling!)
          subject.start
        end
      end
      context 'and the heartbeat is recent' do
        let(:time){ Time.now - (SidekiqSchedulerMultihost::Heartbeat::TIMEOUT/4) }
        it 'clears its own scheduler' do
          expect(subject).to receive(:clear_schedules!)
          subject.start
        end
      end
    end

    context 'when the current process is managing the schedule' do
      let(:time){ Time.now - (SidekiqSchedulerMultihost::Heartbeat::HEARTBEAT) }
      before{ SidekiqSchedulerMultihost::Heartbeat.class_variable_set :@@timestamp, time.to_f.to_s }

      it 'resets the job that handles failing over' do
        expect(SidekiqSchedulerMultihost::Workers::Defibrillator).to receive(:clear_jobs!)
        expect(SidekiqSchedulerMultihost::Workers::Defibrillator).to receive(:perform_in).with(SidekiqSchedulerMultihost::Heartbeat::TIMEOUT)
        subject.start
      end
      it 'starts a counter for the next heartbeat' do
        expect_any_instance_of(Rufus::Scheduler).to receive(:in).with("#{SidekiqSchedulerMultihost::Heartbeat::HEARTBEAT}s")
        subject.start
      end
    end
  end
end
