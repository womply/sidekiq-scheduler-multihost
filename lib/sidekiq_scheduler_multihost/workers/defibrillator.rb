module SidekiqSchedulerMultihost
  module Workers
    class Defibrillator
      include Sidekiq::Worker
      sidekiq_options :queue => :defibrillator

      def perform
        SidekiqSchedulerMultihost::Heartbeat.new.start
      end

      def self.clear_jobs!
        Sidekiq::ScheduledSet.new.each do |scheduled_job|
          scheduled_job.delete if scheduled_job.klass == 'SidekiqSchedulerMultihost::Workers::Defibrillator'
        end
      end
    end
  end
end
