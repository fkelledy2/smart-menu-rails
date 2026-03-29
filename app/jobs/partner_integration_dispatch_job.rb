# frozen_string_literal: true

# Dispatches a canonical partner event to a single adapter asynchronously.
# Retries up to 3 times with exponential backoff. On final failure, writes
# a dead-letter record to partner_integration_error_logs.
#
# Arguments are plain JSON-serialisable types so Sidekiq can marshal them
# safely — no ActiveRecord objects are passed.
class PartnerIntegrationDispatchJob < ApplicationJob
  queue_as :partner_integrations

  # 3 attempts total: 1 initial + 2 retries
  MAX_ATTEMPTS = 3

  retry_on StandardError, wait: :polynomially_longer, attempts: MAX_ATTEMPTS do |job, error|
    # Final failure handler — write to dead-letter log
    job.send(:record_dead_letter, error)
  end

  def perform(restaurant_id:, adapter_type:, event_payload:)
    restaurant = Restaurant.find_by(id: restaurant_id)
    unless restaurant
      Rails.logger.warn("[PartnerIntegrationDispatchJob] restaurant not found id=#{restaurant_id}")
      return
    end

    adapter_class = PartnerIntegrations::EventEmitter::ADAPTER_REGISTRY[adapter_type.to_s]
    unless adapter_class
      Rails.logger.warn("[PartnerIntegrationDispatchJob] unknown adapter_type=#{adapter_type}")
      return
    end

    event = build_event(event_payload)
    return unless event

    @restaurant_id = restaurant_id
    @adapter_type  = adapter_type
    @event_payload = event_payload

    adapter_class.new.call(event: event)

    Rails.logger.info(
      "[PartnerIntegrationDispatchJob] dispatched adapter=#{adapter_type} " \
      "event=#{event.event_type} restaurant=#{restaurant_id}",
    )
  end

  private

  def build_event(payload)
    PartnerIntegrations::CanonicalEvent.new(
      event_type: payload['event_type'],
      restaurant_id: payload['restaurant_id'],
      occurred_at: Time.zone.parse(payload['occurred_at']),
      idempotency_key: payload['idempotency_key'],
      payload: payload['payload'] || {},
    )
  rescue ArgumentError, TypeError => e
    Rails.logger.error("[PartnerIntegrationDispatchJob] failed to build event: #{e.message}")
    nil
  end

  def record_dead_letter(error)
    PartnerIntegrationErrorLog.create!(
      restaurant_id: @restaurant_id || 0,
      adapter_type: (@adapter_type || 'unknown').to_s.truncate(100),
      event_type: (@event_payload&.dig('event_type') || 'unknown').to_s.truncate(100),
      payload_json: @event_payload || {},
      error_message: "#{error.class}: #{error.message}".truncate(2000),
      attempt_number: MAX_ATTEMPTS,
    )
  rescue StandardError => e
    Rails.logger.error(
      "[PartnerIntegrationDispatchJob] dead-letter write failed: #{e.message}",
    )
  end
end
