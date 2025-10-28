# SimpleCov configuration - optimized for speed
# Skip SimpleCov entirely if disabled for fast test runs
unless ENV['DISABLE_SIMPLECOV'] == '1'
  SimpleCov.start 'rails' do
    # Filter out directories we don't want to track (infrastructure only)
    add_filter '/bin/'
    add_filter '/config/'
    add_filter '/db/'
    add_filter '/vendor/'
    add_filter '/test/'
    add_filter '/spec/'
    add_filter '/lib/tasks/'

    # Filter out specific files that shouldn't be tested
    add_filter '/app/channels/application_cable/' # Base ActionCable classes

    # Track all Ruby files in app directory (including jobs, mailers, channels)
    track_files 'app/**/*.rb'

    # Enable branch coverage for more detailed analysis (disable for speed)
    enable_coverage :branch unless ENV['FAST_TESTS'] == '1'

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
    add_group 'Jobs', 'app/jobs'
    add_group 'Mailers', 'app/mailers'
    add_group 'Channels', 'app/channels'
    add_group 'Serializers', 'app/serializers'
    add_group 'Middleware', 'app/middleware'
    add_group 'Uploaders', 'app/uploaders'
    add_group 'Admin', 'app/madmin'

    # Minimum coverage thresholds
    if ENV['COVERAGE_MIN']
      minimum_coverage ENV['COVERAGE_MIN'].to_i
      refuse_coverage_drop
    end
  end
end
