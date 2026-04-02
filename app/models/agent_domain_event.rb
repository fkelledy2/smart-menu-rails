# frozen_string_literal: true

# AgentDomainEvent is the durable event log that the Dispatcher polls.
# Events are written by the platform when something interesting happens
# (order completed, menu updated, etc.) and consumed by agents.
# The idempotency_key unique index prevents duplicate processing.
class AgentDomainEvent < ApplicationRecord
  belongs_to :source, polymorphic: true, optional: true

  validates :event_type, presence: true
  validates :idempotency_key, presence: true, uniqueness: true

  scope :unprocessed, -> { where(processed_at: nil) }
  scope :processed,   -> { where.not(processed_at: nil) }
  scope :recent,      -> { order(created_at: :desc) }

  def processed?
    processed_at.present?
  end

  def mark_processed!
    update!(processed_at: Time.current)
  end

  # Publish a domain event safely — idempotent on idempotency_key.
  # Returns the existing event if the key already exists.
  # @param event_type [String] e.g. 'order.completed'
  # @param source [ActiveRecord::Base, nil] polymorphic source record
  # @param payload [Hash] event data
  # @param idempotency_key [String] caller-provided dedup key
  def self.publish!(event_type:, payload: {}, source: nil, idempotency_key: nil)
    key = idempotency_key || "#{event_type}:#{SecureRandom.hex(16)}"

    existing = find_by(idempotency_key: key)
    return existing if existing

    create!(
      event_type: event_type,
      source: source,
      payload: payload,
      idempotency_key: key,
    )
  rescue ActiveRecord::RecordNotUnique
    # Race condition: another process created it first.
    find_by!(idempotency_key: key)
  end
end
