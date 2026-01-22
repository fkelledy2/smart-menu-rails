require 'rails_helper'

RSpec.describe OrderStateReducer do
  def event(attrs)
    # Simple duck-typed event for unit tests (no DB required)
    OpenStruct.new({
      id: attrs.fetch(:id, 0),
      sequence: attrs.fetch(:sequence),
      event_type: attrs.fetch(:event_type),
      entity_id: attrs[:entity_id],
      payload: attrs.fetch(:payload, {}),
      occurred_at: attrs.fetch(:occurred_at, Time.at(0)),
      created_at: attrs.fetch(:created_at, Time.at(0))
    })
  end

  it 'reduces deterministically by sequence ordering' do
    events = [
      event(sequence: 2, id: 2, event_type: 'status_changed', payload: { from: 'opened', to: 'ordered' }),
      event(sequence: 1, id: 1, event_type: 'item_added', entity_id: 111, payload: { menuitem_id: 5, qty: 1 }),
      event(sequence: 3, id: 3, event_type: 'item_removed', payload: { ordritem_id: 111 })
    ]

    result = described_class.reduce(events)

    expect(result.unsupported_events).to eq([])
    expect(result.state[:status]).to eq('ordered')
    expect(result.state[:items]).to eq({})
  end

  it 'collects unsupported events without corrupting state' do
    events = [
      event(sequence: 1, id: 1, event_type: 'unknown_type', payload: { foo: 'bar' }),
      event(sequence: 2, id: 2, event_type: 'bill_requested', payload: {})
    ]

    result = described_class.reduce(events)

    expect(result.state[:status]).to eq('billrequested')
    expect(result.unsupported_events.length).to eq(1)
    expect(result.unsupported_events.first.event_type).to eq('unknown_type')
  end
end
