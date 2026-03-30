# frozen_string_literal: true

# Manages the customer wait queue for a restaurant.
# All mutations go through this service — controllers stay thin.
module WaitTime
  class QueueManager
    Result = Struct.new(:success, :record, :error, keyword_init: true) do
      def success? = success
    end

    def initialize(restaurant)
      @restaurant = restaurant
    end

    # Add a new customer to the wait queue.
    # Returns a Result with the created CustomerWaitQueue record on success.
    def enqueue(customer_name:, party_size:, customer_phone: nil)
      estimated_wait = EstimationService.new(@restaurant).estimate_for_party(party_size)
      position = next_queue_position

      record = @restaurant.customer_wait_queues.build(
        customer_name: customer_name,
        customer_phone: customer_phone,
        party_size: party_size,
        joined_queue_at: Time.current,
        queue_position: position,
        estimated_wait_minutes: estimated_wait,
        estimated_seat_time: estimated_wait.minutes.from_now,
        status: 'waiting',
      )

      if record.save
        Result.new(success: true, record: record)
      else
        Result.new(success: false, record: record, error: record.errors.full_messages.join(', '))
      end
    end

    # Mark a queued customer as seated. Optionally link to a tablesetting.
    # Reorders remaining queue positions.
    def seat(wait_queue_entry, tablesetting: nil)
      unless wait_queue_entry.active?
        return Result.new(success: false, error: 'Entry is not in an active state')
      end

      success = wait_queue_entry.update(
        status: 'seated',
        seated_at: Time.current,
        tablesetting: tablesetting,
      )

      if success
        reorder_positions_after(wait_queue_entry.queue_position)
        Result.new(success: true, record: wait_queue_entry)
      else
        Result.new(success: false, record: wait_queue_entry,
                   error: wait_queue_entry.errors.full_messages.join(', '),)
      end
    end

    # Mark a queued customer as no-show. Reorders remaining queue positions.
    def mark_no_show(wait_queue_entry)
      unless wait_queue_entry.active?
        return Result.new(success: false, error: 'Entry is not in an active state')
      end

      success = wait_queue_entry.update(status: 'no_show')
      if success
        reorder_positions_after(wait_queue_entry.queue_position)
        Result.new(success: true, record: wait_queue_entry)
      else
        Result.new(success: false, record: wait_queue_entry,
                   error: wait_queue_entry.errors.full_messages.join(', '),)
      end
    end

    # Cancel a queued customer. Reorders remaining queue positions.
    def cancel(wait_queue_entry)
      unless wait_queue_entry.active?
        return Result.new(success: false, error: 'Entry is not in an active state')
      end

      success = wait_queue_entry.update(status: 'cancelled')
      if success
        reorder_positions_after(wait_queue_entry.queue_position)
        Result.new(success: true, record: wait_queue_entry)
      else
        Result.new(success: false, record: wait_queue_entry,
                   error: wait_queue_entry.errors.full_messages.join(', '),)
      end
    end

    # Notify the customer their table is ready.
    def notify(wait_queue_entry)
      unless wait_queue_entry.waiting?
        return Result.new(success: false, error: 'Entry is not in waiting state')
      end

      success = wait_queue_entry.update(status: 'notified')
      if success
        Result.new(success: true, record: wait_queue_entry)
      else
        Result.new(success: false, record: wait_queue_entry,
                   error: wait_queue_entry.errors.full_messages.join(', '),)
      end
    end

    # Return the current active queue for this restaurant, ordered by position.
    def current_queue
      @restaurant.customer_wait_queues
        .active
        .by_position
    end

    private

    def next_queue_position
      max = @restaurant.customer_wait_queues.active.maximum(:queue_position) || 0
      max + 1
    end

    # After removing an entry at +vacated_position+, decrement all higher positions.
    def reorder_positions_after(vacated_position)
      @restaurant.customer_wait_queues
        .active
        .where('queue_position > ?', vacated_position)
        .update_all('queue_position = queue_position - 1')
    end
  end
end
