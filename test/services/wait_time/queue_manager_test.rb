require 'test_helper'

module WaitTime
  class QueueManagerTest < ActiveSupport::TestCase
    def setup
      @restaurant = restaurants(:one)
      @manager = QueueManager.new(@restaurant)
    end

    # ---------------------------------------------------------------------------
    # enqueue
    # ---------------------------------------------------------------------------

    test 'enqueue creates a CustomerWaitQueue record with waiting status' do
      assert_difference('CustomerWaitQueue.count') do
        result = @manager.enqueue(customer_name: 'New Guest', party_size: 3)
        assert result.success?
        assert_equal 'waiting', result.record.status
        assert_equal 'New Guest', result.record.customer_name
        assert_equal 3, result.record.party_size
        assert result.record.queue_position >= 1
      end
    end

    test 'enqueue sets estimated_wait_minutes and estimated_seat_time' do
      result = @manager.enqueue(customer_name: 'Guest', party_size: 2)
      assert result.success?
      assert result.record.estimated_wait_minutes.present?
      assert result.record.estimated_seat_time.present?
    end

    test 'enqueue with phone stores phone number' do
      result = @manager.enqueue(customer_name: 'Guest', party_size: 2, customer_phone: '+15551234567')
      assert result.success?
      assert_equal '+15551234567', result.record.customer_phone
    end

    test 'enqueue fails when customer_name is blank' do
      result = @manager.enqueue(customer_name: '', party_size: 2)
      assert_not result.success?
      assert_includes result.error, "can't be blank"
    end

    test 'enqueue fails when party_size is zero' do
      result = @manager.enqueue(customer_name: 'Guest', party_size: 0)
      assert_not result.success?
    end

    test 'enqueue assigns sequential queue positions' do
      r1 = @manager.enqueue(customer_name: 'First', party_size: 2)
      r2 = @manager.enqueue(customer_name: 'Second', party_size: 4)

      assert r1.success?
      assert r2.success?
      assert r2.record.queue_position > r1.record.queue_position
    end

    # ---------------------------------------------------------------------------
    # seat
    # ---------------------------------------------------------------------------

    test 'seat transitions status to seated and records seated_at' do
      entry = customer_wait_queues(:waiting_one)
      result = @manager.seat(entry)
      assert result.success?
      assert_equal 'seated', result.record.status
      assert result.record.seated_at.present?
    end

    test 'seat with tablesetting links to the table' do
      entry = customer_wait_queues(:waiting_one)
      ts = tablesettings(:one)
      result = @manager.seat(entry, tablesetting: ts)
      assert result.success?
      assert_equal ts, result.record.tablesetting
    end

    test 'seat fails when entry is already terminal' do
      entry = customer_wait_queues(:seated_one)
      result = @manager.seat(entry)
      assert_not result.success?
      assert_match(/not in an active state/i, result.error)
    end

    test 'seat reorders remaining queue positions' do
      # Ensure positions are sequential first by enqueueing fresh entries
      @restaurant.customer_wait_queues.active.delete_all
      e1 = @manager.enqueue(customer_name: 'A', party_size: 2).record
      e2 = @manager.enqueue(customer_name: 'B', party_size: 2).record
      e3 = @manager.enqueue(customer_name: 'C', party_size: 2).record

      assert_equal 1, e1.queue_position
      assert_equal 2, e2.queue_position
      assert_equal 3, e3.queue_position

      @manager.seat(e1)

      assert_equal 1, e2.reload.queue_position
      assert_equal 2, e3.reload.queue_position
    end

    # ---------------------------------------------------------------------------
    # mark_no_show
    # ---------------------------------------------------------------------------

    test 'mark_no_show transitions status to no_show' do
      entry = customer_wait_queues(:waiting_two)
      result = @manager.mark_no_show(entry)
      assert result.success?
      assert_equal 'no_show', result.record.reload.status
    end

    test 'mark_no_show fails on terminal entry' do
      entry = customer_wait_queues(:seated_one)
      result = @manager.mark_no_show(entry)
      assert_not result.success?
    end

    # ---------------------------------------------------------------------------
    # cancel
    # ---------------------------------------------------------------------------

    test 'cancel transitions status to cancelled' do
      entry = customer_wait_queues(:waiting_one)
      result = @manager.cancel(entry)
      assert result.success?
      assert_equal 'cancelled', result.record.reload.status
    end

    test 'cancel fails on notified entry that is terminal' do
      entry = customer_wait_queues(:seated_one)
      result = @manager.cancel(entry)
      assert_not result.success?
    end

    # ---------------------------------------------------------------------------
    # notify
    # ---------------------------------------------------------------------------

    test 'notify transitions waiting entry to notified' do
      # Use a freshly enqueued entry to avoid fixture state issues
      entry = @manager.enqueue(customer_name: 'Notify Test', party_size: 2).record
      result = @manager.notify(entry)
      assert result.success?
      assert_equal 'notified', result.record.reload.status
    end

    test 'notify fails on non-waiting entry' do
      entry = customer_wait_queues(:notified_one) # already notified
      result = @manager.notify(entry)
      assert_not result.success?
    end

    # ---------------------------------------------------------------------------
    # current_queue
    # ---------------------------------------------------------------------------

    test 'current_queue returns active entries ordered by position' do
      queue = @manager.current_queue
      queue.each { |e| assert e.active? }
      positions = queue.map(&:queue_position)
      assert_equal positions.sort, positions
    end
  end
end
