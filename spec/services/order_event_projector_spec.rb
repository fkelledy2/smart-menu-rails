require 'rails_helper'

RSpec.describe OrderEventProjector do
  it 'advances the per-order projection cursor deterministically and is idempotent' do
    ordr = create(:ordr)
    expect(ordr.last_projected_order_event_sequence).to eq(0)

    # Create events without mutating ordr status first, so projection has something to do
    OrderEvent.emit!(
      ordr: ordr,
      event_type: 'status_changed',
      entity_type: 'order',
      entity_id: ordr.id,
      source: 'staff',
      payload: { from: 'opened', to: 'ordered' },
    )

    OrderEvent.emit!(
      ordr: ordr,
      event_type: 'status_changed',
      entity_type: 'order',
      entity_id: ordr.id,
      source: 'staff',
      payload: { from: 'ordered', to: 'preparing' },
    )

    described_class.project!(ordr.id)
    ordr.reload

    expect(ordr.last_projected_order_event_sequence).to eq(2)
    expect(ordr.status.to_s).to eq('preparing')
    expect(ordr.orderedAt).to be_present

    # Re-run should not change anything
    described_class.project!(ordr.id)
    ordr.reload

    expect(ordr.last_projected_order_event_sequence).to eq(2)
    expect(ordr.status.to_s).to eq('preparing')
  end

  it 'sets status timestamps and cascades status to ordritems' do
    ordr = create(:ordr)
    item = Ordritem.create!(
      ordr: ordr,
      menuitem: create(:menuitem),
      status: :opened,
      ordritemprice: 0.0,
      line_key: SecureRandom.uuid,
    )

    OrderEvent.emit!(
      ordr: ordr,
      event_type: 'status_changed',
      entity_type: 'order',
      entity_id: ordr.id,
      source: 'guest',
      payload: { from: 'opened', to: 'billrequested' },
    )

    described_class.project!(ordr.id)
    ordr.reload
    item.reload

    expect(ordr.status.to_s).to eq('billrequested')
    expect(ordr.billRequestedAt).to be_present
    expect(item.status.to_s).to eq('billrequested')
  end

  it 'creates an ordritem from item_added by line_key' do
    ordr = create(:ordr)
    mi = create(:menuitem)
    lk = SecureRandom.uuid

    OrderEvent.emit!(
      ordr: ordr,
      event_type: 'item_added',
      entity_type: 'item',
      source: 'guest',
      payload: { line_key: lk, menuitem_id: mi.id, qty: 1, ordritemprice: 1.23 },
    )

    described_class.project!(ordr.id)

    created = Ordritem.find_by(ordr_id: ordr.id, line_key: lk)
    expect(created).to be_present
    expect(created.menuitem_id).to eq(mi.id)
  end

  it 'marks an ordritem removed by line_key' do
    ordr = create(:ordr)
    mi = create(:menuitem)
    lk = SecureRandom.uuid
    it = Ordritem.create!(ordr: ordr, menuitem: mi, status: :opened, ordritemprice: 5.0, line_key: lk)

    OrderEvent.emit!(
      ordr: ordr,
      event_type: 'item_removed',
      entity_type: 'item',
      entity_id: it.id,
      source: 'guest',
      payload: { line_key: lk, ordritem_id: it.id },
    )

    described_class.project!(ordr.id)
    it.reload

    expect(it.status.to_s).to eq('removed')
    expect(it.ordritemprice.to_f).to eq(0.0)
  end

  it 'clears station tickets on terminal status without FK violations' do
    ordr = create(:ordr)
    ticket = OrdrStationTicket.create!(
      restaurant: ordr.restaurant,
      ordr: ordr,
      station: :kitchen,
      status: :ordered,
      sequence: 1,
    )
    item = Ordritem.create!(
      ordr: ordr,
      menuitem: create(:menuitem),
      status: :opened,
      ordritemprice: 1.0,
      line_key: SecureRandom.uuid,
      ordr_station_ticket: ticket,
    )

    OrderEvent.emit!(
      ordr: ordr,
      event_type: 'status_changed',
      entity_type: 'order',
      entity_id: ordr.id,
      source: 'staff',
      payload: { from: 'opened', to: 'delivered' },
    )

    expect { described_class.project!(ordr.id) }.not_to raise_error

    item.reload
    expect(item.ordr_station_ticket_id).to be_nil
    expect(OrdrStationTicket.where(id: ticket.id).count).to eq(0)
  end
end
