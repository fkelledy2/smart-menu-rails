# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrationErrorLogTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @valid_attrs = {
      restaurant: @restaurant,
      adapter_type: 'null',
      event_type: 'order.payment.succeeded',
      payload_json: { event_type: 'order.payment.succeeded' },
      error_message: 'StandardError: Test failure',
      attempt_number: 1,
    }
  end

  test 'is valid with all required attributes' do
    log = PartnerIntegrationErrorLog.new(@valid_attrs)
    assert log.valid?
  end

  test 'requires restaurant' do
    log = PartnerIntegrationErrorLog.new(@valid_attrs.merge(restaurant: nil))
    assert log.invalid?
  end

  test 'requires adapter_type' do
    log = PartnerIntegrationErrorLog.new(@valid_attrs.merge(adapter_type: nil))
    assert log.invalid?
    assert_includes log.errors[:adapter_type], "can't be blank"
  end

  test 'requires event_type' do
    log = PartnerIntegrationErrorLog.new(@valid_attrs.merge(event_type: nil))
    assert log.invalid?
    assert_includes log.errors[:event_type], "can't be blank"
  end

  test 'requires error_message' do
    log = PartnerIntegrationErrorLog.new(@valid_attrs.merge(error_message: nil))
    assert log.invalid?
    assert_includes log.errors[:error_message], "can't be blank"
  end

  test 'requires attempt_number to be positive integer' do
    log = PartnerIntegrationErrorLog.new(@valid_attrs.merge(attempt_number: 0))
    assert log.invalid?
    log2 = PartnerIntegrationErrorLog.new(@valid_attrs.merge(attempt_number: -1))
    assert log2.invalid?
  end

  test 'recent scope orders by created_at desc' do
    old_log = PartnerIntegrationErrorLog.create!(@valid_attrs.merge(created_at: 2.hours.ago))
    new_log = PartnerIntegrationErrorLog.create!(@valid_attrs.merge(created_at: 1.hour.ago))
    recent = PartnerIntegrationErrorLog.recent.where(restaurant: @restaurant)
    assert_equal new_log.id, recent.first.id
    old_log.destroy
    new_log.destroy
  end

  test 'for_restaurant scope filters by restaurant_id' do
    other_restaurant = restaurants(:two)
    log_one = PartnerIntegrationErrorLog.create!(@valid_attrs)
    log_two = PartnerIntegrationErrorLog.create!(@valid_attrs.merge(restaurant: other_restaurant))
    results = PartnerIntegrationErrorLog.for_restaurant(@restaurant.id)
    assert_includes results.pluck(:id), log_one.id
    assert_not_includes results.pluck(:id), log_two.id
    log_one.destroy
    log_two.destroy
  end

  test 'for_adapter scope filters by adapter_type' do
    log = PartnerIntegrationErrorLog.create!(@valid_attrs.merge(adapter_type: 'null'))
    results = PartnerIntegrationErrorLog.for_adapter('null')
    assert_includes results.pluck(:id), log.id
    assert_empty PartnerIntegrationErrorLog.for_adapter('nonexistent').pluck(:id)
    log.destroy
  end

  test 'fixture loads correctly' do
    log = partner_integration_error_logs(:one)
    assert log.persisted?
    assert_equal 'null', log.adapter_type
    assert_equal 3, log.attempt_number
  end
end
