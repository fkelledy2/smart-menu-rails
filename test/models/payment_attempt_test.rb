# frozen_string_literal: true

require 'test_helper'

class PaymentAttemptTest < ActiveSupport::TestCase
  def build_attempt(overrides = {})
    attrs = {
      ordr: ordrs(:one),
      restaurant: restaurants(:one),
      provider: :stripe,
      amount_cents: 1000,
      currency: 'USD',
      status: :requires_action,
      charge_pattern: :direct,
      merchant_model: :restaurant_mor,
    }.merge(overrides)
    PaymentAttempt.new(attrs)
  end

  # =========================================================================
  # validations
  # =========================================================================

  test 'is valid with all required attributes' do
    assert build_attempt.valid?
  end

  test 'is invalid without amount_cents' do
    attempt = build_attempt(amount_cents: nil)
    assert_not attempt.valid?
    assert attempt.errors[:amount_cents].any?
  end

  test 'is invalid with zero amount_cents' do
    attempt = build_attempt(amount_cents: 0)
    assert_not attempt.valid?
    assert attempt.errors[:amount_cents].any?
  end

  test 'is invalid with negative amount_cents' do
    attempt = build_attempt(amount_cents: -100)
    assert_not attempt.valid?
    assert attempt.errors[:amount_cents].any?
  end

  test 'is invalid without currency' do
    attempt = build_attempt(currency: nil)
    assert_not attempt.valid?
    assert attempt.errors[:currency].any?
  end

  test 'has all required fields to be valid' do
    # All enum fields have DB defaults so a complete record is valid
    attempt = build_attempt
    assert attempt.valid?, attempt.errors.full_messages.join(', ')
  end

  test 'idempotency_key must be unique when present' do
    key = "idem-#{SecureRandom.hex(8)}"

    first = build_attempt(idempotency_key: key)
    first.save!

    second = build_attempt(idempotency_key: key)
    assert_not second.valid?
    assert second.errors[:idempotency_key].any?
  end

  test 'idempotency_key can be nil for multiple records' do
    a1 = build_attempt(idempotency_key: nil)
    a1.save!

    a2 = build_attempt(idempotency_key: nil)
    assert a2.valid?
  end

  # =========================================================================
  # enums
  # =========================================================================

  test 'provider enum has stripe and square' do
    attempt = build_attempt(provider: :stripe)
    assert attempt.stripe?

    attempt2 = build_attempt(provider: :square)
    assert attempt2.square?
  end

  test 'status enum transitions' do
    attempt = build_attempt
    assert attempt.requires_action?

    attempt.status = :succeeded
    assert attempt.succeeded?
  end

  test 'charge_pattern enum has direct, destination, and separate' do
    %i[direct destination separate].each do |pattern|
      attempt = build_attempt(charge_pattern: pattern)
      assert_equal pattern.to_s, attempt.charge_pattern
    end
  end

  test 'merchant_model enum has restaurant_mor and smartmenu_mor' do
    attempt = build_attempt(merchant_model: :smartmenu_mor)
    assert attempt.smartmenu_mor?
  end
end
