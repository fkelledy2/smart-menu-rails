# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Set the environment path for cron jobs
env :PATH, ENV['PATH']

# Materialized View Refresh Schedule
# High-priority views (restaurant analytics) - every 15 minutes
every 15.minutes do
  runner "MaterializedViewRefreshJob.perform_later(nil, 'high')"
end

# Medium-priority views (menu performance) - every 30 minutes  
every 30.minutes do
  runner "MaterializedViewRefreshJob.perform_later(nil, 'medium')"
end

# Low-priority views (system analytics) - every hour
every 1.hour do
  runner "MaterializedViewRefreshJob.perform_later(nil, 'low')"
end

# Health check for materialized views - every 2 hours
every 2.hours do
  runner "MaterializedViewHealthCheckJob.perform_later"
end

# Full refresh of all views during off-peak hours (3 AM daily)
every 1.day, at: '3:00 am' do
  runner "MaterializedViewRefreshJob.perform_later(nil, nil, true)" # force_refresh = true
end

# Learn more: http://github.com/javan/whenever
