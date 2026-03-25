# frozen_string_literal: true

require 'test_helper'

class AutoPayControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @restaurant = restaurants(:one)
    @user = @restaurant.user || users(:one)
    @restaurant.update!(user: @user) unless @restaurant.user_id == @user.id
    @ordr = ordrs(:one)
    @ordr.update!(
      status: 0, # opened
      gross: 42.00,
      tip: 0,
      payment_on_file: false,
      payment_method_ref: nil,
      auto_pay_enabled: false,
      auto_pay_status: nil,
    )
    # Enable Flipper for this restaurant
    Flipper.enable(:auto_pay, @restaurant)
  end

  def teardown
    Flipper.disable(:auto_pay, @restaurant)
    Flipper.disable(:auto_pay)
  end

  # ─── store_payment_method ─────────────────────────────────────────────────

  test 'store_payment_method sets payment_on_file for authenticated owner' do
    sign_in @user

    post payment_methods_restaurant_ordr_url(@restaurant, @ordr),
         params: { payment_method_id: 'pm_test_abc' },
         as: :json

    assert_response :ok
    body = response.parsed_body
    assert body['ok']
    assert body['payment_on_file']

    @ordr.reload
    assert @ordr.payment_on_file
    assert_equal 'pm_test_abc', @ordr.payment_method_ref
    assert_equal 'stripe', @ordr.payment_provider
  end

  test 'store_payment_method rejects blank payment_method_id' do
    sign_in @user

    post payment_methods_restaurant_ordr_url(@restaurant, @ordr),
         params: { payment_method_id: '' },
         as: :json

    assert_response :unprocessable_content
    assert_not response.parsed_body['ok']
  end

  test 'store_payment_method rejects invalid format (not pm_ prefix)' do
    sign_in @user

    post payment_methods_restaurant_ordr_url(@restaurant, @ordr),
         params: { payment_method_id: 'card_123' },
         as: :json

    assert_response :unprocessable_content
  end

  test 'store_payment_method returns 503 when feature flag disabled' do
    Flipper.disable(:auto_pay, @restaurant)
    sign_in @user

    post payment_methods_restaurant_ordr_url(@restaurant, @ordr),
         params: { payment_method_id: 'pm_test_abc' },
         as: :json

    assert_response :service_unavailable
  end

  # ─── remove_payment_method ────────────────────────────────────────────────

  test 'remove_payment_method clears payment data' do
    @ordr.update!(
      payment_on_file: true,
      payment_method_ref: 'pm_test_abc',
      payment_provider: 'stripe',
      auto_pay_enabled: true,
    )
    sign_in @user

    delete payment_methods_restaurant_ordr_url(@restaurant, @ordr), as: :json

    assert_response :ok
    @ordr.reload
    assert_not @ordr.payment_on_file
    assert_nil @ordr.payment_method_ref
    assert_not @ordr.auto_pay_enabled
  end

  # ─── toggle_auto_pay ──────────────────────────────────────────────────────

  test 'toggle_auto_pay enables auto_pay when payment is on file' do
    @ordr.update!(payment_on_file: true, payment_method_ref: 'pm_test_abc')
    sign_in @user

    post auto_pay_restaurant_ordr_url(@restaurant, @ordr),
         params: { enabled: true },
         as: :json

    assert_response :ok
    body = response.parsed_body
    assert body['ok']
    assert body['auto_pay_enabled']
    assert_not_nil body['auto_pay_consent_at']

    @ordr.reload
    assert @ordr.auto_pay_enabled
    assert_not_nil @ordr.auto_pay_consent_at
  end

  test 'toggle_auto_pay fails to enable when no payment method on file' do
    sign_in @user

    post auto_pay_restaurant_ordr_url(@restaurant, @ordr),
         params: { enabled: true },
         as: :json

    assert_response :unprocessable_content
    assert_not response.parsed_body['ok']
  end

  test 'toggle_auto_pay disables auto_pay' do
    @ordr.update!(payment_on_file: true, auto_pay_enabled: true, auto_pay_consent_at: Time.current)
    sign_in @user

    post auto_pay_restaurant_ordr_url(@restaurant, @ordr),
         params: { enabled: false },
         as: :json

    assert_response :ok
    @ordr.reload
    assert_not @ordr.auto_pay_enabled
  end

  # ─── view_bill ────────────────────────────────────────────────────────────

  test 'view_bill sets viewed_bill_at on first call' do
    sign_in @user

    post view_bill_restaurant_ordr_url(@restaurant, @ordr), as: :json

    assert_response :ok
    @ordr.reload
    assert_not_nil @ordr.viewed_bill_at
  end

  test 'view_bill is idempotent — does not change viewed_bill_at on subsequent calls' do
    existing_time = 1.hour.ago
    @ordr.update!(viewed_bill_at: existing_time)
    sign_in @user

    post view_bill_restaurant_ordr_url(@restaurant, @ordr), as: :json

    assert_response :ok
    @ordr.reload
    assert_in_delta existing_time.to_i, @ordr.viewed_bill_at.to_i, 1
  end

  # ─── capture ──────────────────────────────────────────────────────────────

  test 'capture returns 403 for anonymous user' do
    post capture_restaurant_ordr_url(@restaurant, @ordr), as: :json

    assert_response :forbidden
  end

  test 'capture calls CaptureService for authenticated staff' do
    @ordr.update!(
      payment_on_file: true,
      payment_method_ref: 'pm_test_abc',
      auto_pay_status: nil,
      status: 30, # billrequested
    )
    sign_in @user

    success_result = AutoPay::CaptureService::Result.new(success: true, error: nil)
    fake_service = lambda { |_ordr_kw|
      stub = Object.new
      stub.define_singleton_method(:call) { success_result }
      stub
    }

    AutoPay::CaptureService.stub :new, fake_service do
      post capture_restaurant_ordr_url(@restaurant, @ordr), as: :json
    end

    assert_response :ok
    assert response.parsed_body['ok']
  end

  test 'capture returns 200 with message when order already captured' do
    @ordr.update!(payment_on_file: true, auto_pay_status: 'succeeded', status: 35)
    sign_in @user

    post capture_restaurant_ordr_url(@restaurant, @ordr), as: :json

    assert_response :ok
    body = response.parsed_body
    assert body['ok']
    assert_match(/Already captured/, body['message'])
  end

  test 'capture fails when no payment method on file' do
    sign_in @user

    post capture_restaurant_ordr_url(@restaurant, @ordr), as: :json

    assert_response :unprocessable_content
    assert_not response.parsed_body['ok']
  end
end
