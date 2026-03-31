# frozen_string_literal: true

require 'test_helper'

class Payments::Providers::StripeAdapterTest < ActiveSupport::TestCase
  # All Stripe API calls are stubbed with minimal doubles.
  # No real HTTP requests are made.

  def setup
    @restaurant = restaurants(:one)
    @ordr = ordrs(:one)
    @adapter = Payments::Providers::StripeAdapter.new

    # Provide a dummy API key so ensure_api_key! passes without hitting credentials.
    @original_api_key = Stripe.api_key
    Stripe.api_key = 'sk_test_stub_key'

    @payment_attempt = PaymentAttempt.create!(
      ordr: @ordr,
      restaurant: @restaurant,
      provider: :stripe,
      amount_cents: 2000,
      currency: 'USD',
      status: :requires_action,
      charge_pattern: :direct,
      merchant_model: :restaurant_mor,
    )
  end

  def teardown
    Stripe.api_key = @original_api_key
  end

  # ---------------------------------------------------------------------------
  # create_checkout_session! — return shape
  # ---------------------------------------------------------------------------

  test 'create_checkout_session! returns hash with checkout_session_id, checkout_url, payment_intent_id' do
    fake_session = fake_stripe_session(
      id: 'cs_test_abc123',
      url: 'https://checkout.stripe.com/pay/cs_test_abc123',
      payment_intent: nil,
    )

    Stripe::Checkout::Session.stub(:create, fake_session) do
      result = @adapter.create_checkout_session!(
        payment_attempt: @payment_attempt,
        ordr: @ordr,
        amount_cents: 2000,
        currency: 'USD',
        success_url: 'https://example.com/success',
        cancel_url: 'https://example.com/cancel',
      )

      assert_equal 'cs_test_abc123', result[:checkout_session_id]
      assert_equal 'https://checkout.stripe.com/pay/cs_test_abc123', result[:checkout_url]
      assert_nil result[:payment_intent_id]
    end
  end

  test 'create_checkout_session! includes payment_intent_id when session has one' do
    pi_double = Object.new
    pi_double.define_singleton_method(:id) { 'pi_test_xyz' }
    pi_double.define_singleton_method(:to_s) { 'pi_test_xyz' }

    fake_session = fake_stripe_session(
      id: 'cs_test_with_pi',
      url: 'https://checkout.stripe.com/pay/cs_test_with_pi',
      payment_intent: pi_double,
    )

    Stripe::Checkout::Session.stub(:create, fake_session) do
      result = @adapter.create_checkout_session!(
        payment_attempt: @payment_attempt,
        ordr: @ordr,
        amount_cents: 2000,
        currency: 'USD',
        success_url: 'https://example.com/success',
        cancel_url: 'https://example.com/cancel',
      )

      assert_equal 'pi_test_xyz', result[:payment_intent_id]
    end
  end

  # ---------------------------------------------------------------------------
  # create_and_capture_intent! — return shape and PaymentAttempt update
  # ---------------------------------------------------------------------------

  test 'create_and_capture_intent! returns hash with payment_intent_id' do
    fake_intent = fake_stripe_payment_intent(id: 'pi_test_capture_001')

    Stripe::PaymentIntent.stub(:create, fake_intent) do
      result = @adapter.create_and_capture_intent!(
        payment_attempt: @payment_attempt,
        ordr: @ordr,
        payment_method_id: 'pm_test_card',
        amount_cents: 2000,
        currency: 'USD',
        idempotency_key: 'auto_pay:99',
      )

      assert_equal 'pi_test_capture_001', result[:payment_intent_id]
    end
  end

  test 'create_and_capture_intent! updates PaymentAttempt to succeeded' do
    fake_intent = fake_stripe_payment_intent(id: 'pi_test_capture_002')

    Stripe::PaymentIntent.stub(:create, fake_intent) do
      @adapter.create_and_capture_intent!(
        payment_attempt: @payment_attempt,
        ordr: @ordr,
        payment_method_id: 'pm_test_card',
        amount_cents: 2000,
        currency: 'USD',
      )
    end

    assert_equal 'succeeded', @payment_attempt.reload.status
    assert_equal 'pi_test_capture_002', @payment_attempt.provider_payment_id
  end

  test 'create_and_capture_intent! raises CaptureError on Stripe::CardError' do
    Stripe::PaymentIntent.stub(:create, ->(*_args, **_kwargs) { raise Stripe::CardError.new('Card declined', nil) }) do
      assert_raises Payments::Orchestrator::CaptureError do
        @adapter.create_and_capture_intent!(
          payment_attempt: @payment_attempt,
          ordr: @ordr,
          payment_method_id: 'pm_test_declined',
          amount_cents: 2000,
          currency: 'USD',
        )
      end
    end
  end

  test 'create_and_capture_intent! sets PaymentAttempt status to failed on card error' do
    Stripe::PaymentIntent.stub(:create, ->(*_args, **_kwargs) { raise Stripe::CardError.new('Declined', nil) }) do
      assert_raises Payments::Orchestrator::CaptureError do
        @adapter.create_and_capture_intent!(
          payment_attempt: @payment_attempt,
          ordr: @ordr,
          payment_method_id: 'pm_test_declined',
          amount_cents: 2000,
          currency: 'USD',
        )
      end
    end

    assert_equal 'failed', @payment_attempt.reload.status
  end

  test 'create_and_capture_intent! raises CaptureError on generic Stripe::StripeError' do
    Stripe::PaymentIntent.stub(:create, ->(*_args, **_kwargs) { raise Stripe::InvalidRequestError.new('Invalid', nil) }) do
      assert_raises Payments::Orchestrator::CaptureError do
        @adapter.create_and_capture_intent!(
          payment_attempt: @payment_attempt,
          ordr: @ordr,
          payment_method_id: 'pm_test_invalid',
          amount_cents: 2000,
          currency: 'USD',
        )
      end
    end
  end

  # ---------------------------------------------------------------------------
  # ensure_api_key! — raises when no key is configured
  # ---------------------------------------------------------------------------

  test 'ensure_api_key! raises when Stripe.api_key is blank and no env/credentials key exists' do
    Stripe.api_key = nil

    ENV_KEY_BACKUP = ENV.fetch('STRIPE_SECRET_KEY', nil)
    ENV.delete('STRIPE_SECRET_KEY')

    adapter = Payments::Providers::StripeAdapter.new

    # Stub credentials to return nil
    Rails.application.credentials.stub(:stripe_secret_key, nil) do
      assert_raises RuntimeError do
        adapter.create_checkout_session!(
          payment_attempt: @payment_attempt,
          ordr: @ordr,
          amount_cents: 2000,
          currency: 'USD',
          success_url: 'https://example.com/success',
          cancel_url: 'https://example.com/cancel',
        )
      end
    end
  ensure
    ENV['STRIPE_SECRET_KEY'] = ENV_KEY_BACKUP if defined?(ENV_KEY_BACKUP) && ENV_KEY_BACKUP
    Stripe.api_key = 'sk_test_stub_key'
  end

  private

  def fake_stripe_session(id:, url:, payment_intent: nil)
    obj = Object.new
    obj.define_singleton_method(:id) { id }
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:payment_intent) { payment_intent }
    obj
  end

  def fake_stripe_payment_intent(id:)
    obj = Object.new
    obj.define_singleton_method(:id) { id }
    obj
  end
end
