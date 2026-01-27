require 'test_helper'

class Payments::FundsFlowRouterTest < ActiveSupport::TestCase
  test 'charge_pattern_for maps merchant_model to a charge_pattern' do
    assert_equal :direct, Payments::FundsFlowRouter.charge_pattern_for(provider: :stripe, merchant_model: :restaurant_mor)
    assert_equal :destination, Payments::FundsFlowRouter.charge_pattern_for(provider: :stripe, merchant_model: :smartmenu_mor)
  end
end
