# Sidekiq::Scheduler::Multihost

This gem is intended to be a plug-and-play solution for running sidekiq-scheduler in a multi-host environment. It relies on Sidekiq's Redis instance for storing a heartbeat, rufus-scheduler (a depedency of sidekiq-scheduler) for the actual heartbeating, and Sidekiq for running a task called Defibrillator which will cause another host to take over if the current scheduler goes down.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-scheduler-multihost', require: sidekiq_scheduler_multihost
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-scheduler-multihost

## Usage

Just include the gem and it will set up the heartbeat, place a defibrillator job in the queue, and start sidekiq-scheduler. You will still need to load the schedule yourself, with an initializer that does something like:

```ruby
config.on(:startup) do
  Sidekiq.schedule = YAML.load_file(File.expand_path("../../scheduler.yml",__FILE__))
end
```

See the sidekiq-scheduler and sidekiq docs for more information.

## Known Issues

  * There could be a race condition, if multiple hosts write the exact same heartbeat timestamp at the exact same time. It's not likely as the resolution is pretty high but it could happen.

  * There's not currently a way to configure the heartbeat frequency.

  * When the host that is running the schedule dies, no schedule will be run for a period of time up to two heartbeats. Heartbeats happen every 30 seconds currently.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Womply/sidekiq-scheduler-multihost.
