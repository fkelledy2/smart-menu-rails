ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'simplecov'
require 'minitest/mock'

# Start SimpleCov with Rails profile and optional coverage minimum for CI
SimpleCov.start 'rails' do
  add_filter %w[bin/ config/ db/ vendor/ app/channels/ app/mailers/ app/jobs/]
  track_files 'app/**/*.rb'
  enable_coverage :branch

  if ENV['COVERAGE_MIN']
    minimum_coverage ENV['COVERAGE_MIN'].to_i
    refuse_coverage_drop
  end
end

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
