# frozen_string_literal: true

require 'test_helper'

module Square
  class HealthCheckJobTest < ActiveSupport::TestCase
    def setup
      @restaurant = restaurants(:one)
      @restaurant.update!(payment_provider: 'square', payment_provider_status: :connected)
      @account = ProviderAccount.create!(
        restaurant: @restaurant,
        provider: :square,
        access_token: 'test-token',
        refresh_token: 'test-refresh',
        token_expires_at: 30.days.from_now,
        status: :enabled,
        connected_at: 1.day.ago,
        environment: 'sandbox',
      )
    end

    test 'healthy connection stays connected' do
      fake_response = Minitest::Mock.new
      fake_response.expect :success?, true
      fake_response.expect :parsed_response, { 'locations' => [{ 'id' => 'LOC_1' }] }

      HTTParty.stub :send, fake_response do
        HealthCheckJob.perform_now
      end

      @restaurant.reload
      assert @restaurant.provider_connected?
    end

    test 'restores degraded connection when API responds OK' do
      @restaurant.update!(payment_provider_status: :degraded)

      fake_response = Minitest::Mock.new
      fake_response.expect :success?, true
      fake_response.expect :parsed_response, { 'locations' => [{ 'id' => 'LOC_1' }] }

      HTTParty.stub :send, fake_response do
        HealthCheckJob.perform_now
      end

      @restaurant.reload
      assert @restaurant.provider_connected?
    end

    test 'marks restaurant degraded on non-401 API error' do
      error = Payments::Providers::SquareHttpClient::SquareApiError.new(
        'Server error', status_code: 500, errors: [], category: 'API_ERROR'
      )

      fake_client = Minitest::Mock.new
      fake_client.expect :get, nil do
        raise error
      end

      Payments::Providers::SquareHttpClient.stub :new, fake_client do
        HealthCheckJob.perform_now
      end

      @restaurant.reload
      assert @restaurant.provider_degraded?
      @account.reload
      assert_equal 'enabled', @account.status
    end

    test 'marks restaurant disconnected on 401 error' do
      error = Payments::Providers::SquareHttpClient::SquareApiError.new(
        'Unauthorized', status_code: 401, errors: [], category: 'AUTHENTICATION_ERROR'
      )

      fake_client = Minitest::Mock.new
      fake_client.expect :get, nil do
        raise error
      end

      Payments::Providers::SquareHttpClient.stub :new, fake_client do
        HealthCheckJob.perform_now
      end

      @restaurant.reload
      assert @restaurant.provider_disconnected?
      @account.reload
      assert_equal 'disabled', @account.status
      assert_not_nil @account.disconnected_at
    end

    test 'continues processing on unexpected errors' do
      # Stub to raise a generic error
      Payments::Providers::SquareHttpClient.stub :new, ->(*_args, **_opts) {
        raise StandardError, 'unexpected'
      } do
        assert_nothing_raised { HealthCheckJob.perform_now }
      end
    end
  end
end
