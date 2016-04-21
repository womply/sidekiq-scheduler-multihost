require 'rubygems'
require 'bundler/setup'
require 'rufus-scheduler'
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq-scheduler'
require "sidekiq_scheduler_multihost/version"
require "sidekiq_scheduler_multihost/heartbeat"
require "sidekiq_scheduler_multihost/workers/defibrillator"

Sidekiq.configure_server do |config|
  config.on(:startup) do
    SidekiqSchedulerMultihost::Heartbeat.new.start
  end

  config.on(:shutdown) do
    SidekiqSchedulerMultihost::Heartbeat.new.stop
  end
end
