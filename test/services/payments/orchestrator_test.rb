# frozen_string_literal: true

require 'test_helper'

class Payments::OrchestratorTest < ActiveSupport::TestCase
  # All external adapter calls are stubbed — no Stripe API calls are made.
  # Tests verify: PaymentAttempt creation, currency fallback, zero-amount guard,
  # and CaptureError propagation.

  def setup
    @restaurant = restaurants(:one)
    @ordr = ordrs(:one)
    @user = users(:one)

    # Ensure a PaymentProfile exists so Orchestrator does not create one with a
    # different primary_provider that changes the adapter routing.
    @profile = PaymentProfile.find_or_create_by!(restaurant: @restaurant) do |p|
      p.merchant_model = :restaurant_mor
      p.primary_provider = :stripe
    end

    @fake_checkout_result = {
      checkout_session_id: 'cs_test_abc123',
      checkout_url: 'https://checkout.stripe.com/pay/cs_test_abc123',
      payment_intent_id: nil,
    }
  end

  # ---------------------------------------------------------------------------
  # create_payment_attempt! — happy path
  # ---------------------------------------------------------------------------

  test 'create_payment_attempt! creates a PaymentAttempt record' do
    stub_stripe_checkout_session(@fake_checkout_result) do
      assert_difference 'PaymentAttempt.count', 1 do
        Payments::Orchestrator.new.create_payment_attempt!(
          ordr: @ordr,
          success_url: 'https://example.com/success',
          cancel_url: 'https://example.com/cancel',
        )
      end
    end
  end

  test 'create_payment_attempt! returns hash with payment_attempt, next_action, and provider_reference' do
    stub_stripe_checkout_session(@fake_checkout_result) do
      result = Payments::Orchestrator.new.create_payment_attempt!(
        ordr: @ordr,
        success_url: 'https://example.com/success',
        cancel_url: 'https://example.com/cancel',
      )

      assert result.key?(:payment_attempt)
      assert result.key?(:next_action)
      assert result.key?(:provider_reference)
    end
  end

  test 'create_payment_attempt! sets provider_payment_id from checkout_session_id' do
    stub_stripe_checkout_session(@fake_checkout_result) do
      result = Payments::Orchestrator.new.create_payment_attempt!(
        ordr: @ordr,
        success_url: 'https://example.com/success',
        cancel_url: 'https://example.com/cancel',
      )

      assert_equal 'cs_test_abc123', result[:payment_attempt].provider_payment_id
    end
  end

  test 'create_payment_attempt! sets next_action redirect_url from checkout_url' do
    stub_stripe_checkout_session(@fake_checkout_result) do
      result = Payments::Orchestrator.new.create_payment_attempt!(
        ordr: @ordr,
        success_url: 'https://example.com/success',
        cancel_url: 'https://example.com/cancel',
      )

      assert_equal 'https://checkout.stripe.com/pay/cs_test_abc123',
                   result[:next_action][:redirect_url]
    end
  end

  test 'create_payment_attempt! uses USD when restaurant currency is blank' do
    @restaurant.update!(currency: nil)

    stub_stripe_checkout_session(@fake_checkout_result) do
      result = Payments::Orchestrator.new.create_payment_attempt!(
        ordr: @ordr,
        success_url: 'https://example.com/success',
        cancel_url: 'https://example.com/cancel',
      )

      assert_equal 'USD', result[:payment_attempt].currency
    end
  end

  test 'create_payment_attempt! uses restaurant currency when present' do
    @restaurant.update!(currency: 'EUR')

    stub_stripe_checkout_session(@fake_checkout_result) do
      result = Payments::Orchestrator.new.create_payment_attempt!(
        ordr: @ordr,
        success_url: 'https://example.com/success',
        cancel_url: 'https://example.com/cancel',
      )

      assert_equal 'EUR', result[:payment_attempt].currency
    end
  end

  test 'create_payment_attempt! falls back to ordritems sum when gross - tip is zero' do
    @ordr.update!(gross: 0, tip: 0)

    stub_stripe_checkout_session(@fake_checkout_result) do
      assert_nothing_raised do
        Payments::Orchestrator.new.create_payment_attempt!(
          ordr: @ordr,
          success_url: 'https://example.com/success',
          cancel_url: 'https://example.com/cancel',
        )
      end
    end
  end

  test 'create_payment_attempt! sets status requires_action on the PaymentAttempt' do
    stub_stripe_checkout_session(@fake_checkout_result) do
      result = Payments::Orchestrator.new.create_payment_attempt!(
        ordr: @ordr,
        success_url: 'https://example.com/success',
        cancel_url: 'https://example.com/cancel',
      )

      assert_equal 'requires_action', result[:payment_attempt].status
    end
  end

  # ---------------------------------------------------------------------------
  # create_and_capture_payment_intent! — happy path
  # ---------------------------------------------------------------------------

  test 'create_and_capture_payment_intent! creates a PaymentAttempt and appends a LedgerEvent' do
    fake_intent_result = { payment_intent_id: 'pi_test_xyz' }

    stub_stripe_capture_intent(fake_intent_result) do
      assert_difference ['PaymentAttempt.count', 'LedgerEvent.count'], 1 do
        Payments::Orchestrator.new.create_and_capture_payment_intent!(
          ordr: @ordr,
          payment_method_id: 'pm_test_card',
          amount_cents: 2500,
          currency: 'USD',
        )
      end
    end
  end

  test 'create_and_capture_payment_intent! returns payment_attempt and payment_intent_id' do
    fake_intent_result = { payment_intent_id: 'pi_test_xyz' }

    stub_stripe_capture_intent(fake_intent_result) do
      result = Payments::Orchestrator.new.create_and_capture_payment_intent!(
        ordr: @ordr,
        payment_method_id: 'pm_test_card',
        amount_cents: 2500,
        currency: 'USD',
      )

      assert result.key?(:payment_attempt)
      assert_equal 'pi_test_xyz', result[:payment_intent_id]
    end
  end

  # ---------------------------------------------------------------------------
  # CaptureError propagation
  # ---------------------------------------------------------------------------

  test 'create_and_capture_payment_intent! propagates CaptureError from adapter' do
    original_key = Stripe.api_key
    Stripe.api_key = 'sk_test_stub'

    Payments::Providers::StripeAdapter.stub(:new, raise_capture_error_adapter) do
      assert_raises Payments::Orchestrator::CaptureError do
        Payments::Orchestrator.new.create_and_capture_payment_intent!(
          ordr: @ordr,
          payment_method_id: 'pm_card_declined',
          amount_cents: 2500,
          currency: 'USD',
        )
      end
    end
  ensure
    Stripe.api_key = original_key
  end

  # ---------------------------------------------------------------------------
  # Unsupported provider
  # ---------------------------------------------------------------------------

  test 'raises ArgumentError for unsupported provider' do
    orchestrator = Payments::Orchestrator.new(provider: :paypal)
    @profile.update!(primary_provider: :stripe)

    stub_stripe_checkout_session(@fake_checkout_result) do
      assert_raises ArgumentError do
        orchestrator.create_payment_attempt!(
          ordr: @ordr,
          success_url: 'https://example.com/success',
          cancel_url: 'https://example.com/cancel',
        )
      end
    end
  end

  private

  # Minimal Stripe::Checkout::Session double
  def fake_stripe_session(checkout_session_id:, url:, payment_intent: nil)
    obj = Object.new
    obj.define_singleton_method(:id) { checkout_session_id }
    obj.define_singleton_method(:url) { url }
    obj.define_singleton_method(:payment_intent) { payment_intent }
    obj
  end

  def stub_stripe_checkout_session(result, &block)
    # Bypass ensure_api_key! by setting a dummy key and stub Stripe::Checkout::Session.create
    original_key = Stripe.api_key
    Stripe.api_key = 'sk_test_stub'

    fake_session = fake_stripe_session(
      checkout_session_id: result[:checkout_session_id],
      url: result[:checkout_url],
      payment_intent: result[:payment_intent_id],
    )

    Stripe::Checkout::Session.stub(:create, fake_session) do
      block.call
    end
  ensure
    Stripe.api_key = original_key
  end

  def stub_stripe_capture_intent(result, &block)
    original_key = Stripe.api_key
    Stripe.api_key = 'sk_test_stub'

    fake_adapter = Object.new
    fake_adapter.define_singleton_method(:create_and_capture_intent!) do |**_kwargs|
      result
    end

    # Also stub PaymentAttempt#update! so we do not need the adapter to update status
    Payments::Providers::StripeAdapter.stub(:new, fake_adapter) do
      block.call
    end
  ensure
    Stripe.api_key = original_key
  end

  def raise_capture_error_adapter
    obj = Object.new
    obj.define_singleton_method(:create_and_capture_intent!) do |**_kwargs|
      raise Payments::Orchestrator::CaptureError, 'Card declined'
    end
    obj
  end
end
