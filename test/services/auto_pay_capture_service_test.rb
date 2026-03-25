# frozen_string_literal: true

require 'test_helper'

class AutoPayCaptureServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @ordr = ordrs(:one)
    @ordr.update!(
      status: 30, # billrequested
      gross: 42.00,
      tip: 0,
      payment_on_file: true,
      payment_method_ref: 'pm_test_123',
      payment_provider: 'stripe',
      auto_pay_enabled: true,
      auto_pay_status: nil,
    )
  end

  # ─── Precondition failures ──────────────────────────────────────────────

  test 'fails when auto_pay_enabled is false' do
    @ordr.update!(auto_pay_enabled: false)

    result = AutoPay::CaptureService.new(ordr: @ordr).call
    assert result.failure?
    assert_match(/not enabled/, result.error)
  end

  test 'fails when no payment method on file' do
    @ordr.update!(payment_on_file: false)

    result = AutoPay::CaptureService.new(ordr: @ordr).call
    assert result.failure?
    assert_match(/No payment method/, result.error)
  end

  test 'is a no-op when already captured (idempotent)' do
    @ordr.update!(auto_pay_status: 'succeeded')

    result = AutoPay::CaptureService.new(ordr: @ordr).call
    assert result.success?
    # Should not have changed anything
    @ordr.reload
    assert_equal 'succeeded', @ordr.auto_pay_status
  end

  test 'returns failure when order is already paid' do
    @ordr.update!(status: 35) # paid

    result = AutoPay::CaptureService.new(ordr: @ordr).call
    assert result.failure?
    assert_match(/already been paid/, result.error)
  end

  # ─── Zero-total path ────────────────────────────────────────────────────

  test 'zero-total order marks auto_pay_status succeeded without charging' do
    @ordr.update!(gross: 0.0, tip: 0.0)

    # Stub OrderEvent and OrderEventProjector to avoid state machine side effects
    event_stub = OrderEvent.new(id: 1)
    OrderEvent.stub :emit!, event_stub do
      OrderEventProjector.stub :project!, nil do
        # Prevent actual reload from changing ordr status in test
        @ordr.stub :reload, @ordr do
          result = AutoPay::CaptureService.new(ordr: @ordr).call
          assert result.success?
        end
      end
    end

    @ordr.reload
    assert_equal 'succeeded', @ordr.auto_pay_status
  end

  # ─── Successful capture ─────────────────────────────────────────────────

  test 'successful capture sets auto_pay_status to succeeded' do
    pa = PaymentAttempt.new
    orchestrator_result = { payment_attempt: pa, payment_intent_id: 'pi_test_123' }

    fake_orchestrator = lambda { |provider:|
      stub = Object.new
      stub.define_singleton_method(:create_and_capture_payment_intent!) { |**_kwargs| orchestrator_result }
      stub
    }

    event_stub = OrderEvent.new(id: 1)
    OrderEvent.stub :emit!, event_stub do
      OrderEventProjector.stub :project!, nil do
        @ordr.stub :reload, @ordr do
          Payments::Orchestrator.stub :new, fake_orchestrator do
            result = AutoPay::CaptureService.new(ordr: @ordr).call
            assert result.success?
          end
        end
      end
    end

    @ordr.reload
    assert_equal 'succeeded', @ordr.auto_pay_status
    assert_not_nil @ordr.auto_pay_attempted_at
  end

  # ─── Failure path ───────────────────────────────────────────────────────

  test 'capture failure sets auto_pay_status to failed and disables auto_pay' do
    error_orchestrator = Object.new
    def error_orchestrator.create_and_capture_payment_intent!(**_kwargs)
      raise Payments::Orchestrator::CaptureError, 'Card declined: insufficient_funds'
    end

    # Stub ActionCable to avoid broadcast errors in test
    cable_stub = Object.new
    def cable_stub.broadcast(_channel, _payload); end
    ActionCable.stub :server, cable_stub do
      Payments::Orchestrator.stub :new, error_orchestrator do
        result = AutoPay::CaptureService.new(ordr: @ordr).call
        assert result.failure?
        assert_match(/Card declined/, result.error)
      end
    end

    @ordr.reload
    assert_equal 'failed', @ordr.auto_pay_status
    assert_equal false, @ordr.auto_pay_enabled
    assert_not_nil @ordr.auto_pay_failure_reason
  end
end
