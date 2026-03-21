# frozen_string_literal: true

require 'test_helper'

class RestaurantSubscriptionTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  def build_sub(attrs = {})
    RestaurantSubscription.new({ restaurant: @restaurant, status: :inactive }.merge(attrs))
  end

  # === VALIDATIONS ===

  test 'valid with required fields' do
    sub = build_sub
    assert sub.valid?, sub.errors.full_messages.join(', ')
  end

  test 'invalid without status' do
    sub = build_sub(status: nil)
    assert_not sub.valid?
    assert sub.errors[:status].any?
  end

  # === ENUM ===

  test 'status enum values are correct' do
    sub = build_sub
    %i[inactive trialing active past_due canceled].each do |s|
      sub.status = s
      assert_equal s.to_s, sub.status
    end
  end

  # === active_or_trialing_with_payment_method? ===

  test 'returns true when active with payment method on file' do
    sub = build_sub(status: :active, payment_method_on_file: true)
    assert sub.active_or_trialing_with_payment_method?
  end

  test 'returns true when trialing with payment method on file' do
    sub = build_sub(status: :trialing, payment_method_on_file: true)
    assert sub.active_or_trialing_with_payment_method?
  end

  test 'returns false when active but no payment method on file' do
    sub = build_sub(status: :active, payment_method_on_file: false)
    assert_not sub.active_or_trialing_with_payment_method?
  end

  test 'returns false when trialing but no payment method on file' do
    sub = build_sub(status: :trialing, payment_method_on_file: false)
    assert_not sub.active_or_trialing_with_payment_method?
  end

  test 'returns false when past_due even with payment method on file' do
    sub = build_sub(status: :past_due, payment_method_on_file: true)
    assert_not sub.active_or_trialing_with_payment_method?
  end

  test 'returns false when canceled even with payment method on file' do
    sub = build_sub(status: :canceled, payment_method_on_file: true)
    assert_not sub.active_or_trialing_with_payment_method?
  end

  test 'returns false when inactive even with payment method on file' do
    sub = build_sub(status: :inactive, payment_method_on_file: true)
    assert_not sub.active_or_trialing_with_payment_method?
  end
end
