class OrderEvent < ApplicationRecord
  belongs_to :ordr

  after_create_commit :enqueue_projection

  def self.emit!(ordr:, event_type:, entity_type:, source:, payload: {}, entity_id: nil, idempotency_key: nil,
                 occurred_at: Time.current)
    raise ArgumentError, 'ordr is required' unless ordr

    if idempotency_key.present?
      existing = OrderEvent.find_by(ordr_id: ordr.id, idempotency_key: idempotency_key)
      return existing if existing
    end

    ordr.with_lock do
      if idempotency_key.present?
        existing = OrderEvent.find_by(ordr_id: ordr.id, idempotency_key: idempotency_key)
        return existing if existing
      end

      next_sequence = OrderEvent.where(ordr_id: ordr.id).maximum(:sequence).to_i + 1

      begin
        OrderEvent.create!(
          ordr: ordr,
          sequence: next_sequence,
          event_type: event_type,
          entity_type: entity_type,
          entity_id: entity_id,
          payload: payload || {},
          source: source,
          idempotency_key: idempotency_key,
          occurred_at: occurred_at,
        )
      rescue ActiveRecord::RecordNotUnique
        if idempotency_key.present?
          OrderEvent.find_by!(ordr_id: ordr.id, idempotency_key: idempotency_key)
        else
          raise
        end
      end
    end
  end

  validates :ordr, presence: true
  validates :sequence, presence: true
  validates :event_type, presence: true
  validates :entity_type, presence: true
  validates :source, presence: true
  validates :payload, presence: true
  validates :occurred_at, presence: true

  private

  def enqueue_projection
    OrderEventProjectionJob.perform_later(ordr_id)
  rescue StandardError => e
    Rails.logger.warn("[OrderEvent] Failed to enqueue projection for ordr_id=#{ordr_id}: #{e.class}: #{e.message}")
  end
end
