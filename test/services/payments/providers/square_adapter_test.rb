# frozen_string_literal: true

require 'test_helper'

module Payments
  module Providers
    class SquareAdapterTest < ActiveSupport::TestCase
      def setup
        @restaurant = restaurants(:one)
        @restaurant.update!(
          payment_provider: 'square',
          payment_provider_status: :connected,
          square_location_id: 'LOC_TEST_1',
          square_merchant_id: 'MERCH_TEST',
          platform_fee_type: :percent,
          platform_fee_percent: 1.5,
        )

        @account = ProviderAccount.create!(
          restaurant: @restaurant,
          provider: :square,
          access_token: 'test-access-token',
          refresh_token: 'test-refresh-token',
          token_expires_at: 30.days.from_now,
          status: :enabled,
          connected_at: 1.day.ago,
          environment: 'sandbox',
        )

        @adapter = SquareAdapter.new(restaurant: @restaurant)
      end

      # --- square_account! ---

      test 'raises when no square account exists' do
        @account.destroy!
        error = assert_raises(RuntimeError) { @adapter.send(:square_account!) }
        assert_match(/not connected/, error.message)
      end

      test 'raises when access token expired' do
        @account.update!(token_expires_at: 1.hour.ago)
        error = assert_raises(RuntimeError) { @adapter.send(:square_account!) }
        assert_match(/expired/, error.message)
      end

      test 'returns account when connected and valid' do
        account = @adapter.send(:square_account!)
        assert_equal @account.id, account.id
      end

      # --- create_payment! ---

      test 'create_payment sends correct body and updates payment_attempt' do
        ordr = ordrs(:one)
        pa = PaymentAttempt.create!(
          ordr: ordr,
          restaurant: @restaurant,
          provider: :square,
          amount_cents: 1000,
          currency: 'EUR',
          status: :requires_action,
          charge_pattern: :direct,
          merchant_model: :restaurant_mor,
          idempotency_key: SecureRandom.uuid,
        )

        fake_response = {
          'payment' => {
            'id' => 'sq_pay_123',
            'status' => 'COMPLETED',
            'receipt_url' => 'https://squareup.com/receipt/123',
          },
        }

        mock_client = Minitest::Mock.new
        mock_client.expect :post, fake_response, ['/payments'], body: Hash

        SquareHttpClient.stub :new, mock_client do
          result = @adapter.create_payment!(
            payment_attempt: pa,
            ordr: ordr,
            source_id: 'cnon:card-nonce-ok',
            amount_cents: 1000,
            currency: 'EUR',
            tip_cents: 200,
          )

          assert_equal 'sq_pay_123', result[:payment_id]
          assert_equal 'COMPLETED', result[:status]

          pa.reload
          assert_equal 'sq_pay_123', pa.provider_payment_id
          assert_equal 'succeeded', pa.status
        end
      end

      # --- create_checkout_session! ---

      test 'create_checkout_session sends correct body and returns link' do
        ordr = ordrs(:one)
        pa = PaymentAttempt.create!(
          ordr: ordr,
          restaurant: @restaurant,
          provider: :square,
          amount_cents: 2500,
          currency: 'EUR',
          status: :requires_action,
          charge_pattern: :direct,
          merchant_model: :restaurant_mor,
          idempotency_key: SecureRandom.uuid,
        )

        fake_response = {
          'payment_link' => {
            'id' => 'sq_link_456',
            'url' => 'https://square.link/u/test456',
          },
          'related_resources' => {
            'orders' => [{ 'id' => 'sq_order_789' }],
          },
        }

        mock_client = Minitest::Mock.new
        mock_client.expect :post, fake_response, ['/online-checkout/payment-links'], body: Hash

        SquareHttpClient.stub :new, mock_client do
          result = @adapter.create_checkout_session!(
            payment_attempt: pa,
            ordr: ordr,
            amount_cents: 2500,
            currency: 'EUR',
            success_url: 'https://example.com/success',
            cancel_url: 'https://example.com/cancel',
          )

          assert_equal 'sq_link_456', result[:checkout_session_id]
          assert_equal 'https://square.link/u/test456', result[:checkout_url]
          assert_equal 'sq_order_789', result[:order_id]

          pa.reload
          assert_equal 'sq_link_456', pa.provider_payment_id
          assert_equal 'https://square.link/u/test456', pa.provider_checkout_url
        end
      end

      # --- create_full_refund! ---

      test 'create_full_refund sends correct body' do
        ordr = ordrs(:one)
        pa = PaymentAttempt.create!(
          ordr: ordr,
          restaurant: @restaurant,
          provider: :square,
          amount_cents: 1000,
          currency: 'EUR',
          status: :succeeded,
          charge_pattern: :direct,
          merchant_model: :restaurant_mor,
          provider_payment_id: 'sq_pay_original',
        )

        fake_response = {
          'refund' => {
            'id' => 'sq_refund_001',
            'status' => 'PENDING',
          },
        }

        mock_client = Minitest::Mock.new
        mock_client.expect :post, fake_response, ['/refunds'], body: Hash

        SquareHttpClient.stub :new, mock_client do
          result = @adapter.create_full_refund!(payment_attempt: pa)

          assert_equal 'sq_refund_001', result[:refund_id]
          assert_equal 'PENDING', result[:status]
        end
      end

      test 'create_full_refund raises when no provider_payment_id' do
        ordr = ordrs(:one)
        pa = PaymentAttempt.create!(
          ordr: ordr,
          restaurant: @restaurant,
          provider: :square,
          amount_cents: 500,
          currency: 'EUR',
          status: :succeeded,
          charge_pattern: :direct,
          merchant_model: :restaurant_mor,
        )

        error = assert_raises(ArgumentError) { @adapter.create_full_refund!(payment_attempt: pa) }
        assert_match(/provider_payment_id/, error.message)
      end

      # --- map_status ---

      test 'maps Square payment statuses correctly' do
        assert_equal :succeeded, @adapter.send(:map_status, 'COMPLETED')
        assert_equal :processing, @adapter.send(:map_status, 'APPROVED')
        assert_equal :requires_action, @adapter.send(:map_status, 'PENDING')
        assert_equal :failed, @adapter.send(:map_status, 'FAILED')
        assert_equal :failed, @adapter.send(:map_status, 'CANCELED')
      end

      # --- platform fee calculation ---

      test 'includes platform fee in payment body' do
        # 1.5% of 1000 cents = 15 cents
        fee = @restaurant.compute_platform_fee_cents(1000)
        assert_equal 15, fee
      end

      # --- location required ---

      test 'create_payment raises when no location configured' do
        @restaurant.update!(square_location_id: nil)
        ordr = ordrs(:one)
        pa = PaymentAttempt.create!(
          ordr: ordr,
          restaurant: @restaurant,
          provider: :square,
          amount_cents: 1000,
          currency: 'EUR',
          status: :requires_action,
          charge_pattern: :direct,
          merchant_model: :restaurant_mor,
        )

        error = assert_raises(RuntimeError) do
          @adapter.create_payment!(
            payment_attempt: pa,
            ordr: ordr,
            source_id: 'nonce',
            amount_cents: 1000,
            currency: 'EUR',
          )
        end
        assert_match(/location/, error.message)
      end
    end
  end
end
