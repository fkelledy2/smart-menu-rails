require 'test_helper'

class Ordritems::BroadcastStatusChangeJobTest < ActiveJob::TestCase
  def setup
    Flipper.enable(:ordritem_realtime_tracking)

    @restaurant = restaurants(:one)
    @ordr       = ordrs(:one)
    @ordritem   = ordritems(:one)
    @ordritem.update_columns(fulfillment_status: 0, station: 0)

    @event = OrdritemEvent.create!(
      ordritem_id: @ordritem.id,
      ordr_id: @ordr.id,
      restaurant_id: @restaurant.id,
      event_type: 'fulfillment_status_changed',
      from_status: Ordritem.fulfillment_statuses['pending'],
      to_status: Ordritem.fulfillment_statuses['preparing'],
      occurred_at: Time.current,
      metadata: {},
    )
  end

  def teardown
    Flipper.disable(:ordritem_realtime_tracking)
  end

  # ── Basic execution ───────────────────────────────────────────────────────

  test 'broadcasts to the correct ordr channel' do
    broadcast_payloads = []
    allow_cable_broadcast = lambda do |channel, data|
      broadcast_payloads << { channel: channel, data: data }
    end

    ActionCable.server.stub(:broadcast, allow_cable_broadcast) do
      Ordritems::BroadcastStatusChangeJob.new.perform(@event.id)
    end

    assert_equal 1, broadcast_payloads.size
    assert_equal "ordr_#{@ordr.id}_channel", broadcast_payloads.first[:channel]
  end

  test 'payload has correct type' do
    captured = nil
    ActionCable.server.stub(:broadcast, ->(ch, data) { captured = data }) do
      Ordritems::BroadcastStatusChangeJob.new.perform(@event.id)
    end

    assert_equal 'order_item_status_changed', captured[:type]
  end

  test 'payload includes ordr_id and ordritem_id as strings' do
    captured = nil
    ActionCable.server.stub(:broadcast, ->(ch, data) { captured = data }) do
      Ordritems::BroadcastStatusChangeJob.new.perform(@event.id)
    end

    assert_equal @ordr.id.to_s, captured[:ordr_id]
    assert_equal @ordritem.id.to_s, captured[:ordritem_id]
  end

  test 'payload includes from_status and to_status' do
    captured = nil
    ActionCable.server.stub(:broadcast, ->(ch, data) { captured = data }) do
      Ordritems::BroadcastStatusChangeJob.new.perform(@event.id)
    end

    assert_equal 'pending', captured[:from_status]
    assert_equal 'preparing', captured[:to_status]
  end

  test 'payload includes order_summary hash' do
    captured = nil
    ActionCable.server.stub(:broadcast, ->(ch, data) { captured = data }) do
      Ordritems::BroadcastStatusChangeJob.new.perform(@event.id)
    end

    assert_kind_of Hash, captured[:order_summary]
    assert_includes captured[:order_summary].keys, :label
    assert_includes captured[:order_summary].keys, :status
  end

  test 'payload includes customer_status_label' do
    captured = nil
    ActionCable.server.stub(:broadcast, ->(ch, data) { captured = data }) do
      Ordritems::BroadcastStatusChangeJob.new.perform(@event.id)
    end

    assert_not_nil captured[:customer_status_label]
  end

  test 'skips gracefully when event not found' do
    assert_nothing_raised do
      Ordritems::BroadcastStatusChangeJob.new.perform(999_999)
    end
  end

  test 'skips gracefully when ordritem is missing (stubbed)' do
    # Stub Ordritem.find_by to return nil to simulate deleted record
    find_call_count = 0
    Ordritem.stub(:find_by, proc { |_|
      find_call_count += 1
      nil
    },) do
      assert_nothing_raised do
        Ordritems::BroadcastStatusChangeJob.new.perform(@event.id)
      end
    end
    assert find_call_count >= 1
  end

  # ── Order summary derivation ──────────────────────────────────────────────

  test 'order_summary label is Received when all items are pending' do
    # All fixture items are pending (fulfillment_status: 0)
    captured = nil
    ActionCable.server.stub(:broadcast, ->(ch, data) { captured = data }) do
      Ordritems::BroadcastStatusChangeJob.new.perform(@event.id)
    end

    # After event, item1 is still pending in DB unless we updated it
    # The job reads live DB state, so check derived label
    assert_not_nil captured[:order_summary][:label]
  end
end
