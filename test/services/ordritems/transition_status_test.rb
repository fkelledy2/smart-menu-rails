require 'test_helper'

class Ordritems::TransitionStatusTest < ActiveSupport::TestCase
  def setup
    Flipper.enable(:ordritem_realtime_tracking)

    @restaurant = restaurants(:one)
    @ordr       = ordrs(:one)
    @ordritem   = ordritems(:one)
    # Ensure clean state
    @ordritem.update_columns(fulfillment_status: 0, station: 0)
  end

  def teardown
    Flipper.disable(:ordritem_realtime_tracking)
  end

  # ── Allowed transitions ──────────────────────────────────────────────────

  test 'pending -> preparing succeeds' do
    result = call(to_status: 'preparing')

    assert result[:success], "Expected success but got: #{result[:error]}"
    assert_equal 'preparing', @ordritem.reload.fulfillment_status
    assert_not_nil @ordritem.preparing_at
    assert_not_nil @ordritem.fulfillment_status_changed_at
  end

  test 'preparing -> ready succeeds' do
    @ordritem.update_columns(fulfillment_status: 1, preparing_at: 1.minute.ago)

    result = call(to_status: 'ready')

    assert result[:success]
    assert_equal 'ready', @ordritem.reload.fulfillment_status
    assert_not_nil @ordritem.ready_at
  end

  test 'ready -> collected succeeds' do
    @ordritem.update_columns(fulfillment_status: 2, preparing_at: 2.minutes.ago, ready_at: 1.minute.ago)

    result = call(to_status: 'collected')

    assert result[:success]
    assert_equal 'collected', @ordritem.reload.fulfillment_status
    assert_not_nil @ordritem.collected_at
  end

  # ── Invalid transitions ──────────────────────────────────────────────────

  test 'pending -> ready is rejected' do
    result = call(to_status: 'ready')

    assert_not result[:success]
    assert_equal 'Invalid transition', result[:error]
    assert_equal 'pending', @ordritem.reload.fulfillment_status
  end

  test 'pending -> collected is rejected' do
    result = call(to_status: 'collected')

    assert_not result[:success]
    assert_equal 'Invalid transition', result[:error]
  end

  test 'ready -> preparing is rejected (backward)' do
    @ordritem.update_columns(fulfillment_status: 2)

    result = call(to_status: 'preparing')

    assert_not result[:success]
    assert_equal 'Invalid transition', result[:error]
  end

  # ── Idempotency ───────────────────────────────────────────────────────────

  test 'transitioning to current status is a noop' do
    @ordritem.update_columns(fulfillment_status: 1)

    assert_no_difference 'OrdritemEvent.count' do
      result = call(to_status: 'preparing')

      assert result[:success]
      assert result[:noop]
    end
  end

  test 'two rapid calls produce exactly one event' do
    assert_difference 'OrdritemEvent.count', 1 do
      call(to_status: 'preparing')
      call(to_status: 'preparing') # idempotent
    end
  end

  # ── Event creation ────────────────────────────────────────────────────────

  test 'creates an OrdritemEvent on successful transition' do
    assert_difference 'OrdritemEvent.count', 1 do
      call(to_status: 'preparing')
    end

    event = OrdritemEvent.last
    assert_equal 'fulfillment_status_changed', event.event_type
    assert_equal Ordritem.fulfillment_statuses['pending'], event.from_status
    assert_equal Ordritem.fulfillment_statuses['preparing'], event.to_status
    assert_equal @ordritem.id, event.ordritem_id
    assert_equal @ordr.id, event.ordr_id
  end

  test 'records actor when provided' do
    actor = users(:one)

    call(to_status: 'preparing', actor: actor)

    event = OrdritemEvent.last
    assert_equal 'User', event.actor_type
    assert_equal actor.id, event.actor_id
  end

  test 'records nil actor when none provided' do
    call(to_status: 'preparing')

    event = OrdritemEvent.last
    assert_nil event.actor_type
    assert_nil event.actor_id
  end

  # ── Feature flag gate ─────────────────────────────────────────────────────

  test 'returns failure when feature flag is disabled' do
    Flipper.disable(:ordritem_realtime_tracking)

    result = call(to_status: 'preparing')

    assert_not result[:success]
    assert_equal 'Feature not enabled', result[:error]
  end

  # ── Timestamp correctness ─────────────────────────────────────────────────

  test 'sets preparing_at when transitioning to preparing' do
    call(to_status: 'preparing')
    assert_in_delta Time.current.to_f, @ordritem.reload.preparing_at.to_f, 2
  end

  test 'sets ready_at when transitioning to ready' do
    @ordritem.update_columns(fulfillment_status: 1, preparing_at: 1.minute.ago)
    call(to_status: 'ready')
    assert_in_delta Time.current.to_f, @ordritem.reload.ready_at.to_f, 2
  end

  test 'sets collected_at when transitioning to collected' do
    @ordritem.update_columns(fulfillment_status: 2, preparing_at: 2.minutes.ago, ready_at: 1.minute.ago)
    call(to_status: 'collected')
    assert_in_delta Time.current.to_f, @ordritem.reload.collected_at.to_f, 2
  end

  private

  def call(to_status:, actor: nil)
    Ordritems::TransitionStatus.new(
      ordritem: @ordritem,
      to_status: to_status,
      actor: actor,
    ).call
  end
end
