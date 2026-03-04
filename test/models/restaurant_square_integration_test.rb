# frozen_string_literal: true

require 'test_helper'

class RestaurantSquareIntegrationTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  # --- payment_provider_status enum ---

  test 'payment_provider_status defaults to disconnected' do
    assert_equal 'disconnected', @restaurant.payment_provider_status
  end

  test 'payment_provider_status enum has expected values' do
    expected = { 'disconnected' => 0, 'connected' => 10, 'degraded' => 20 }
    assert_equal expected, Restaurant.payment_provider_statuses
  end

  test 'payment_provider_status uses prefix provider' do
    @restaurant.payment_provider_status = :connected
    assert @restaurant.provider_connected?
    assert_not @restaurant.provider_disconnected?
  end

  # --- square_checkout_mode enum ---

  test 'square_checkout_mode defaults to inline' do
    assert_equal 'inline', @restaurant.square_checkout_mode
  end

  test 'square_checkout_mode enum has expected values' do
    expected = { 'inline' => 0, 'hosted' => 10 }
    assert_equal expected, Restaurant.square_checkout_modes
  end

  test 'square_checkout_mode uses prefix square' do
    @restaurant.square_checkout_mode = :hosted
    assert @restaurant.square_hosted?
    assert_not @restaurant.square_inline?
  end

  # --- platform_fee_type enum ---

  test 'platform_fee_type defaults to none' do
    assert_equal 'none', @restaurant.platform_fee_type
  end

  test 'platform_fee_type enum has expected values' do
    expected = { 'none' => 0, 'percent' => 10, 'fixed' => 20, 'percent_plus_fixed' => 30 }
    assert_equal expected, Restaurant.platform_fee_types
  end

  # --- provider detection helpers ---

  test 'stripe_provider? returns true when payment_provider is stripe' do
    @restaurant.payment_provider = 'stripe'
    assert @restaurant.stripe_provider?
    assert_not @restaurant.square_provider?
  end

  test 'square_provider? returns true when payment_provider is square' do
    @restaurant.payment_provider = 'square'
    assert @restaurant.square_provider?
    assert_not @restaurant.stripe_provider?
  end

  test 'square_connected? requires both square provider and connected status' do
    @restaurant.payment_provider = 'square'
    @restaurant.payment_provider_status = :connected
    assert @restaurant.square_connected?

    @restaurant.payment_provider_status = :disconnected
    assert_not @restaurant.square_connected?

    @restaurant.payment_provider = 'stripe'
    @restaurant.payment_provider_status = :connected
    assert_not @restaurant.square_connected?
  end

  # --- compute_platform_fee_cents ---

  test 'compute_platform_fee_cents returns 0 for none' do
    @restaurant.platform_fee_type = :none
    assert_equal 0, @restaurant.compute_platform_fee_cents(10_000)
  end

  test 'compute_platform_fee_cents calculates percent correctly' do
    @restaurant.platform_fee_type = :percent
    @restaurant.platform_fee_percent = 1.5
    # 10000 * 1.5/100 = 150
    assert_equal 150, @restaurant.compute_platform_fee_cents(10_000)
  end

  test 'compute_platform_fee_cents rounds percent up' do
    @restaurant.platform_fee_type = :percent
    @restaurant.platform_fee_percent = 1.5
    # 999 * 1.5/100 = 14.985 → ceil = 15
    assert_equal 15, @restaurant.compute_platform_fee_cents(999)
  end

  test 'compute_platform_fee_cents returns fixed amount' do
    @restaurant.platform_fee_type = :fixed
    @restaurant.platform_fee_fixed_cents = 50
    assert_equal 50, @restaurant.compute_platform_fee_cents(10_000)
  end

  test 'compute_platform_fee_cents combines percent plus fixed' do
    @restaurant.platform_fee_type = :percent_plus_fixed
    @restaurant.platform_fee_percent = 1.5
    @restaurant.platform_fee_fixed_cents = 30
    # 10000 * 1.5/100 = 150 (ceil) + 30 = 180
    assert_equal 180, @restaurant.compute_platform_fee_cents(10_000)
  end

  test 'compute_platform_fee_cents handles zero amount' do
    @restaurant.platform_fee_type = :percent
    @restaurant.platform_fee_percent = 1.5
    assert_equal 0, @restaurant.compute_platform_fee_cents(0)
  end

  # --- payment_provider column ---

  test 'payment_provider defaults to stripe' do
    assert_equal 'stripe', @restaurant.payment_provider
  end
end
