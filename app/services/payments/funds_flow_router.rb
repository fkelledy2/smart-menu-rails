module Payments
  class FundsFlowRouter
    class << self
      def charge_pattern_for(provider:, merchant_model:, restaurant: nil)
        merchant_model = merchant_model.to_sym

        case merchant_model
        when :smartmenu_mor
          :destination
        else
          :direct
        end
      end
    end
  end
end
