# frozen_string_literal: true

require 'test_helper'

class LedgerEventTest < ActiveSupport::TestCase
  def build_ledger_event(overrides = {})
    LedgerEvent.new({
      provider: :stripe,
      provider_event_id: "evt_#{SecureRandom.hex(8)}",
      entity_type: :payment_attempt,
      event_type: :created,
    }.merge(overrides))
  end

  # =========================================================================
  # validations
  # =========================================================================

  test 'is valid with all required attributes' do
    assert build_ledger_event.valid?
  end

  test 'is invalid without provider_event_id' do
    event = build_ledger_event(provider_event_id: nil)
    assert_not event.valid?
    assert event.errors[:provider_event_id].any?
  end

  test 'is invalid without entity_type' do
    event = build_ledger_event
    event.write_attribute(:entity_type, nil)
    assert_not event.valid?
    assert event.errors[:entity_type].any?
  end

  test 'is invalid without event_type' do
    event = build_ledger_event
    event.write_attribute(:event_type, nil)
    assert_not event.valid?
    assert event.errors[:event_type].any?
  end

  # =========================================================================
  # enums
  # =========================================================================

  test 'provider enum has stripe and square' do
    assert build_ledger_event(provider: :stripe).stripe?
    assert build_ledger_event(provider: :square).square?
  end

  test 'entity_type enum has all expected types' do
    %i[payment_attempt refund transfer dispute payout].each do |type|
      event = build_ledger_event(entity_type: type)
      assert_equal type.to_s, event.entity_type
    end
  end

  test 'event_type enum has all expected types' do
    %i[created authorized captured succeeded failed refunded dispute_opened].each do |type|
      event = build_ledger_event(event_type: type)
      assert_equal type.to_s, event.event_type
    end
  end

  test 'can be saved with all required fields' do
    event = build_ledger_event
    assert event.save, event.errors.full_messages.join(', ')
  end
end
