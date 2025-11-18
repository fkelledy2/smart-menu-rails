# frozen_string_literal: true

# Sidekiq maintenance tasks
# Usage:
#   bundle exec rake sidekiq:clear_queues
#   QUEUES=default,limited bundle exec rake sidekiq:clear_queues

namespace :sidekiq do
  desc "Clear Sidekiq queues (all queues by default), plus scheduled, retries, and dead sets.\n" \
       "Use QUEUES=queue1,queue2 to only clear specific queues."
  task clear_queues: :environment do
    require 'sidekiq/api'

    queues = ENV['QUEUES']&.split(',')&.map(&:strip)&.reject(&:blank?)

    if queues.present?
      queues.each do |q|
        Sidekiq::Queue.new(q).clear
        puts "Cleared queue: #{q}"
      end
    else
      Sidekiq::Queue.all.each do |q|
        q.clear
        puts "Cleared queue: #{q.name}"
      end
    end

    Sidekiq::ScheduledSet.new.clear
    puts 'Cleared scheduled set'

    Sidekiq::RetrySet.new.clear
    puts 'Cleared retries set'

    Sidekiq::DeadSet.new.clear
    puts 'Cleared dead set'

    puts 'Sidekiq cleanup complete.'
  end
end
