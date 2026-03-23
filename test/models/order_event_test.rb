# frozen_string_literal: true

require 'test_helper'

class OrderEventTest < ActiveSupport::TestCase
  def setup
    @ordr = ordrs(:one)
  end

  # =========================================================================
  # validations
  # =========================================================================

  test 'is invalid without sequence' do
    event = OrderEvent.new(
      ordr: @ordr,
      event_type: 'status_changed',
      entity_type: 'Ordr',
      source: 'test',
      payload: {},
      occurred_at: Time.current,
    )
    event.sequence = nil
    assert_not event.valid?
    assert event.errors[:sequence].any?
  end

  test 'is invalid without event_type' do
    event = OrderEvent.new(
      ordr: @ordr,
      sequence: 1,
      entity_type: 'Ordr',
      source: 'test',
      payload: {},
      occurred_at: Time.current,
    )
    assert_not event.valid?
    assert event.errors[:event_type].any?
  end

  test 'is invalid without source' do
    event = OrderEvent.new(
      ordr: @ordr,
      sequence: 1,
      event_type: 'status_changed',
      entity_type: 'Ordr',
      payload: {},
      occurred_at: Time.current,
    )
    assert_not event.valid?
    assert event.errors[:source].any?
  end

  # =========================================================================
  # emit!
  # =========================================================================

  test 'emit! creates an OrderEvent record' do
    count_before = OrderEvent.where(ordr_id: @ordr.id).count

    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'status_changed',
      entity_type: 'Ordr',
      source: 'api',
      payload: { from: 'opened', to: 'ordered' },
    )

    assert_equal count_before + 1, OrderEvent.where(ordr_id: @ordr.id).count
  end

  test 'emit! raises ArgumentError when ordr is nil' do
    assert_raises(ArgumentError, /ordr is required/) do
      OrderEvent.emit!(
        ordr: nil,
        event_type: 'status_changed',
        entity_type: 'Ordr',
        source: 'test',
      )
    end
  end

  test 'emit! assigns auto-incrementing sequence numbers' do
    e1 = OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'item_added',
      entity_type: 'Ordritem',
      source: 'test',
      payload: { line_key: 'lk-1' },
    )

    e2 = OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'item_added',
      entity_type: 'Ordritem',
      source: 'test',
      payload: { line_key: 'lk-2' },
    )

    assert e2.sequence > e1.sequence
  end

  test 'emit! with idempotency_key returns same record on duplicate call' do
    key = "idem-#{SecureRandom.hex(8)}"

    e1 = OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'paid',
      entity_type: 'Ordr',
      source: 'webhook',
      idempotency_key: key,
      payload: { status: 'paid' },
    )

    e2 = OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'paid',
      entity_type: 'Ordr',
      source: 'webhook',
      idempotency_key: key,
      payload: { status: 'paid' },
    )

    assert_equal e1.id, e2.id
  end

  test 'emit! without idempotency_key creates separate events each time' do
    count_before = OrderEvent.where(ordr_id: @ordr.id).count

    2.times do
      OrderEvent.emit!(
        ordr: @ordr,
        event_type: 'status_changed',
        entity_type: 'Ordr',
        source: 'test',
        payload: { status: 'ordered' },
      )
    end

    assert_equal count_before + 2, OrderEvent.where(ordr_id: @ordr.id).count
  end

  test 'emit! enqueues an OrderEventProjectionJob after creation' do
    enqueued_count_before = ActiveJob::Base.queue_adapter.enqueued_jobs.count

    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'closed',
      entity_type: 'Ordr',
      source: 'test',
      payload: { status: 'closed' },
    )

    assert_operator ActiveJob::Base.queue_adapter.enqueued_jobs.count, :>, enqueued_count_before
  end
end
