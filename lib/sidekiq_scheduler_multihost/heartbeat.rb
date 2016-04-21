module SidekiqSchedulerMultihost
  class Heartbeat
    TIMEOUT = 60 #seconds
    HEARTBEAT = TIMEOUT/2

    CACHE_KEY = :sidekiq_scheduler_heartbeat_timestamp

    @@timestamp = -1.0
    @@rufus = Rufus::Scheduler.new

    def start
      if i_own_the_scheduler?
        @@timestamp = set_timestamp! #update from heartbeat
        # App.logger.debug "container ##{ENV['DOCKER_INSTANCE']}: scheduler is MINE!"
        reset_failover_job!
        schedule_heartbeat
      elsif schedule_owner_exists? && timestamp_current?
        # App.logger.debug "container ##{ENV['DOCKER_INSTANCE']}: scheduler is NOT mine!"
        clear_schedules!
      else
        # App.logger.debug "container ##{ENV['DOCKER_INSTANCE']}: no owner found! I am taking over scheduling!"
        take_over_scheduling!
      end
    end

    def stop
      clear_schedules!
    end

    private

    def get_timestamp
      Sidekiq.redis{|r| r.get CACHE_KEY}
    end

    def set_timestamp!
      t = Time.now.to_f.to_s
      Sidekiq.redis{|r| r.set CACHE_KEY, t}
      t
    end

    def i_own_the_scheduler?
      @@timestamp == get_timestamp
    end

    def schedule_owner_exists?
      timestamp = Float(get_timestamp) rescue 0.0
      !timestamp.nil? && timestamp != 0.0
    end

    def timestamp_current?
      timestamp = get_timestamp
      # App.logger.debug "container ##{ENV['DOCKER_INSTANCE']}: timestamp is #{timestamp}, current is #{Time.now.to_f}!"
      (Time.now.to_f - Float(timestamp)) < TIMEOUT
    end

    def take_over_scheduling!
      @@timestamp = set_timestamp!
      # App.logger.debug "container ##{ENV['DOCKER_INSTANCE']}: timestamp set to #{@@timestamp}"
      sleep(rand 0.99) # sleep for a random amount of time, under a second
      if i_own_the_scheduler? #if not, no problem... someone else has it
        confirm_takeover!
      else
        # App.logger.debug "container ##{ENV['DOCKER_INSTANCE']}: someone else took over scheduling. My timestamp is #{@@timestamp}, and I found #{get_timestamp}"
      end
    end

    def confirm_takeover!
      # App.logger.debug "container ##{ENV['DOCKER_INSTANCE']}: I took over scheduling!"
      # App.logger.warn "A container has taken over the scheduler!"
      Sidekiq::Scheduler.enabled = true
      Sidekiq::Scheduler.reload_schedule!
      reset_failover_job!
      schedule_heartbeat
    end

    def reset_failover_job!
      SidekiqSchedulerMultihost::Workers::Defibrillator.clear_jobs!
      SidekiqSchedulerMultihost::Workers::Defibrillator.perform_in(TIMEOUT)
    end

    def clear_schedules!
      Sidekiq::Scheduler.enabled = false
      Sidekiq::Scheduler.clear_schedule! # in case we owned it previously and someone came in after
    end

    def schedule_heartbeat
      @@rufus.in("#{HEARTBEAT}s"){self.class.new.start}
    end
  end
end
