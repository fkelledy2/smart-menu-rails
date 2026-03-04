module Payments
  module Providers
    class BaseAdapter
      def create_checkout_session!(payment_attempt:, ordr:, amount_cents:, currency:, success_url:, cancel_url:)
        raise NotImplementedError
      end

      def create_full_refund!(payment_attempt:)
        raise NotImplementedError
      end

      # Inline payment (e.g. Square Web Payments SDK card nonce)
      def create_payment!(payment_attempt:, ordr:, source_id:,
                          amount_cents:, currency:, tip_cents: 0,
                          verification_token: nil)
        raise NotImplementedError
      end

      # Credential lifecycle (e.g. Square OAuth token refresh)
      def refresh_credentials!(provider_account:)
        raise NotImplementedError
      end
    end
  end
end
