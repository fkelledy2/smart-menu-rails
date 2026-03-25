# frozen_string_literal: true

require 'test_helper'

class OrdrAutoPayTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @tablesetting = tablesettings(:one)
    @ordr = ordrs(:one)
    @ordr.update!(
      gross: 42.00,
      tip: 0,
      payment_on_file: false,
      payment_method_ref: nil,
      auto_pay_enabled: false,
    )
  end

  # Column defaults

  test 'payment_on_file defaults to false' do
    ordr = Ordr.new(restaurant: @restaurant, menu: @menu, tablesetting: @tablesetting)
    assert_equal false, ordr.payment_on_file
  end

  test 'auto_pay_enabled defaults to false' do
    ordr = Ordr.new(restaurant: @restaurant, menu: @menu, tablesetting: @tablesetting)
    assert_equal false, ordr.auto_pay_enabled
  end

  # auto_pay_armed? helper

  test 'auto_pay_armed? returns true when both flags set' do
    @ordr.payment_on_file = true
    @ordr.auto_pay_enabled = true
    assert @ordr.auto_pay_armed?
  end

  test 'auto_pay_armed? returns false when payment_on_file is false' do
    @ordr.payment_on_file = false
    @ordr.auto_pay_enabled = true
    assert_not @ordr.auto_pay_armed?
  end

  test 'auto_pay_armed? returns false when auto_pay_enabled is false' do
    @ordr.payment_on_file = true
    @ordr.auto_pay_enabled = false
    assert_not @ordr.auto_pay_armed?
  end

  # auto_pay_capturable? helper

  test 'auto_pay_capturable? returns true when armed with positive gross and not yet succeeded' do
    @ordr.payment_on_file = true
    @ordr.auto_pay_enabled = true
    @ordr.gross = 10.00
    @ordr.auto_pay_status = nil
    assert @ordr.auto_pay_capturable?
  end

  test 'auto_pay_capturable? returns false when already succeeded' do
    @ordr.payment_on_file = true
    @ordr.auto_pay_enabled = true
    @ordr.gross = 10.00
    @ordr.auto_pay_status = 'succeeded'
    assert_not @ordr.auto_pay_capturable?
  end

  test 'auto_pay_capturable? returns false when gross is zero' do
    @ordr.payment_on_file = true
    @ordr.auto_pay_enabled = true
    @ordr.gross = 0
    assert_not @ordr.auto_pay_capturable?
  end

  # disarm_auto_pay_if_totals_changed!

  test 'disarm_auto_pay_if_totals_changed! disarms when gross will change' do
    @ordr.update!(payment_on_file: true, auto_pay_enabled: true, auto_pay_consent_at: Time.current, gross: 10.00)

    @ordr.gross = 15.00 # simulate change
    @ordr.disarm_auto_pay_if_totals_changed!
    assert_equal false, @ordr.auto_pay_enabled
    assert_nil @ordr.auto_pay_consent_at
  end

  test 'disarm_auto_pay_if_totals_changed! is a no-op when auto_pay is not enabled' do
    @ordr.update!(payment_on_file: true, auto_pay_enabled: false, gross: 10.00)

    @ordr.gross = 15.00
    @ordr.disarm_auto_pay_if_totals_changed!
    assert_equal false, @ordr.auto_pay_enabled # still false — no change
  end

  # Ordraction enum extensions

  test 'ordraction enum includes auto_pay actions' do
    assert Ordraction.actions.key?('payment_method_added')
    assert Ordraction.actions.key?('auto_pay_enabled')
    assert Ordraction.actions.key?('auto_pay_succeeded')
    assert Ordraction.actions.key?('auto_pay_failed')
    assert Ordraction.actions.key?('manual_capture')
    assert Ordraction.actions.key?('bill_viewed')
  end
end
