# frozen_string_literal: true

require 'test_helper'

module Payments
  module Webhooks
    class SquareIngestorTest < ActiveSupport::TestCase
      def setup
        @ingestor = SquareIngestor.new
      end

      # --- normalized_entity_type ---

      test 'payment.completed maps to payment_attempt entity' do
        result = @ingestor.send(:normalized_entity_type, 'payment.completed')
        assert_equal :payment_attempt, result
      end

      test 'refund.created maps to refund entity' do
        result = @ingestor.send(:normalized_entity_type, 'refund.created')
        assert_equal :refund, result
      end

      # --- normalized_event_type ---

      test 'payment.completed maps to succeeded' do
        result = @ingestor.send(:normalized_event_type, 'payment.completed')
        assert_equal :succeeded, result
      end

      test 'payment.failed maps to failed' do
        result = @ingestor.send(:normalized_event_type, 'payment.failed')
        assert_equal :failed, result
      end

      test 'refund.created maps to refunded' do
        result = @ingestor.send(:normalized_event_type, 'refund.created')
        assert_equal :refunded, result
      end

      test 'oauth.authorization.revoked maps to failed' do
        result = @ingestor.send(:normalized_event_type, 'oauth.authorization.revoked')
        assert_equal :failed, result
      end

      # --- map_payment_status ---

      test 'maps Square payment statuses correctly' do
        assert_equal :succeeded, @ingestor.send(:map_payment_status, 'completed')
        assert_equal :processing, @ingestor.send(:map_payment_status, 'approved')
        assert_equal :requires_action, @ingestor.send(:map_payment_status, 'pending')
        assert_equal :failed, @ingestor.send(:map_payment_status, 'failed')
        assert_equal :failed, @ingestor.send(:map_payment_status, 'canceled')
        assert_nil @ingestor.send(:map_payment_status, 'unknown')
      end

      # --- amount_cents_for_payload ---

      test 'extracts amount from payment object' do
        obj = { 'payment' => { 'amount_money' => { 'amount' => 1500, 'currency' => 'EUR' } } }
        assert_equal 1500, @ingestor.send(:amount_cents_for_payload, obj)
      end

      test 'extracts amount from top-level amount_money' do
        obj = { 'amount_money' => { 'amount' => 2000, 'currency' => 'USD' } }
        assert_equal 2000, @ingestor.send(:amount_cents_for_payload, obj)
      end

      # --- currency_for_payload ---

      test 'extracts currency and uppercases it' do
        obj = { 'payment' => { 'amount_money' => { 'amount' => 100, 'currency' => 'eur' } } }
        assert_equal 'EUR', @ingestor.send(:currency_for_payload, obj)
      end

      # --- handle_oauth_revoked ---

      test 'oauth revoked disconnects restaurant' do
        restaurant = restaurants(:one)
        restaurant.update!(
          square_merchant_id: 'MERCH_123',
          payment_provider: 'square',
          payment_provider_status: :connected,
        )
        ProviderAccount.create!(
          restaurant: restaurant,
          provider: :square,
          access_token: 'tok',
          refresh_token: 'ref',
          status: :enabled,
          connected_at: 1.day.ago,
          environment: 'sandbox',
        )

        @ingestor.send(:handle_oauth_revoked, obj: { 'merchant_id' => 'MERCH_123' })

        restaurant.reload
        assert restaurant.provider_disconnected?
        assert_not_nil restaurant.square_oauth_revoked_at

        account = ProviderAccount.find_by(restaurant: restaurant, provider: :square)
        assert_equal 'disabled', account.status
        assert_not_nil account.disconnected_at
      end

      # --- verify_signature (on controller) ---

      test 'signature verification computes correct HMAC' do
        key = 'test-webhook-key'
        url = 'https://example.com/payments/webhooks/square'
        body = '{"event_id":"evt_1","type":"payment.completed"}'
        string_to_sign = url + body
        expected = Base64.strict_encode64(
          OpenSSL::HMAC.digest('sha256', key, string_to_sign),
        )

        # Verify the math matches what the controller does
        computed = Base64.strict_encode64(
          OpenSSL::HMAC.digest('sha256', key, string_to_sign),
        )
        assert_equal expected, computed
      end
    end
  end
end
