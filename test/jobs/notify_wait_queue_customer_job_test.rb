require 'test_helper'

class NotifyWaitQueueCustomerJobTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @entry = customer_wait_queues(:waiting_one)
  end

  test 'does nothing when record not found' do
    assert_nothing_raised { NotifyWaitQueueCustomerJob.new.perform(999_999) }
  end

  test 'does nothing when wait_time_sms flag is disabled' do
    Flipper.disable(:wait_time_sms, @restaurant)
    # Should log and return without SMS send (no credentials needed)
    assert_nothing_raised { NotifyWaitQueueCustomerJob.new.perform(@entry.id) }
  end

  test 'does nothing when customer has no phone number' do
    entry = customer_wait_queues(:waiting_two)  # no customer_phone
    Flipper.enable(:wait_time_sms, entry.restaurant)

    # Should return early without attempting Twilio
    assert_nothing_raised { NotifyWaitQueueCustomerJob.new.perform(entry.id) }

    Flipper.disable(:wait_time_sms, entry.restaurant)
  end
end
