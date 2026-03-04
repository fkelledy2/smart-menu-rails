# frozen_string_literal: true

require 'test_helper'

module Square
  class RefreshTokenJobTest < ActiveSupport::TestCase
    def setup
      @restaurant = restaurants(:one)
      @restaurant.update!(payment_provider: 'square', payment_provider_status: :connected)
    end

    test 'refreshes accounts expiring within 7 days' do
      account = ProviderAccount.create!(
        restaurant: @restaurant,
        provider: :square,
        access_token: 'old-token',
        refresh_token: 'old-refresh',
        token_expires_at: 3.days.from_now,
        status: :enabled,
        connected_at: 1.day.ago,
        environment: 'sandbox',
      )

      fake_response = OpenStruct.new(
        success?: true,
        code: 200,
        parsed_response: {
          'access_token' => 'new-token',
          'refresh_token' => 'new-refresh',
          'expires_at' => 30.days.from_now.iso8601,
        },
      )

      # Stub HTTParty.post which is called by SquareConnect#oauth_post
      HTTParty.stub :post, ->(*_args, **_opts) { fake_response } do
        RefreshTokenJob.perform_now
      end

      account.reload
      assert_equal 'new-token', account.access_token
      assert_equal 'new-refresh', account.refresh_token
    end

    test 'skips accounts not expiring soon' do
      account = ProviderAccount.create!(
        restaurant: @restaurant,
        provider: :square,
        access_token: 'valid-token',
        refresh_token: 'valid-refresh',
        token_expires_at: 30.days.from_now,
        status: :enabled,
        connected_at: 1.day.ago,
        environment: 'sandbox',
      )

      # Should not call refresh at all — if it does, it'll fail because no stub
      RefreshTokenJob.perform_now

      account.reload
      assert_equal 'valid-token', account.access_token
    end

    test 'skips disabled accounts' do
      account = ProviderAccount.create!(
        restaurant: @restaurant,
        provider: :square,
        access_token: 'disabled-token',
        refresh_token: 'disabled-refresh',
        token_expires_at: 1.day.from_now,
        status: :disabled,
        connected_at: 1.day.ago,
        environment: 'sandbox',
      )

      # Should not process disabled accounts
      RefreshTokenJob.perform_now

      account.reload
      assert_equal 'disabled', account.status
    end

    test 'logs error but continues on failure' do
      ProviderAccount.create!(
        restaurant: @restaurant,
        provider: :square,
        access_token: 'fail-token',
        refresh_token: 'fail-refresh',
        token_expires_at: 2.days.from_now,
        status: :enabled,
        connected_at: 1.day.ago,
        environment: 'sandbox',
      )

      # Stub HTTParty.post to raise an error
      HTTParty.stub :post, ->(*_args, **_opts) { raise StandardError, 'refresh failed' } do
        assert_nothing_raised { RefreshTokenJob.perform_now }
      end
    end
  end
end
