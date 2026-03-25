# frozen_string_literal: true

require 'test_helper'

# Tests the staff-assisted "Collect Payment" workflow introduced alongside the
# payOrderModal payment-method tabs. Covers:
#   - cash_payment: marks an order paid in cash and closes it
#   - checkout_qr:  generates a hosted checkout session and returns an SVG QR code
class CollectPaymentWorkflowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user        = users(:one)
    @restaurant  = restaurants(:one)
    @restaurant.update!(user: @user, payment_provider: 'stripe')
    @menu = menus(:one)
    @menu.update!(restaurant: @restaurant)
    @tablesetting = tablesettings(:one)

    @ordr = @restaurant.ordrs.create!(
      tablesetting: @tablesetting,
      menu: @menu,
      status: :billrequested,
      gross: 42.50,
      tip: 0,
    )

    @ordr.ordritems.create!(
      menuitem: menuitems(:one),
      ordritemprice: 42.50,
      quantity: 1,
      status: :ordered,
    )

    sign_in @user
  end

  # ── cash_payment ──────────────────────────────────────────────────────

  test 'cash_payment transitions order through paid → closed and responds ok' do
    assert_equal 'billrequested', @ordr.status

    post payments_cash_restaurant_ordr_path(@restaurant, @ordr)

    assert_response :ok
    body = response.parsed_body
    assert body['ok'], "Expected ok:true but got: #{body.inspect}"
    assert_equal 'closed', body['status']

    @ordr.reload
    assert_equal 'closed', @ordr.status
  end

  test 'cash_payment emits exactly two order events: paid then closed' do
    assert_difference -> { OrderEvent.where(ordr: @ordr).count }, 2 do
      post payments_cash_restaurant_ordr_path(@restaurant, @ordr)
    end

    events = OrderEvent.where(ordr: @ordr).order(:sequence).pluck(:event_type)
    assert_includes events, 'paid'
    assert_includes events, 'closed'
    assert_operator events.index('paid'), :<, events.index('closed'),
                    'paid event must come before closed event'
  end

  test 'cash_payment records cash as the payment method in the event payload' do
    post payments_cash_restaurant_ordr_path(@restaurant, @ordr)

    paid_event = OrderEvent.find_by(ordr: @ordr, event_type: 'paid')
    assert_not_nil paid_event
    assert_equal 'cash', paid_event.payload['method']
    assert_equal 'staff', paid_event.source
  end

  test 'cash_payment rejects when order is not billrequested' do
    @ordr.update!(status: 'delivered')

    post payments_cash_restaurant_ordr_path(@restaurant, @ordr)

    assert_response :unprocessable_content
    body = response.parsed_body
    assert_not body['ok']

    @ordr.reload
    assert_equal 'delivered', @ordr.status # unchanged
  end

  test 'cash_payment is rejected when called by unauthenticated user' do
    sign_out @user

    post payments_cash_restaurant_ordr_path(@restaurant, @ordr)

    assert_response :forbidden
    @ordr.reload
    assert_equal 'billrequested', @ordr.status # unchanged
  end

  test 'cash_payment cannot be used to pay an order from a different restaurant' do
    other_restaurant = restaurants(:two)
    other_ordr       = other_restaurant.ordrs.create!(
      tablesetting: @tablesetting,
      menu: @menu,
      status: :billrequested,
      gross: 10.00,
    )

    # @user owns @restaurant but not other_restaurant
    post payments_cash_restaurant_ordr_path(@restaurant, other_ordr)

    # Route mismatch detected by set_ordr — returns 404
    assert_response :not_found

    other_ordr.reload
    assert_equal 'billrequested', other_ordr.status # unchanged
  end

  # ── checkout_qr (Stripe) ─────────────────────────────────────────────

  test 'checkout_qr returns a valid JSON payload with checkout_url and SVG' do
    fake_session = OpenStruct.new(
      id: 'cs_test_workflow_1',
      url: 'https://checkout.stripe.com/pay/cs_test_workflow_1',
      payment_intent: nil,
    )

    original_key = Stripe.api_key
    Stripe.api_key = 'sk_test_fake_key'

    Stripe::Checkout::Session.stub :create, fake_session do
      post payments_checkout_qr_restaurant_ordr_path(@restaurant, @ordr),
           params: { success_url: root_url, cancel_url: root_url }
    end

    assert_response :ok
    body = response.parsed_body

    assert body['ok']
    assert_equal 'https://checkout.stripe.com/pay/cs_test_workflow_1', body['checkout_url']

    # QR SVG must be present and valid XML
    assert body['qr_svg'].present?, 'Expected qr_svg to be present'
    assert_includes body['qr_svg'], '<svg'
    assert_nothing_raised { Nokogiri::XML(body['qr_svg'], &:strict) }
  ensure
    Stripe.api_key = original_key
  end

  test 'checkout_qr rejects order not in billrequested status' do
    @ordr.update!(status: 'closed')

    post payments_checkout_qr_restaurant_ordr_path(@restaurant, @ordr)

    assert_response :unprocessable_content
    assert_not response.parsed_body['ok']
  end

  test 'checkout_qr rejects order with zero total' do
    @ordr.update!(gross: 0)
    @ordr.ordritems.delete_all

    post payments_checkout_qr_restaurant_ordr_path(@restaurant, @ordr)

    assert_response :unprocessable_content
    body = response.parsed_body
    assert_not body['ok']
    assert_match(/zero/i, body['error'])
  end

  test 'checkout_qr is rejected when called by unauthenticated user' do
    sign_out @user

    post payments_checkout_qr_restaurant_ordr_path(@restaurant, @ordr)

    assert_response :forbidden
  end

  # ── checkout_qr (Square) ─────────────────────────────────────────────

  test 'checkout_qr routes to Square and returns hosted link URL when restaurant uses Square' do
    @restaurant.update!(
      payment_provider: 'square',
      payment_provider_status: :connected,
      square_location_id: 'LOC_WF',
      square_merchant_id: 'MERCH_WF',
      platform_fee_type: :none,
    )

    ProviderAccount.create!(
      restaurant: @restaurant,
      provider: :square,
      access_token: 'tok',
      refresh_token: 'ref',
      token_expires_at: 30.days.from_now,
      status: :enabled,
      connected_at: 1.day.ago,
      environment: 'sandbox',
    )

    fake_response = {
      'payment_link' => {
        'id' => 'sq_wf_link_1',
        'url' => 'https://square.link/u/workflow_test',
      },
      'related_resources' => { 'orders' => [] },
    }

    mock_client = Minitest::Mock.new
    mock_client.expect :post, fake_response, ['/online-checkout/payment-links'], body: Hash

    Payments::Providers::SquareHttpClient.stub :new, mock_client do
      post payments_checkout_qr_restaurant_ordr_path(@restaurant, @ordr),
           params: { success_url: root_url, cancel_url: root_url }
    end

    assert_response :ok
    body = response.parsed_body

    assert body['ok']
    assert_equal 'https://square.link/u/workflow_test', body['checkout_url']
    assert_includes body['qr_svg'], '<svg'
  end

  # ── full staff collect-payment flow ──────────────────────────────────

  test 'full cash payment flow: billrequested → closed in one POST' do
    assert_equal 'billrequested', @ordr.reload.status

    post payments_cash_restaurant_ordr_path(@restaurant, @ordr)
    assert_response :ok

    @ordr.reload
    assert_equal 'closed', @ordr.status
    assert OrderEvent.exists?(ordr: @ordr, event_type: 'paid')
    assert OrderEvent.exists?(ordr: @ordr, event_type: 'closed')
  end

  test 'full QR payment flow: checkout_qr followed by Stripe webhook closes order' do
    fake_session = OpenStruct.new(
      id: 'cs_fullflow_1',
      url: 'https://checkout.stripe.com/pay/cs_fullflow_1',
      payment_intent: 'pi_fullflow_1',
    )

    original_key = Stripe.api_key
    Stripe.api_key = 'sk_test_fake_key'

    Stripe::Checkout::Session.stub :create, fake_session do
      post payments_checkout_qr_restaurant_ordr_path(@restaurant, @ordr),
           params: { success_url: root_url, cancel_url: root_url }
    end

    Stripe.api_key = original_key

    assert_response :ok
    assert response.parsed_body['checkout_url'].present?

    # Simulate Stripe completing payment via webhook projector path
    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'paid',
      entity_type: 'order',
      entity_id: @ordr.id,
      source: 'stripe_webhook',
      idempotency_key: "stripe_paid:#{@ordr.id}",
      payload: { provider_payment_id: 'pi_fullflow_1' },
    )
    OrderEventProjector.project!(@ordr.id)

    @ordr.reload
    assert_equal 'paid', @ordr.status
  end
end
