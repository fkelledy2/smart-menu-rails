# frozen_string_literal: true

require 'test_helper'

class OrdrSplitPaymentTest < ActiveSupport::TestCase
  def build_split_payment(overrides = {})
    OrdrSplitPayment.new({
      ordr: ordrs(:one),
      provider: :stripe,
      split_method: :equal,
      amount_cents: 2500,
      currency: 'USD',
      status: :pending,
    }.merge(overrides))
  end

  # =========================================================================
  # validations
  # =========================================================================

  test 'is valid with all required attributes' do
    assert build_split_payment.valid?
  end

  test 'is invalid without amount_cents' do
    sp = build_split_payment(amount_cents: nil)
    assert_not sp.valid?
    assert sp.errors[:amount_cents].any?
  end

  test 'is invalid without currency' do
    sp = build_split_payment(currency: nil)
    assert_not sp.valid?
    assert sp.errors[:currency].any?
  end

  test 'idempotency_key uniqueness is enforced when present' do
    key = "split-idem-#{SecureRandom.hex(8)}"
    first = build_split_payment(idempotency_key: key)
    first.save!

    second = build_split_payment(idempotency_key: key)
    assert_not second.valid?
    assert second.errors[:idempotency_key].any?
  end

  test 'idempotency_key allows nil for multiple records' do
    s1 = build_split_payment(idempotency_key: nil)
    s1.save!

    s2 = build_split_payment(idempotency_key: nil)
    assert s2.valid?
  end

  # =========================================================================
  # enums
  # =========================================================================

  test 'provider enum has stripe and square' do
    assert build_split_payment(provider: :stripe).stripe?
    assert build_split_payment(provider: :square).square?
  end

  test 'split_method enum has all four methods' do
    %i[equal custom percentage item_based].each do |method|
      sp = build_split_payment(split_method: method)
      assert_equal method.to_s, sp.split_method
    end
  end

  test 'status enum has all statuses' do
    %i[pending requires_payment succeeded failed canceled].each do |status|
      sp = build_split_payment(status: status)
      assert_equal status.to_s, sp.status.to_s.tr(' ', '_')
    end
  end

  # =========================================================================
  # instance methods
  # =========================================================================

  test 'pay_ready? returns true when requires_payment' do
    sp = build_split_payment(status: :requires_payment)
    assert sp.pay_ready?
  end

  test 'pay_ready? returns true when failed' do
    sp = build_split_payment(status: :failed)
    assert sp.pay_ready?
  end

  test 'pay_ready? returns false when pending' do
    sp = build_split_payment(status: :pending)
    assert_not sp.pay_ready?
  end

  test 'pay_ready? returns false when succeeded' do
    sp = build_split_payment(status: :succeeded)
    assert_not sp.pay_ready?
  end

  test 'locked? returns true when locked_at is set' do
    sp = build_split_payment
    sp.locked_at = Time.current
    assert sp.locked?
  end

  test 'locked? returns false when locked_at is nil and no split plan' do
    sp = build_split_payment
    sp.locked_at = nil
    sp.ordr_split_plan = nil
    assert_not sp.locked?
  end
end
