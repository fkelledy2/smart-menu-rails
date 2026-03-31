# frozen_string_literal: true

require 'test_helper'

class Payments::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @plan = plans(:two) # professional plan — has stripe_price_id_month set
    sign_in @user

    # Ensure Stripe API key is set so ensure_stripe_api_key! does not raise.
    @original_stripe_api_key = Stripe.api_key
    Stripe.api_key = 'sk_test_subscriptions_controller_stub'
  end

  teardown do
    Stripe.api_key = @original_stripe_api_key
  end

  # ---------------------------------------------------------------------------
  # POST /payments/subscriptions/start
  # ---------------------------------------------------------------------------

  test 'start: redirects unauthenticated user' do
    sign_out @user
    post payments_subscriptions_start_path,
      params: { restaurant_id: @restaurant.id },
      as: :json

    assert_response :unauthorized
  end

  test 'start: returns not_found for unknown restaurant (super_admin bypasses verify_authorized)' do
    sign_in users(:super_admin)
    post payments_subscriptions_start_path,
      params: { restaurant_id: 0 },
      as: :json

    assert_response :not_found
  end

  test 'start: returns error JSON when plan is not found' do
    post payments_subscriptions_start_path,
      params: { restaurant_id: @restaurant.id, plan_id: 0 },
      as: :json

    # plan_id 0 not found → respond_with_start_error
    assert_response :unprocessable_content
    body = response.parsed_body
    assert_equal false, body['ok']
    assert_match(/No plan selected/i, body['error'])
  end

  test 'start: returns error JSON when plan has no stripe price configured' do
    # Use plan :one which has stripe_price_id_month set; pick a year interval
    # against a plan without stripe_price_id_year to trigger the blank price_id path.
    plan_no_year = plans(:one) # free plan — stripe_price_id_year is nil

    post payments_subscriptions_start_path,
      params: { restaurant_id: @restaurant.id, plan_id: plan_no_year.id, interval: 'year' },
      as: :json

    assert_response :unprocessable_content
    body = response.parsed_body
    assert_equal false, body['ok']
    assert_match(/not configured for billing/i, body['error'])
  end

  test 'start: creates checkout session and returns ok JSON' do
    # Ensure no existing sub so the customer creation branch runs
    @restaurant.restaurant_subscription&.destroy

    fake_customer = Object.new
    fake_customer.define_singleton_method(:id) { 'cus_test_123' }

    fake_session = Object.new
    fake_session.define_singleton_method(:url) { 'https://checkout.stripe.com/test' }

    Stripe::Customer.stub(:create, fake_customer) do
      Stripe::Checkout::Session.stub(:create, fake_session) do
        post payments_subscriptions_start_path,
          params: { restaurant_id: @restaurant.id, plan_id: @plan.id, interval: 'month' },
          as: :json
      end
    end

    assert_response :ok
    body = response.parsed_body
    assert_equal true, body['ok']
    assert_equal 'https://checkout.stripe.com/test', body['checkout_url']
  end

  test 'start: skips customer creation when stripe_customer_id already exists' do
    sub = @restaurant.restaurant_subscription ||
      @restaurant.build_restaurant_subscription
    sub.stripe_customer_id = 'cus_existing_456'
    sub.status = :active
    sub.save!

    fake_session = Object.new
    fake_session.define_singleton_method(:url) { 'https://checkout.stripe.com/existing' }

    # Stripe::Customer.create should NOT be called; only Session.create
    Stripe::Customer.stub(:create, ->(*_args) { raise 'should not be called' }) do
      Stripe::Checkout::Session.stub(:create, fake_session) do
        post payments_subscriptions_start_path,
          params: { restaurant_id: @restaurant.id, plan_id: @plan.id, interval: 'month' },
          as: :json
      end
    end

    assert_response :ok
    body = response.parsed_body
    assert_equal true, body['ok']
    assert_equal 'https://checkout.stripe.com/existing', body['checkout_url']
  end

  test 'start: returns error JSON on Stripe API failure' do
    @restaurant.restaurant_subscription&.destroy

    Stripe::Customer.stub(:create, ->(*_args) { raise Stripe::StripeError, 'API error' }) do
      post payments_subscriptions_start_path,
        params: { restaurant_id: @restaurant.id, plan_id: @plan.id },
        as: :json
    end

    assert_response :unprocessable_content
    body = response.parsed_body
    assert_equal false, body['ok']
  end

  # ---------------------------------------------------------------------------
  # POST /payments/subscriptions/portal
  # ---------------------------------------------------------------------------

  test 'portal: redirects unauthenticated user' do
    sign_out @user
    post payments_subscriptions_portal_path,
      params: { restaurant_id: @restaurant.id },
      as: :json

    assert_response :unauthorized
  end

  test 'portal: returns not_found for unknown restaurant (super_admin bypasses verify_authorized)' do
    sign_in users(:super_admin)
    post payments_subscriptions_portal_path,
      params: { restaurant_id: 0 },
      as: :json

    assert_response :not_found
  end

  test 'portal: returns error JSON when no stripe customer on record' do
    # Ensure no subscription / blank customer id
    @restaurant.restaurant_subscription&.destroy

    post payments_subscriptions_portal_path,
      params: { restaurant_id: @restaurant.id },
      as: :json

    assert_response :unprocessable_content
    body = response.parsed_body
    assert_equal false, body['ok']
    assert_match(/Billing is not configured/i, body['error'])
  end

  test 'portal: returns portal_url JSON when customer exists' do
    sub = @restaurant.restaurant_subscription ||
      @restaurant.build_restaurant_subscription
    sub.stripe_customer_id = 'cus_portal_test'
    sub.status = :active
    sub.save!

    fake_portal = Object.new
    fake_portal.define_singleton_method(:url) { 'https://billing.stripe.com/portal/test' }

    Stripe::BillingPortal::Session.stub(:create, fake_portal) do
      post payments_subscriptions_portal_path,
        params: { restaurant_id: @restaurant.id },
        as: :json
    end

    assert_response :ok
    body = response.parsed_body
    assert_equal true, body['ok']
    assert_equal 'https://billing.stripe.com/portal/test', body['portal_url']
  end

  test 'portal: returns error JSON on Stripe API failure' do
    sub = @restaurant.restaurant_subscription ||
      @restaurant.build_restaurant_subscription
    sub.stripe_customer_id = 'cus_fail_test'
    sub.status = :active
    sub.save!

    Stripe::BillingPortal::Session.stub(:create, ->(*_args) { raise Stripe::StripeError, 'Portal error' }) do
      post payments_subscriptions_portal_path,
        params: { restaurant_id: @restaurant.id },
        as: :json
    end

    assert_response :unprocessable_content
    body = response.parsed_body
    assert_equal false, body['ok']
  end
end
