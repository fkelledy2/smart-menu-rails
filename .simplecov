# SimpleCov configuration
SimpleCov.start 'rails' do
  # Filter out directories we don't want to track
  add_filter '/bin/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
  add_filter '/app/channels/'
  add_filter '/app/mailers/'
  add_filter '/app/jobs/'
  add_filter '/test/'
  add_filter '/spec/'
  add_filter '/lib/tasks/'

  # Track all Ruby files in app directory
  track_files 'app/**/*.rb'

  # Enable branch coverage for more detailed analysis
  enable_coverage :branch

  # Merge results from different test runs (RSpec + Minitest)
  use_merging true
  merge_timeout 3600 # 1 hour

  # Coverage groups for better organization
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Helpers', 'app/helpers'
  add_group 'Views', 'app/views'
  add_group 'Policies', 'app/policies'

  # Minimum coverage thresholds
  if ENV['COVERAGE_MIN']
    minimum_coverage ENV['COVERAGE_MIN'].to_i
    refuse_coverage_drop
  end
end
