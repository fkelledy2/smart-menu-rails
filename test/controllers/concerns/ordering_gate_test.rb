require 'test_helper'

class OrderingGateTest < ActiveSupport::TestCase
  # Test the concern's logic directly via a minimal test controller
  class FakeController
    include OrderingGate

    attr_accessor :format_html_called, :format_json_called, :current_user

    def respond_to
      yield(self)
    end

    def html
      @format_html_called = true
    end

    def json
      @format_json_called = true
    end

    def redirect_back_or_to(*); end
    def render(*); end
    def root_path = '/'
  end

  def setup
    @restaurant = restaurants(:one)
  end

  test 'ensure_ordering_enabled! returns true when ordering_enabled' do
    @restaurant.update_columns(ordering_enabled: true)
    controller = FakeController.new
    assert controller.send(:ensure_ordering_enabled!, @restaurant)
  end

  test 'ensure_ordering_enabled! returns true when restaurant is nil' do
    controller = FakeController.new
    assert controller.send(:ensure_ordering_enabled!, nil)
  end

  test 'ensure_ordering_enabled! returns true for claimed restaurant even if ordering disabled' do
    @restaurant.update_columns(ordering_enabled: false, claim_status: 2) # claimed
    controller = FakeController.new
    assert controller.send(:ensure_ordering_enabled!, @restaurant)
  end

  test 'ensure_payments_enabled! returns true when payments_enabled' do
    @restaurant.update_columns(payments_enabled: true)
    controller = FakeController.new
    assert controller.send(:ensure_payments_enabled!, @restaurant)
  end

  test 'ensure_payments_enabled! returns false when payments disabled' do
    @restaurant.update_columns(payments_enabled: false)
    controller = FakeController.new
    result = controller.send(:ensure_payments_enabled!, @restaurant)
    assert_equal false, result
  end
end
