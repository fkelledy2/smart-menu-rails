require 'test_helper'

class OrdritemEventTest < ActiveSupport::TestCase
  def valid_event_attrs
    {
      ordritem_id: ordritems(:one).id,
      ordr_id: ordritems(:one).ordr_id,
      restaurant_id: restaurants(:one).id,
      event_type: 'fulfillment_status_changed',
      from_status: 0,
      to_status: 1,
      occurred_at: Time.current,
      metadata: {},
    }
  end

  # ── Validations ──��─────────────────────────────────────────────────────────

  test 'is valid with all required attributes' do
    event = OrdritemEvent.new(valid_event_attrs)
    assert event.valid?
  end

  test 'is invalid without event_type' do
    event = OrdritemEvent.new(valid_event_attrs.merge(event_type: nil))
    assert_not event.valid?
    assert_includes event.errors[:event_type], "can't be blank"
  end

  test 'is invalid without occurred_at' do
    event = OrdritemEvent.new(valid_event_attrs.merge(occurred_at: nil))
    assert_not event.valid?
    assert_includes event.errors[:occurred_at], "can't be blank"
  end

  test 'is invalid without to_status' do
    event = OrdritemEvent.new(valid_event_attrs.merge(to_status: nil))
    assert_not event.valid?
    assert_includes event.errors[:to_status], "can't be blank"
  end

  # ── Immutability ────────────────────────────────────────────────────────────

  test 'cannot be updated after creation' do
    event = OrdritemEvent.create!(valid_event_attrs)
    original_type = event.event_type

    result = event.update(event_type: 'tampered')
    assert_equal false, result, 'update should return false (thrown :abort)'
    assert_equal original_type, event.reload.event_type
  end

  test 'cannot be destroyed' do
    event = OrdritemEvent.create!(valid_event_attrs)
    event.destroy
    assert OrdritemEvent.exists?(event.id), 'record should still exist in DB after destroy attempt'
  end

  # ── Associations ────────────────────────────────────────────────────────────

  test 'belongs_to ordritem' do
    event = OrdritemEvent.create!(valid_event_attrs)
    assert_equal ordritems(:one), event.ordritem
  end

  test 'belongs_to restaurant' do
    event = OrdritemEvent.create!(valid_event_attrs)
    assert_equal restaurants(:one), event.restaurant
  end
end
