require 'rails_helper'

RSpec.describe OrderEvent, type: :model do
  describe '.emit!' do
    it 'allocates a monotonic sequence per order under lock' do
      ordr = create(:ordr)

      evt1 = described_class.emit!(
        ordr: ordr,
        event_type: 'item_added',
        entity_type: 'item',
        entity_id: 123,
        source: 'guest',
        payload: { menuitem_id: 1, qty: 1 },
      )

      evt2 = described_class.emit!(
        ordr: ordr,
        event_type: 'status_changed',
        entity_type: 'order',
        entity_id: ordr.id,
        source: 'staff',
        payload: { from: 'opened', to: 'ordered' },
      )

      expect(evt1.sequence).to eq(1)
      expect(evt2.sequence).to eq(2)
    end

    it 'dedupes by idempotency_key per order' do
      ordr = create(:ordr)

      evt1 = described_class.emit!(
        ordr: ordr,
        event_type: 'paid',
        entity_type: 'payment',
        source: 'webhook',
        idempotency_key: 'stripe:pi_123',
        payload: { provider: 'stripe', external_ref: 'pi_123' },
      )

      evt2 = described_class.emit!(
        ordr: ordr,
        event_type: 'paid',
        entity_type: 'payment',
        source: 'webhook',
        idempotency_key: 'stripe:pi_123',
        payload: { provider: 'stripe', external_ref: 'pi_123' },
      )

      expect(evt2.id).to eq(evt1.id)
      expect(described_class.where(ordr_id: ordr.id, idempotency_key: 'stripe:pi_123').count).to eq(1)
    end
  end
end
