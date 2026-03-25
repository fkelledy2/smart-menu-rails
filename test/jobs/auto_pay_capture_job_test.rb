# frozen_string_literal: true

require 'test_helper'

class AutoPayCaptureJobTest < ActiveJob::TestCase
  def setup
    @ordr = ordrs(:one)
    @ordr.update!(
      status: 30, # billrequested
      gross: 42.00,
      payment_on_file: true,
      payment_method_ref: 'pm_test_123',
      auto_pay_enabled: true,
      auto_pay_status: nil,
    )
  end

  test 'skips when ordr not found — no error raised' do
    assert_nothing_raised do
      AutoPayCaptureJob.new.perform(999_999)
    end
  end

  test 'skips when already captured (idempotency)' do
    @ordr.update!(auto_pay_status: 'succeeded')

    AutoPayCaptureJob.new.perform(@ordr.id)

    @ordr.reload
    assert_equal 'succeeded', @ordr.auto_pay_status
  end

  test 'skips when auto_pay_enabled is false' do
    @ordr.update!(auto_pay_enabled: false)

    assert_nothing_raised do
      AutoPayCaptureJob.new.perform(@ordr.id)
    end

    @ordr.reload
    assert_nil @ordr.auto_pay_status
  end

  test 'calls CaptureService when capturable and records result' do
    success_result = AutoPay::CaptureService::Result.new(success: true, error: nil)

    called_with_ordr = nil
    fake_service = lambda { |ordr:|
      called_with_ordr = ordr
      stub_service = Object.new
      stub_service.define_singleton_method(:call) { success_result }
      stub_service
    }

    AutoPay::CaptureService.stub :new, fake_service do
      AutoPayCaptureJob.new.perform(@ordr.id)
    end

    assert_equal @ordr.id, called_with_ordr.id
  end

  test 're-raises unexpected errors so Sidekiq retry picks them up' do
    error_service = lambda { |ordr:|
      stub = Object.new
      stub.define_singleton_method(:call) { raise 'unexpected' }
      stub
    }

    AutoPay::CaptureService.stub :new, error_service do
      assert_raises(RuntimeError) do
        AutoPayCaptureJob.new.perform(@ordr.id)
      end
    end
  end
end
