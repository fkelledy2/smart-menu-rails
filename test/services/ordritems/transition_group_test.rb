require 'test_helper'

class Ordritems::TransitionGroupTest < ActiveSupport::TestCase
  def setup
    Flipper.enable(:ordritem_realtime_tracking)

    @ordr = ordrs(:one)
    @restaurant = restaurants(:one)

    # Set up two kitchen items in pending state
    @item1 = ordritems(:one)
    @item2 = ordritems(:two)
    @item1.update_columns(fulfillment_status: 0, station: 0)
    @item2.update_columns(fulfillment_status: 0, station: 0)

    # item3 is a bar item
    @item3 = ordritems(:three)
    @item3.update_columns(fulfillment_status: 0, station: 1)
  end

  def teardown
    Flipper.disable(:ordritem_realtime_tracking)
  end

  # ── Batch transition ──────────────────────────────────────────────────────

  test 'advances all matching kitchen items from pending to preparing' do
    result = call(station: 'kitchen', from_status: 'pending', to_status: 'preparing')

    assert_equal 2, result[:transitioned_count]
    assert_equal 0, result[:skipped_count]
    assert_empty result[:errors]
    assert_equal 'preparing', @item1.reload.fulfillment_status
    assert_equal 'preparing', @item2.reload.fulfillment_status
    # Bar item unchanged
    assert_equal 'pending', @item3.reload.fulfillment_status
  end

  test 'only advances bar items when station is bar' do
    result = call(station: 'bar', from_status: 'pending', to_status: 'preparing')

    assert_equal 1, result[:transitioned_count]
    assert_equal 'preparing', @item3.reload.fulfillment_status
    # Kitchen items unchanged
    assert_equal 'pending', @item1.reload.fulfillment_status
  end

  # ── Already-in-target-status items are counted as skipped ────────────────

  test 'items already in target status are skipped not errored' do
    @item1.update_columns(fulfillment_status: 1) # already preparing

    result = call(station: 'kitchen', from_status: 'pending', to_status: 'preparing')

    # item1 is not in from_status so it won't be in the scope — only item2 matches
    assert_equal 1, result[:transitioned_count]
    assert_equal 0, result[:skipped_count]
    assert_empty result[:errors]
  end

  # ── Summary hash shape ───────────────────────────────────────────────────

  test 'returns correct summary hash keys' do
    result = call(station: 'kitchen', from_status: 'pending', to_status: 'preparing')

    assert_includes result.keys, :station
    assert_includes result.keys, :from_status
    assert_includes result.keys, :to_status
    assert_includes result.keys, :transitioned_count
    assert_includes result.keys, :skipped_count
    assert_includes result.keys, :errors
  end

  # ── Feature flag gate ─────────────────────────────────────────────────────

  test 'returns error result when feature disabled' do
    Flipper.disable(:ordritem_realtime_tracking)

    result = call(station: 'kitchen', from_status: 'pending', to_status: 'preparing')

    assert_equal 0, result[:transitioned_count]
    assert_not_empty result[:errors]
  end

  # ── Invalid transition propagated to errors ───────────────────────────────

  test 'invalid transition per-item is counted as skipped with error' do
    result = call(station: 'kitchen', from_status: 'pending', to_status: 'ready')

    assert_equal 0, result[:transitioned_count]
    assert_equal 2, result[:skipped_count]
    assert_equal 2, result[:errors].size
  end

  private

  def call(station:, from_status:, to_status:)
    Ordritems::TransitionGroup.new(
      ordr_id: @ordr.id,
      station: station,
      from_status: from_status,
      to_status: to_status,
      actor: nil,
    ).call
  end
end
