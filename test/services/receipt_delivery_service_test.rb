require 'test_helper'

class ReceiptDeliveryServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @restaurant = restaurants(:one)
    @ordr = ordrs(:one)
    @user = users(:one)

    # Put the order in paid state for most tests
    @ordr.update_column(:status, Ordr.statuses[:paid])

    # Ensure receipt_email flag is enabled for tests
    Flipper.enable(:receipt_email)
  end

  def teardown
    Flipper.disable(:receipt_email)
    Flipper.disable(:receipt_sms)
  end

  # ---------------------------------------------------------------------------
  # Happy path — email
  # ---------------------------------------------------------------------------

  test 'creates a ReceiptDelivery record and enqueues job' do
    assert_difference 'ReceiptDelivery.count', 1 do
      assert_enqueued_with(job: ReceiptDeliveryJob) do
        service.call
      end
    end
  end

  test 'returns the created ReceiptDelivery' do
    delivery = service.call
    assert_instance_of ReceiptDelivery, delivery
    assert_equal 'pending', delivery.status
    assert_equal 'customer@example.com', delivery.recipient_email
    assert_equal 'email', delivery.delivery_method
    assert_equal @ordr.id, delivery.ordr_id
    assert_equal @restaurant.id, delivery.restaurant_id
    assert_equal @user.id, delivery.created_by_user_id
  end

  test 'strips whitespace from recipient_email' do
    svc = build_service(recipient_email: '  hello@example.com  ')
    delivery = svc.call
    assert_equal 'hello@example.com', delivery.recipient_email
  end

  # ---------------------------------------------------------------------------
  # Validation failures — raises DeliveryError
  # ---------------------------------------------------------------------------

  test 'raises DeliveryError when order is not in paid or closed state' do
    @ordr.update_column(:status, Ordr.statuses[:ordered])
    err = assert_raises(ReceiptDeliveryService::DeliveryError) { service.call }
    assert_match(/paid or closed/, err.message)
  end

  test 'raises DeliveryError when recipient_email is blank for email delivery' do
    err = assert_raises(ReceiptDeliveryService::DeliveryError) do
      build_service(recipient_email: nil).call
    end
    assert_match(/email is required/i, err.message)
  end

  test 'raises DeliveryError when recipient_email is invalid' do
    err = assert_raises(ReceiptDeliveryService::DeliveryError) do
      build_service(recipient_email: 'not-an-email').call
    end
    assert_match(/invalid email/i, err.message)
  end

  test 'raises DeliveryError for unknown delivery method' do
    err = assert_raises(ReceiptDeliveryService::DeliveryError) do
      build_service(delivery_method: 'morse_code').call
    end
    assert_match(/unknown delivery method/i, err.message)
  end

  test 'raises DeliveryError for sms when receipt_sms flag is disabled' do
    Flipper.disable(:receipt_sms)
    err = assert_raises(ReceiptDeliveryService::DeliveryError) do
      build_service(delivery_method: 'sms', recipient_email: nil, recipient_phone: '+353861234567').call
    end
    assert_match(/not enabled/i, err.message)
  end

  test 'does not enqueue job when validation fails' do
    @ordr.update_column(:status, Ordr.statuses[:opened])
    assert_no_enqueued_jobs(only: ReceiptDeliveryJob) do
      assert_raises(ReceiptDeliveryService::DeliveryError) { service.call }
    end
  end

  # ---------------------------------------------------------------------------
  # Closed-state order is also allowed
  # ---------------------------------------------------------------------------

  test 'succeeds when order is in closed state' do
    @ordr.update_column(:status, Ordr.statuses[:closed])
    delivery = service.call
    assert_equal 'pending', delivery.status
  end

  private

  def service
    build_service
  end

  def build_service(overrides = {})
    ReceiptDeliveryService.new(ordr: @ordr,
                               delivery_method: 'email',
                               recipient_email: 'customer@example.com',
                               created_by_user: @user, **overrides,)
  end
end
