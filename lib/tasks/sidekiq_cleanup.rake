namespace :sidekiq do
  desc 'Clean up failed jobs and orphaned jobs'
  task cleanup: :environment do
    puts '🧹 Cleaning up Sidekiq jobs...'

    begin
      require 'sidekiq/api'

      # Clear failed jobs
      failed_count = Sidekiq::FailedSet.new.size
      if failed_count.positive?
        puts "  Clearing #{failed_count} failed jobs..."
        Sidekiq::FailedSet.new.clear
        puts '  ✅ Failed jobs cleared'
      else
        puts '  ✅ No failed jobs to clear'
      end

      # Clear retry jobs
      retry_count = Sidekiq::RetrySet.new.size
      if retry_count.positive?
        puts "  Clearing #{retry_count} retry jobs..."
        Sidekiq::RetrySet.new.clear
        puts '  ✅ Retry jobs cleared'
      else
        puts '  ✅ No retry jobs to clear'
      end

      # Clear scheduled jobs
      scheduled_count = Sidekiq::ScheduledSet.new.size
      if scheduled_count.positive?
        puts "  Found #{scheduled_count} scheduled jobs"
        puts '  ⚠️  Not clearing scheduled jobs (they may be legitimate)'
      else
        puts '  ✅ No scheduled jobs found'
      end

      puts '🎉 Sidekiq cleanup complete!'
    rescue LoadError
      puts '❌ Sidekiq not available - skipping cleanup'
    rescue StandardError => e
      puts "❌ Error during cleanup: #{e.message}"
    end
  end

  desc 'Show Sidekiq queue statistics'
  task stats: :environment do
    puts '📊 Sidekiq Queue Statistics:'

    begin
      require 'sidekiq/api'

      # Queue stats
      queues = Sidekiq::Queue.all
      if queues.any?
        puts "\n📋 Queues:"
        queues.each do |queue|
          puts "  #{queue.name}: #{queue.size} jobs"
        end
      else
        puts '  ✅ No active queues'
      end

      # Failed jobs
      failed_count = Sidekiq::FailedSet.new.size
      puts "\n❌ Failed jobs: #{failed_count}"

      # Retry jobs
      retry_count = Sidekiq::RetrySet.new.size
      puts "🔄 Retry jobs: #{retry_count}"

      # Scheduled jobs
      scheduled_count = Sidekiq::ScheduledSet.new.size
      puts "⏰ Scheduled jobs: #{scheduled_count}"

      # Workers
      workers = Sidekiq::Workers.new
      puts "👷 Active workers: #{workers.size}"

      # Processes
      processes = Sidekiq::ProcessSet.new
      puts "🔧 Processes: #{processes.size}"

      if failed_count.positive? || retry_count.positive?
        puts "\n💡 Run 'rails sidekiq:cleanup' to clear failed and retry jobs"
      end
    rescue LoadError
      puts '❌ Sidekiq not available'
    rescue StandardError => e
      puts "❌ Error getting stats: #{e.message}"
    end
  end

  desc 'Clear specific job types from queues'
  task :clear_job_type, [:job_class] => :environment do |_t, args|
    job_class = args[:job_class]

    unless job_class
      puts '❌ Please specify a job class: rails sidekiq:clear_job_type[ProcessPdfJob]'
      exit 1
    end

    puts "🧹 Clearing #{job_class} jobs from all queues..."

    begin
      require 'sidekiq/api'

      total_cleared = 0

      # Clear from all queues
      Sidekiq::Queue.find_each do |queue|
        cleared = 0
        queue.each do |job|
          if job.klass == job_class
            job.delete
            cleared += 1
          end
        end
        if cleared.positive?
          puts "  Cleared #{cleared} #{job_class} jobs from '#{queue.name}' queue"
          total_cleared += cleared
        end
      end

      # Clear from retry set
      retry_cleared = 0
      Sidekiq::RetrySet.new.each do |job|
        if job.klass == job_class
          job.delete
          retry_cleared += 1
        end
      end
      if retry_cleared.positive?
        puts "  Cleared #{retry_cleared} #{job_class} jobs from retry set"
        total_cleared += retry_cleared
      end

      # Clear from scheduled set
      scheduled_cleared = 0
      Sidekiq::ScheduledSet.new.each do |job|
        if job.klass == job_class
          job.delete
          scheduled_cleared += 1
        end
      end
      if scheduled_cleared.positive?
        puts "  Cleared #{scheduled_cleared} #{job_class} jobs from scheduled set"
        total_cleared += scheduled_cleared
      end

      puts "✅ Total cleared: #{total_cleared} #{job_class} jobs"
    rescue LoadError
      puts '❌ Sidekiq not available'
    rescue StandardError => e
      puts "❌ Error clearing jobs: #{e.message}"
    end
  end
end
