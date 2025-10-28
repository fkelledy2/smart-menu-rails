require 'test_helper'

class KitchenBroadcastServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @restaurant.update!(user: users(:one))
  end

  test 'broadcast_new_order should broadcast to kitchen channel' do
    order = ordrs(:one)
    order.update!(restaurant: @restaurant)

    assert_nothing_raised do
      KitchenBroadcastService.broadcast_new_order(order)
    end
  end

  test 'broadcast_status_change should broadcast status update' do
    order = ordrs(:one)
    order.update!(restaurant: @restaurant)

    assert_nothing_raised do
      KitchenBroadcastService.broadcast_status_change(order, 'opened', 'ordered')
    end
  end

  test 'broadcast_inventory_alert should broadcast alert' do
    assert_nothing_raised do
      KitchenBroadcastService.broadcast_inventory_alert(
        @restaurant,
        'Tomatoes',
        5,
        10,
      )
    end
  end

  test 'broadcast_staff_assignment should broadcast assignment' do
    order = ordrs(:one)
    order.update!(restaurant: @restaurant)
    staff = users(:two)

    assert_nothing_raised do
      KitchenBroadcastService.broadcast_staff_assignment(order, staff)
    end
  end

  test 'broadcast_kitchen_metrics should broadcast metrics' do
    metrics = {
      orders_pending: 5,
      avg_prep_time: 15,
      orders_completed_today: 50,
    }

    assert_nothing_raised do
      KitchenBroadcastService.broadcast_kitchen_metrics(@restaurant, metrics)
    end
  end

  test 'broadcast_queue_update should broadcast queue status' do
    assert_nothing_raised do
      KitchenBroadcastService.broadcast_queue_update(@restaurant)
    end
  end
end
