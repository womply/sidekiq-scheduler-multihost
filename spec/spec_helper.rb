$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'pry'
require 'sidekiq_scheduler_multihost'
require 'timecop'
require 'ostruct'
