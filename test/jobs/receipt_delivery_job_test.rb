require 'test_helper'

class ReceiptDeliveryJobTest < ActiveSupport::TestCase
  def setup
    @ordr = ordrs(:one)
    @restaurant = restaurants(:one)

    @ordr.update_column(:status, Ordr.statuses[:paid])
    @ordr.update_columns(gross: 24.97, tax: 2.25, tip: 2.00)

    @delivery = ReceiptDelivery.create!(
      ordr: @ordr,
      restaurant: @restaurant,
      recipient_email: 'test@example.com',
      delivery_method: 'email',
      status: 'pending',
    )
  end

  # ---------------------------------------------------------------------------
  # Happy path
  # ---------------------------------------------------------------------------

  test 'marks delivery as sent after successful email dispatch' do
    assert_emails 1 do
      ReceiptDeliveryJob.new.perform(@delivery.id)
    end
    @delivery.reload
    assert @delivery.sent?
    assert_not_nil @delivery.sent_at
  end

  test 'sends the email to the correct recipient' do
    email = nil
    assert_emails 1 do
      ReceiptDeliveryJob.new.perform(@delivery.id)
      email = ActionMailer::Base.deliveries.last
    end
    assert_equal ['test@example.com'], email.to
  end

  # ---------------------------------------------------------------------------
  # Guard clauses
  # ---------------------------------------------------------------------------

  test 'skips gracefully when ReceiptDelivery record does not exist' do
    assert_nothing_raised do
      assert_emails 0 do
        ReceiptDeliveryJob.new.perform(999_999_999)
      end
    end
  end

  test 'skips when delivery is already sent' do
    @delivery.mark_sent!
    assert_emails 0 do
      ReceiptDeliveryJob.new.perform(@delivery.id)
    end
  end

  # ---------------------------------------------------------------------------
  # Failure path
  # ---------------------------------------------------------------------------

  test 'marks delivery as failed and increments retry_count on mailer error' do
    ReceiptMailer.stub(:customer_receipt, ->(*) { raise StandardError, 'SMTP down' }) do
      assert_raises(StandardError) do
        ReceiptDeliveryJob.new.perform(@delivery.id)
      end
    end

    @delivery.reload
    assert @delivery.failed?
    assert_match(/SMTP down/, @delivery.error_message)
    assert_equal 1, @delivery.retry_count
  end

  # ---------------------------------------------------------------------------
  # SMS guard
  # ---------------------------------------------------------------------------

  test 'marks sms delivery as failed when receipt_sms flag is disabled' do
    Flipper.disable(:receipt_sms)

    sms_delivery = ReceiptDelivery.create!(
      ordr: @ordr,
      restaurant: @restaurant,
      recipient_phone: '+353861234567',
      delivery_method: 'sms',
      status: 'pending',
    )

    ReceiptDeliveryJob.new.perform(sms_delivery.id)

    sms_delivery.reload
    assert sms_delivery.failed?
    assert_match(/not enabled/, sms_delivery.error_message)
  ensure
    Flipper.disable(:receipt_sms)
  end
end
