# frozen_string_literal: true

require 'test_helper'

class PaymentRefundTest < ActiveSupport::TestCase
  def build_attempt
    PaymentAttempt.create!(
      ordr: ordrs(:one),
      restaurant: restaurants(:one),
      provider: :stripe,
      amount_cents: 1000,
      currency: 'USD',
      status: :requires_action,
      charge_pattern: :direct,
      merchant_model: :restaurant_mor,
    )
  end

  def build_refund(overrides = {})
    @attempt ||= build_attempt
    PaymentRefund.new({
      payment_attempt: @attempt,
      ordr: ordrs(:one),
      restaurant: restaurants(:one),
      provider: :stripe,
      status: :pending,
    }.merge(overrides))
  end

  test 'is valid with all required attributes' do
    assert build_refund.valid?
  end

  test 'requires provider' do
    refund = build_refund
    refund.provider = nil
    assert_not refund.valid?
  end

  test 'requires status' do
    refund = build_refund
    refund.status = nil
    assert_not refund.valid?
  end

  test 'stripe provider enum works' do
    assert build_refund(provider: :stripe).stripe?
  end

  test 'square provider enum works' do
    assert build_refund(provider: :square).square?
  end

  test 'pending status enum works' do
    assert build_refund(status: :pending).pending?
  end

  test 'processing status enum works' do
    assert build_refund(status: :processing).processing?
  end

  test 'succeeded status enum works' do
    assert build_refund(status: :succeeded).succeeded?
  end

  test 'failed status enum works' do
    assert build_refund(status: :failed).failed?
  end

  test 'canceled status enum works' do
    assert build_refund(status: :canceled).canceled?
  end

  test 'belongs to payment_attempt' do
    refund = build_refund
    refund.save!
    assert_equal @attempt, refund.payment_attempt
  end
end
