# frozen_string_literal: true

require 'test_helper'

class OrdrPaymentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @restaurant = restaurants(:one)
    @user = @restaurant.user || users(:one)
    @restaurant.update!(user: @user) unless @restaurant.user_id == @user.id
    @ordr = ordrs(:one)

    # Ensure order belongs to restaurant and has items with a total
    @ordr.update!(status: 'billrequested', gross: 25.00, tip: 0)

    sign_in @user
  end

  # ─── split_evenly ──────────────────────────────────────────────────────

  test 'split_evenly requires billrequested status' do
    @ordr.update!(status: 'opened')

    post split_evenly_restaurant_ordr_url(@restaurant, @ordr)
    assert_response :unprocessable_content

    body = JSON.parse(response.body)
    assert_equal false, body['ok']
    assert_match(/billrequested/, body['error'])
  end

  test 'split_evenly requires at least 2 customer participants' do
    # Only one customer participant in fixtures (two)
    # Remove the extra customer (three)
    Ordrparticipant.where(ordr: @ordr, role: :customer).where.not(id: ordrparticipants(:two).id).destroy_all

    post split_evenly_restaurant_ordr_url(@restaurant, @ordr)
    assert_response :unprocessable_content

    body = JSON.parse(response.body)
    assert_match(/2 participants/, body['error'])
  end

  test 'split_evenly creates split payments for each customer participant' do
    # Ensure we have 2 customer participants
    assert_operator Ordrparticipant.where(ordr: @ordr, role: :customer).count, :>=, 2

    post split_evenly_restaurant_ordr_url(@restaurant, @ordr)
    assert_response :ok

    body = JSON.parse(response.body)
    assert body['ok']
    assert_equal @ordr.id, body['order_id']
    assert body['split_payments'].is_a?(Array)
    assert_equal 2, body['split_payments'].length

    # All split amounts should sum to total
    total = body['split_payments'].sum { |sp| sp['amount_cents'] }
    assert_equal body['total_cents'], total
  end

  test 'split_plan returns nil when no plan exists yet' do
    get split_plan_restaurant_ordr_url(@restaurant, @ordr)
    assert_response :ok

    body = JSON.parse(response.body)
    assert body['ok']
    assert_nil body['split_plan']
  end

  test 'split_plan rejects custom split with incorrect total' do
    patch split_plan_restaurant_ordr_url(@restaurant, @ordr), params: {
      split_method: 'custom',
      participant_ids: [ordrparticipants(:two).id, ordrparticipants(:three).id],
      custom_amounts_cents: {
        ordrparticipants(:two).id => 1000,
        ordrparticipants(:three).id => 1000,
      },
    }
    assert_response :unprocessable_content

    body = JSON.parse(response.body)
    refute body['ok']
    assert_match(/subtotal/i, body['error'])
  end

  test 'split_plan rejects percentage split not totaling 100%' do
    patch split_plan_restaurant_ordr_url(@restaurant, @ordr), params: {
      split_method: 'percentage',
      participant_ids: [ordrparticipants(:two).id, ordrparticipants(:three).id],
      percentage_basis_points: {
        ordrparticipants(:two).id => 6000,
        ordrparticipants(:three).id => 3000,
      },
    }
    assert_response :unprocessable_content

    body = JSON.parse(response.body)
    refute body['ok']
    assert_match(/100%/i, body['error'])
  end

  test 'split_plan rejects item-based split with unassigned items' do
    patch split_plan_restaurant_ordr_url(@restaurant, @ordr), params: {
      split_method: 'item_based',
      participant_ids: [ordrparticipants(:two).id],
      item_assignments: {
        ordrparticipants(:two).id => [],
      },
    }
    assert_response :unprocessable_content

    body = JSON.parse(response.body)
    refute body['ok']
    assert_match(/assigned/i, body['error'])
  end

  test 'split_plan rejects updates when plan is frozen' do
    plan = @ordr.create_ordr_split_plan!(
      split_method: 'equal',
      plan_status: 'frozen',
      frozen_at: Time.current,
      created_by_user: users(:one)
    )
    plan.ordr_split_payments.create!(
      ordr: @ordr,
      ordrparticipant: ordrparticipants(:two),
      amount_cents: 1250,
      base_amount_cents: 1250,
      tax_amount_cents: 0,
      tip_amount_cents: 0,
      service_charge_amount_cents: 0,
      currency: @restaurant.currency || 'USD',
      provider: 'stripe',
      split_method: 'equal',
      status: 'pending',
      locked_at: Time.current
    )

    patch split_plan_restaurant_ordr_url(@restaurant, @ordr), params: {
      split_method: 'equal',
      participant_ids: [ordrparticipants(:two).id, ordrparticipants(:three).id],
    }
    assert_response :unprocessable_content

    body = JSON.parse(response.body)
    refute body['ok']
    assert_match(/frozen/i, body['error'])
  end

  test 'split_plan rejects access without authentication or participant session' do
    sign_out @user

    get split_plan_restaurant_ordr_url(@restaurant, @ordr)
    assert_response :forbidden

    body = JSON.parse(response.body)
    refute body['ok']
    assert_match(/authorized/i, body['error'])
  end

  test 'split_plan allows access with valid participant session' do
    skip 'Session-based participant auth requires integration test setup'
  end

  # ─── checkout_session (Stripe — default provider) ─────────────────────

  test 'checkout_session rejects non-billrequested order' do
    @ordr.update!(status: 'opened')

    post payments_checkout_session_restaurant_ordr_url(@restaurant, @ordr)
    assert_response :unprocessable_content
  end

  test 'checkout_session rejects zero amount' do
    @ordr.update!(gross: 0, tip: 0)
    @ordr.ordritems.delete_all

    post payments_checkout_session_restaurant_ordr_url(@restaurant, @ordr)
    assert_response :unprocessable_content

    body = JSON.parse(response.body)
    assert_match(/zero/, body['error'])
  end

  test 'checkout_session returns not_found for invalid split_payment_id' do
    post payments_checkout_session_restaurant_ordr_url(@restaurant, @ordr),
         params: { ordr_split_payment_id: 999_999 }
    assert_response :not_found
  end

  # ─── checkout_session (Square provider) ────────────────────────────────

  test 'checkout_session routes to Square when restaurant uses square provider' do
    @restaurant.update!(
      payment_provider: 'square',
      payment_provider_status: :connected,
      square_location_id: 'LOC_TEST',
      square_merchant_id: 'MERCH_TEST',
      platform_fee_type: :none,
    )

    ProviderAccount.create!(
      restaurant: @restaurant,
      provider: :square,
      access_token: 'test-token',
      refresh_token: 'test-refresh',
      token_expires_at: 30.days.from_now,
      status: :enabled,
      connected_at: 1.day.ago,
      environment: 'sandbox',
    )

    fake_response = {
      'payment_link' => {
        'id' => 'sq_link_split_1',
        'url' => 'https://square.link/u/test',
      },
      'related_resources' => { 'orders' => [{ 'id' => 'sq_order_1' }] },
    }

    mock_client = Minitest::Mock.new
    mock_client.expect :post, fake_response, ['/online-checkout/payment-links'], body: Hash

    Payments::Providers::SquareHttpClient.stub :new, mock_client do
      post payments_checkout_session_restaurant_ordr_url(@restaurant, @ordr),
           params: { success_url: 'https://example.com/success', cancel_url: 'https://example.com/cancel' }
      assert_response :ok

      body = JSON.parse(response.body)
      assert body['ok']
      assert_equal 'sq_link_split_1', body['checkout_session_id']
      assert_equal 'https://square.link/u/test', body['checkout_url']
    end
  end

  test 'checkout_session with split payment routes to Square and updates split record' do
    @restaurant.update!(
      payment_provider: 'square',
      payment_provider_status: :connected,
      square_location_id: 'LOC_TEST',
      square_merchant_id: 'MERCH_TEST',
      platform_fee_type: :none,
    )

    ProviderAccount.create!(
      restaurant: @restaurant,
      provider: :square,
      access_token: 'test-token',
      refresh_token: 'test-refresh',
      token_expires_at: 30.days.from_now,
      status: :enabled,
      connected_at: 1.day.ago,
      environment: 'sandbox',
    )

    sp = @ordr.ordr_split_payments.create!(
      amount_cents: 1250,
      currency: 'EUR',
      status: :requires_payment,
      ordrparticipant: ordrparticipants(:two),
    )

    fake_response = {
      'payment_link' => {
        'id' => 'sq_link_split_2',
        'url' => 'https://square.link/u/split2',
      },
      'related_resources' => { 'orders' => [] },
    }

    mock_client = Minitest::Mock.new
    mock_client.expect :post, fake_response, ['/online-checkout/payment-links'], body: Hash

    Payments::Providers::SquareHttpClient.stub :new, mock_client do
      post payments_checkout_session_restaurant_ordr_url(@restaurant, @ordr),
           params: {
             ordr_split_payment_id: sp.id,
             success_url: 'https://example.com/success',
             cancel_url: 'https://example.com/cancel',
           }
      assert_response :ok

      body = JSON.parse(response.body)
      assert body['ok']

      sp.reload
      assert_equal 'pending', sp.status
      assert_equal 'square', sp.provider
      assert_equal 'sq_link_split_2', sp.provider_checkout_session_id
    end
  end

  # ─── SquareIngestor split settlement ───────────────────────────────────

  test 'SquareIngestor marks split payment succeeded and emits paid when all settled' do
    @ordr.update!(status: 'billrequested', gross: 20.00)

    sp1 = @ordr.ordr_split_payments.create!(
      amount_cents: 1000, currency: 'EUR', status: :succeeded,
      ordrparticipant: ordrparticipants(:two),
    )
    sp2 = @ordr.ordr_split_payments.create!(
      amount_cents: 1000, currency: 'EUR', status: :pending,
      ordrparticipant: ordrparticipants(:three),
    )

    pa = PaymentAttempt.create!(
      ordr: @ordr,
      restaurant: @restaurant,
      provider: :square,
      amount_cents: 1000,
      currency: 'EUR',
      status: :requires_action,
      charge_pattern: :direct,
      merchant_model: :restaurant_mor,
      provider_payment_id: 'sq_pay_split_final',
    )

    payload = {
      'event_id' => 'evt_split_test',
      'type' => 'payment.completed',
      'data' => {
        'object' => {
          'payment' => {
            'id' => 'sq_pay_split_final',
            'status' => 'COMPLETED',
            'reference_id' => @ordr.id.to_s,
            'note' => "Order #{@ordr.id} split:#{sp2.id}",
            'amount_money' => { 'amount' => 1000, 'currency' => 'EUR' },
          },
        },
      },
    }

    ingestor = Payments::Webhooks::SquareIngestor.new

    # Stub broadcast to avoid ActionCable + SmartmenuState dependencies
    ingestor.stub :broadcast_state, nil do
      ingestor.ingest!(
        provider_event_id: 'evt_split_test',
        provider_event_type: 'payment.completed',
        occurred_at: Time.current,
        payload: payload,
      )
    end

    pa.reload
    assert_equal 'succeeded', pa.status

    sp2.reload
    assert_equal 'succeeded', sp2.status

    # Both splits succeeded → paid event should exist
    assert OrderEvent.exists?(ordr_id: @ordr.id, event_type: 'paid')
  end

  test 'SquareIngestor does NOT emit paid when some splits still pending' do
    @ordr.update!(status: 'billrequested', gross: 20.00)

    sp1 = @ordr.ordr_split_payments.create!(
      amount_cents: 1000, currency: 'EUR', status: :requires_payment,
      ordrparticipant: ordrparticipants(:two),
    )
    sp2 = @ordr.ordr_split_payments.create!(
      amount_cents: 1000, currency: 'EUR', status: :pending,
      ordrparticipant: ordrparticipants(:three),
    )

    pa = PaymentAttempt.create!(
      ordr: @ordr,
      restaurant: @restaurant,
      provider: :square,
      amount_cents: 1000,
      currency: 'EUR',
      status: :requires_action,
      charge_pattern: :direct,
      merchant_model: :restaurant_mor,
      provider_payment_id: 'sq_pay_partial',
    )

    payload = {
      'event_id' => 'evt_partial',
      'type' => 'payment.completed',
      'data' => {
        'object' => {
          'payment' => {
            'id' => 'sq_pay_partial',
            'status' => 'COMPLETED',
            'reference_id' => @ordr.id.to_s,
            'note' => "Order #{@ordr.id} split:#{sp2.id}",
            'amount_money' => { 'amount' => 1000, 'currency' => 'EUR' },
          },
        },
      },
    }

    ingestor = Payments::Webhooks::SquareIngestor.new

    ingestor.stub :broadcast_state, nil do
      ingestor.ingest!(
        provider_event_id: 'evt_partial',
        provider_event_type: 'payment.completed',
        occurred_at: Time.current,
        payload: payload,
      )
    end

    # sp2 succeeded but sp1 still requires_payment → no paid event
    sp2.reload
    assert_equal 'succeeded', sp2.status

    assert_not OrderEvent.exists?(ordr_id: @ordr.id, event_type: 'paid')
  end

  # ─── create_inline_payment (Square Web Payments SDK) ───────────────

  test 'create_inline_payment rejects when source_id is missing' do
    @restaurant.update!(payment_provider: 'square')

    post payments_inline_restaurant_ordr_url(@restaurant, @ordr), params: {}
    assert_response :unprocessable_content

    body = JSON.parse(response.body)
    assert_match(/source_id/, body['error'])
  end

  test 'create_inline_payment rejects non-square restaurant' do
    @restaurant.update!(payment_provider: 'stripe')

    post payments_inline_restaurant_ordr_url(@restaurant, @ordr),
         params: { source_id: 'cnon-test' }
    assert_response :unprocessable_content

    body = JSON.parse(response.body)
    assert_match(/Square is not enabled/, body['error'])
  end

  test 'create_inline_payment succeeds with valid source_id' do
    @restaurant.update!(
      payment_provider: 'square',
      payment_provider_status: :connected,
      square_location_id: 'LOC_TEST',
      square_merchant_id: 'MERCH_TEST',
      platform_fee_type: :none,
    )

    ProviderAccount.create!(
      restaurant: @restaurant,
      provider: :square,
      access_token: 'test-token',
      refresh_token: 'test-refresh',
      token_expires_at: 30.days.from_now,
      status: :enabled,
      connected_at: 1.day.ago,
      environment: 'sandbox',
    )

    fake_response = {
      'payment' => {
        'id' => 'sq_pay_inline_1',
        'status' => 'COMPLETED',
        'amount_money' => { 'amount' => 2500, 'currency' => 'USD' },
      },
    }

    mock_client = Minitest::Mock.new
    mock_client.expect :post, fake_response, ['/payments'], body: Hash

    Payments::Providers::SquareHttpClient.stub :new, mock_client do
      post payments_inline_restaurant_ordr_url(@restaurant, @ordr),
           params: { source_id: 'cnon-test-nonce', tip_cents: 200 }
      assert_response :ok

      body = JSON.parse(response.body)
      assert body['ok']
      assert_equal 'succeeded', body['status']
      assert_equal 'sq_pay_inline_1', body['payment_id']
    end

    # PaymentAttempt was created and succeeded
    pa = PaymentAttempt.last
    assert_equal 'succeeded', pa.status
    assert_equal 'square', pa.provider
  end
end
