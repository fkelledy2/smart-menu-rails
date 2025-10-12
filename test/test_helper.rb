# Start SimpleCov BEFORE loading any application code
require 'simplecov'
# SimpleCov configuration is loaded from .simplecov file

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

# Use test adapter for Active Job in tests
ActiveJob::Base.queue_adapter = :test
require 'minitest/mock'

module ActiveSupport
  class TestCase
    # Run tests in a single process to avoid state bleed in auth/system tests
    parallelize(workers: 1)

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
      if integration_test?
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
