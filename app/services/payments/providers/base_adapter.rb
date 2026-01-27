module Payments
  module Providers
    class BaseAdapter
      def create_checkout_session!(payment_attempt:, ordr:, amount_cents:, currency:, success_url:, cancel_url:)
        raise NotImplementedError
      end

      def create_full_refund!(payment_attempt:)
        raise NotImplementedError
      end
    end
  end
end
