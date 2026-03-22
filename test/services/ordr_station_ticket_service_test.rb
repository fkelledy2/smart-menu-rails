require 'test_helper'

class OrdrStationTicketServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @ordr = ordrs(:one)
  end

  # === stream_name ===

  test 'stream_name returns station_restaurantid format' do
    assert_equal 'kitchen_42', OrdrStationTicketService.stream_name(42, 'kitchen')
    assert_equal 'bar_7', OrdrStationTicketService.stream_name(7, 'bar')
  end

  # === submit_unsubmitted_items! early returns ===

  test 'submit_unsubmitted_items! returns false for nil order' do
    assert_equal false, OrdrStationTicketService.submit_unsubmitted_items!(nil)
  end

  test 'submit_unsubmitted_items! returns false when all items already have tickets' do
    ActionCable.server.stub(:broadcast, nil) do
      # Create a real ticket then assign all items to it
      ticket = OrdrStationTicket.create!(
        restaurant_id: @restaurant.id,
        ordr_id: @ordr.id,
        station: :kitchen,
        status: :ordered,
        sequence: 99,
        submitted_at: Time.current,
      )
      @ordr.ordritems.update_all(ordr_station_ticket_id: ticket.id)

      result = OrdrStationTicketService.submit_unsubmitted_items!(@ordr)
      assert_equal false, result

      @ordr.ordritems.update_all(ordr_station_ticket_id: nil)
      ticket.destroy
    end
  end

  # === rollup_order_status_if_ready! early returns ===

  test 'rollup_order_status_if_ready! returns nil for nil order' do
    assert_nil OrdrStationTicketService.rollup_order_status_if_ready!(nil)
  end

  test 'rollup_order_status_if_ready! returns nil when no tickets exist' do
    # No OrdrStationTickets for the fixture ordr — returns nil early
    result = OrdrStationTicketService.rollup_order_status_if_ready!(@ordr)
    assert_nil result
  end

  # === submit and ticket creation ===

  test 'submit_unsubmitted_items! creates a kitchen ticket for food items' do
    # Ensure the ordr has food items with no ticket
    food_item = ordritems(:one) # menuitem burger (food)
    food_item.update!(ordr_station_ticket_id: nil, status: 0)

    # Stub ActionCable broadcast to avoid connection attempt
    ActionCable.server.stub(:broadcast, nil) do
      result = OrdrStationTicketService.submit_unsubmitted_items!(@ordr)
      assert result, 'expected true when tickets are created'
    end

    food_item.reload
    assert_not_nil food_item.ordr_station_ticket_id
  end

  test 'submit_unsubmitted_items! advances order to ordered status from opened' do
    @ordr.update!(status: :opened)
    ordritems(:one).update!(ordr_station_ticket_id: nil, status: 0)

    ActionCable.server.stub(:broadcast, nil) do
      OrdrStationTicketService.submit_unsubmitted_items!(@ordr)
    end

    @ordr.reload
    assert_equal 'ordered', @ordr.status
  end

  # === rollup to ready ===

  test 'rollup_order_status_if_ready! sets order to ready when all tickets are ready' do
    @ordr.update!(status: :ordered)

    ActionCable.server.stub(:broadcast, nil) do
      ticket = OrdrStationTicket.create!(
        restaurant_id: @restaurant.id,
        ordr_id: @ordr.id,
        station: :kitchen,
        status: :ready,
        sequence: 1,
        submitted_at: Time.current,
      )

      OrdrStationTicketService.rollup_order_status_if_ready!(@ordr)

      @ordr.reload
      assert_equal 'ready', @ordr.status

      ticket.destroy
    end
  end

  test 'rollup_order_status_if_ready! does not advance when not all tickets are ready' do
    @ordr.update!(status: :ordered)

    ActionCable.server.stub(:broadcast, nil) do
      t1 = OrdrStationTicket.create!(
        restaurant_id: @restaurant.id,
        ordr_id: @ordr.id,
        station: :kitchen,
        status: :ordered,
        sequence: 1,
        submitted_at: Time.current,
      )

      OrdrStationTicketService.rollup_order_status_if_ready!(@ordr)

      @ordr.reload
      assert_equal 'ordered', @ordr.status

      t1.destroy
    end
  end

  # === broadcast_ticket_event ===

  test 'broadcast_ticket_event returns nil for nil ticket' do
    assert_nil OrdrStationTicketService.broadcast_ticket_event(nil, event: 'new_ticket')
  end
end
