# frozen_string_literal: true

module Payments
  module Providers
    # Square payment adapter — mirrors StripeAdapter interface.
    # Handles inline payments (Web Payments SDK), hosted checkout (payment links),
    # and full refunds.
    class SquareAdapter < BaseAdapter
      def initialize(restaurant:)
        @restaurant = restaurant
      end

      # Inline payment via Web Payments SDK card nonce / digital wallet token.
      def create_payment!(payment_attempt:, ordr:, source_id:,
                          amount_cents:, currency:, tip_cents: 0,
                          verification_token: nil)
        account = square_account!
        location_id = @restaurant.square_location_id
        raise 'Square location not configured' if location_id.blank?

        fee_cents = @restaurant.compute_platform_fee_cents(amount_cents + tip_cents)

        body = {
          idempotency_key: payment_attempt.idempotency_key || SecureRandom.uuid,
          source_id: source_id,
          amount_money: { amount: amount_cents, currency: currency.to_s.upcase },
          location_id: location_id,
          reference_id: ordr.id.to_s,
          note: "Order #{ordr.id}",
        }

        body[:tip_money] = { amount: tip_cents, currency: currency.to_s.upcase } if tip_cents.positive?
        body[:app_fee_money] = { amount: fee_cents, currency: currency.to_s.upcase } if fee_cents.positive?
        body[:verification_token] = verification_token if verification_token.present?

        client = http_client(account)
        result = client.post('/payments', body: body)

        payment = result['payment'] || {}
        payment_attempt.update!(
          provider_payment_id: payment['id'],
          status: map_status(payment['status']),
        )

        {
          payment_id: payment['id'],
          status: payment['status'],
          receipt_url: payment['receipt_url'],
        }
      end

      # Hosted checkout via Square payment links.
      def create_checkout_session!(payment_attempt:, ordr:, amount_cents:, currency:, success_url:, cancel_url:)
        account = square_account!
        location_id = @restaurant.square_location_id
        raise 'Square location not configured' if location_id.blank?

        fee_cents = @restaurant.compute_platform_fee_cents(amount_cents)

        body = {
          idempotency_key: payment_attempt.idempotency_key || SecureRandom.uuid,
          quick_pay: {
            name: "#{@restaurant.name} Order #{ordr.id}",
            price_money: { amount: amount_cents, currency: currency.to_s.upcase },
            location_id: location_id,
          },
          checkout_options: {
            redirect_url: success_url,
            allow_tipping: true,
          },
          pre_populated_data: {
            buyer_address: nil,
          },
        }

        body[:checkout_options][:app_fee_money] = { amount: fee_cents, currency: currency.to_s.upcase } if fee_cents.positive?

        client = http_client(account)
        result = client.post('/online-checkout/payment-links', body: body)

        link = result['payment_link'] || {}
        related = result['related_resources'] || {}
        order = (related['orders'] || []).first || {}

        payment_attempt.update!(
          provider_payment_id: link['id'],
          provider_checkout_url: link['url'],
        )

        {
          checkout_session_id: link['id'],
          checkout_url: link['url'],
          order_id: order['id'],
        }
      end

      # Full refund of a completed payment.
      def create_full_refund!(payment_attempt:)
        account = square_account!
        payment_id = payment_attempt.provider_payment_id.to_s
        raise ArgumentError, 'provider_payment_id is required to refund' if payment_id.blank?

        # Deterministic idempotency key: keyed on the payment_attempt id so that
        # Sidekiq retries (or admin double-clicks) send the same key to Square and
        # Square deduplicates the call instead of issuing a second refund.
        idempotency_key = "square_refund:pa_#{payment_attempt.id}"

        body = {
          idempotency_key: idempotency_key,
          payment_id: payment_id,
          reason: 'Full refund for order',
        }

        client = http_client(account)
        result = client.post('/refunds', body: body)

        refund = result['refund'] || {}
        { refund_id: refund['id'], status: refund['status'], raw: refund }
      end

      # Token refresh (delegates to SquareConnect).
      def refresh_credentials!(provider_account:)
        Payments::Providers::SquareConnect.new(restaurant: @restaurant)
          .refresh_token!(provider_account: provider_account)
      end

      private

      def square_account!
        account = ProviderAccount.find_by(restaurant: @restaurant, provider: :square, status: :enabled)
        raise 'Square account not connected or disabled' unless account
        raise 'Square access token expired' if account.token_expired?

        account
      end

      def http_client(account)
        SquareHttpClient.new(
          access_token: account.access_token,
          environment: account.environment || SquareConfig.environment,
        )
      end

      def map_status(square_status)
        case square_status.to_s.downcase
        when 'completed' then :succeeded
        when 'approved'  then :processing
        when 'pending'   then :requires_action
        when 'failed', 'canceled' then :failed
        else :requires_action
        end
      end
    end
  end
end
