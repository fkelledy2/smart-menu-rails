# frozen_string_literal: true

require 'test_helper'

module Payments
  module Providers
    class SquareConnectTest < ActiveSupport::TestCase
      def setup
        @restaurant = restaurants(:one)
        @service = SquareConnect.new(restaurant: @restaurant)
      end

      # --- authorize_url ---

      test 'authorize_url builds correct URL with params' do
        url = @service.authorize_url(
          redirect_uri: 'https://example.com/callback',
          state: 'abc123',
        )

        assert_includes url, SquareConfig.oauth_base_url
        assert_includes url, '/authorize?'
        assert_includes url, "client_id=#{SquareConfig.client_id}" if SquareConfig.client_id.present?
        assert_includes url, 'state=abc123'
        assert_includes url, 'redirect_uri='
        assert_includes url, 'scope='
      end

      test 'authorize_url includes all required scopes' do
        url = @service.authorize_url(redirect_uri: 'https://example.com/cb', state: 'x')
        SquareConfig.oauth_scopes.each do |scope|
          assert_includes url, scope
        end
      end

      # --- exchange_code! ---

      test 'exchange_code creates provider account and updates restaurant' do
        fake_token_response = {
          'access_token' => 'sq-access-token-123',
          'refresh_token' => 'sq-refresh-token-456',
          'expires_at' => '2026-06-01T00:00:00Z',
          'merchant_id' => 'MERCHANT_ABC',
          'short_lived' => false,
        }

        fake_locations_response = {
          'locations' => [
            { 'id' => 'LOC_1', 'name' => 'Main Street', 'status' => 'ACTIVE' },
          ],
        }

        # Stub oauth_post for token exchange
        call_count = 0
        @service.stub(:oauth_post, ->(_path, _body, **_opts) {
          call_count += 1
          fake_token_response
        }) do
          # Stub fetch_locations
          @service.stub(:fetch_locations, fake_locations_response['locations']) do
            result = @service.exchange_code!(code: 'auth-code-xyz', redirect_uri: 'https://example.com/cb')

            assert_equal 'MERCHANT_ABC', result[:merchant_id]
            assert_equal 1, result[:locations].length

            # Verify ProviderAccount was created
            account = ProviderAccount.find_by(restaurant: @restaurant, provider: :square)
            assert_not_nil account
            assert_equal 'enabled', account.status
            assert_not_nil account.connected_at
            assert_nil account.disconnected_at

            # Verify restaurant was updated
            @restaurant.reload
            assert_equal 'square', @restaurant.payment_provider
            assert @restaurant.provider_connected?
            assert_equal 'MERCHANT_ABC', @restaurant.square_merchant_id

            # Auto-selected single location
            assert_equal 'LOC_1', @restaurant.square_location_id
          end
        end
      end

      # --- revoke! ---

      test 'revoke marks account and restaurant as disconnected' do
        # Create a provider account first
        account = ProviderAccount.create!(
          restaurant: @restaurant,
          provider: :square,
          access_token: 'tok',
          refresh_token: 'ref',
          status: :enabled,
          connected_at: 1.day.ago,
          environment: 'sandbox',
        )
        @restaurant.update!(payment_provider: 'square', payment_provider_status: :connected)

        # Stub the oauth_post to not actually call Square
        @service.stub(:oauth_post, ->(_path, _body, **_opts) { {} }) do
          result = @service.revoke!
          assert result

          account.reload
          assert_equal 'disabled', account.status
          assert_not_nil account.disconnected_at

          @restaurant.reload
          assert @restaurant.provider_disconnected?
          assert_not_nil @restaurant.square_oauth_revoked_at
        end
      end

      test 'revoke returns false when no account exists' do
        result = @service.revoke!
        assert_not result
      end

      # --- refresh_token! ---

      test 'refresh_token updates tokens on account' do
        account = ProviderAccount.create!(
          restaurant: @restaurant,
          provider: :square,
          access_token: 'old-access',
          refresh_token: 'old-refresh',
          token_expires_at: 1.day.from_now,
          status: :enabled,
          connected_at: 1.day.ago,
          environment: 'sandbox',
        )

        fake_response = {
          'access_token' => 'new-access-token',
          'refresh_token' => 'new-refresh-token',
          'expires_at' => '2026-09-01T00:00:00Z',
        }

        @service.stub(:oauth_post, ->(_path, _body, **_opts) { fake_response }) do
          returned = @service.refresh_token!(provider_account: account)

          account.reload
          assert_equal 'new-access-token', account.access_token
          assert_equal 'new-refresh-token', account.refresh_token
          assert_equal returned.id, account.id
        end
      end
    end
  end
end
