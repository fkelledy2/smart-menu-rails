# Start SimpleCov BEFORE loading any application code
require 'simplecov'
# SimpleCov configuration is loaded from .simplecov file

SimpleCov.formatter = SimpleCov::Formatter::SimpleFormatter

ENV['RAILS_ENV'] ||= 'test'

# Speed optimizations for test environment
ENV['DISABLE_SPRING'] = '1' unless ENV['ENABLE_SPRING']
ENV['RAILS_LOG_LEVEL'] = 'error' # Reduce logging overhead

require_relative '../config/environment'
require 'rails/test_help'

# Use test adapter for Active Job in tests
ActiveJob::Base.queue_adapter = :test
require 'minitest/mock'

# Disable ActionCable in tests for speed
ActionCable.server.config.disable_request_forgery_protection = true

module ActiveSupport
  class TestCase
    # Parallel testing disabled to show real-time "..." progress
    # To enable parallel testing, uncomment the lines below:
    # workers = ENV['RAILS_PARALLEL_WORKERS']&.to_i || 2
    # parallelize(workers: workers)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    # Load all test helpers from test/support/**/*.rb
    Rails.root.glob('test/support/**/*.rb').each { |f| require f }

    # Include test helpers
    include Devise::Test::IntegrationHelpers
    include Warden::Test::Helpers
    include ActionDispatch::TestProcess::FixtureFile

    def log_in(user)
      if defined?(ActionDispatch::SystemTestCase) && is_a?(ActionDispatch::SystemTestCase)
        login_as(user, scope: :user)
      elsif respond_to?(:integration_test?) && integration_test?
        login_as(user, scope: :user)
      else
        sign_in(user)
      end
    end

    # Ensure Warden is in test mode and sessions are cleaned between tests
    Warden.test_mode!

    teardown do
      Warden.test_reset!
    end
  end
end
