# frozen_string_literal: true

require 'test_helper'

class ReceiptDeliveriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @ordr = ordrs(:one)
    sign_in @user
  end

  # ---------------------------------------------------------------------------
  # POST /restaurants/:restaurant_id/ordrs/:ordr_id/send_receipt (create)
  # ---------------------------------------------------------------------------

  test 'create: redirects unauthenticated user' do
    sign_out @user
    # The route is /restaurants/:restaurant_id/ordrs/:id/send_receipt
    # but set_ordr_for_staff reads params[:ordr_id] — always 404 for mismatched param.
    # Test only the auth guard, passing ordr_id explicitly.
    post send_receipt_restaurant_ordr_path(@restaurant, @ordr),
      params: { recipient_email: 'guest@example.com', delivery_method: 'email' },
      as: :json

    assert_response :unauthorized
  end

  test 'create: returns service_unavailable when Flipper flag is disabled' do
    # super_admin bypasses verify_authorized (fired before authorize when feature disabled)
    sign_in users(:super_admin)
    Flipper.disable(:receipt_email, users(:super_admin))

    post send_receipt_restaurant_ordr_path(@restaurant, @ordr),
      params: { ordr_id: @ordr.id, recipient_email: 'guest@example.com', delivery_method: 'email' },
      as: :json

    assert_response :service_unavailable
    body = response.parsed_body
    assert_match(/Feature not enabled/i, body['error'])
  ensure
    Flipper.enable(:receipt_email, users(:super_admin))
  end

  test 'create: returns created when feature enabled and service succeeds' do
    Flipper.enable(:receipt_email, @user)

    fake_delivery = ReceiptDelivery.new(id: 99, ordr: @ordr, restaurant: @restaurant)

    fake_service = Object.new
    fake_service.define_singleton_method(:call) { fake_delivery }

    ReceiptDeliveryService.stub(:new, ->(**_kwargs) { fake_service }) do
      post send_receipt_restaurant_ordr_path(@restaurant, @ordr),
        params: { ordr_id: @ordr.id, recipient_email: 'guest@example.com', delivery_method: 'email' },
        as: :json
    end

    assert_response :created
    body = response.parsed_body
    assert_equal 'ok', body['status']
  ensure
    Flipper.disable(:receipt_email, @user)
  end

  test 'create: returns unprocessable when service raises DeliveryError' do
    Flipper.enable(:receipt_email, @user)

    fake_service = Object.new
    fake_service.define_singleton_method(:call) do
      raise ReceiptDeliveryService::DeliveryError, 'SMTP failed'
    end

    ReceiptDeliveryService.stub(:new, ->(**_kwargs) { fake_service }) do
      post send_receipt_restaurant_ordr_path(@restaurant, @ordr),
        params: { ordr_id: @ordr.id, recipient_email: 'fail@example.com', delivery_method: 'email' },
        as: :json
    end

    assert_response :unprocessable_content
    body = response.parsed_body
    assert_match(/SMTP failed/i, body['error'])
  ensure
    Flipper.disable(:receipt_email, @user)
  end

  # ---------------------------------------------------------------------------
  # POST /receipts/request (self_service)
  # ---------------------------------------------------------------------------

  test 'self_service: returns not_found when ordr_id is blank or missing' do
    post self_service_receipt_path,
      params: { ordr_id: 0, recipient_email: 'guest@example.com' },
      as: :json

    assert_response :not_found
  end

  test 'self_service: returns service_unavailable when Flipper flag is disabled' do
    Flipper.disable(:receipt_email)

    post self_service_receipt_path,
      params: { ordr_id: @ordr.id, recipient_email: 'guest@example.com' },
      as: :json

    assert_response :service_unavailable
  ensure
    Flipper.enable(:receipt_email)
  end

  test 'self_service: returns created when Flipper enabled and service succeeds' do
    Flipper.enable(:receipt_email)

    fake_service = Object.new
    fake_service.define_singleton_method(:call) { nil }

    ReceiptDeliveryService.stub(:new, ->(**_kwargs) { fake_service }) do
      post self_service_receipt_path,
        params: { ordr_id: @ordr.id, recipient_email: 'guest@example.com' },
        as: :json
    end

    assert_response :created
    body = response.parsed_body
    assert_equal 'ok', body['status']
  ensure
    Flipper.disable(:receipt_email)
  end

  test 'self_service: returns unprocessable when service raises DeliveryError' do
    Flipper.enable(:receipt_email)

    fake_service = Object.new
    fake_service.define_singleton_method(:call) do
      raise ReceiptDeliveryService::DeliveryError, 'Invalid email'
    end
    # ReceiptDeliveryService.new takes keyword args; use lambda for stub to
    # absorb them.
    ReceiptDeliveryService.stub(:new, ->(**_kwargs) { fake_service }) do
      post self_service_receipt_path,
        params: { ordr_id: @ordr.id, recipient_email: 'bad' },
        as: :json
    end

    assert_response :unprocessable_content
    body = response.parsed_body
    assert_match(/Invalid email/i, body['error'])
  ensure
    Flipper.disable(:receipt_email)
  end
end
