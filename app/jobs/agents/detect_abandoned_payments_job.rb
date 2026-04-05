# frozen_string_literal: true

module Agents
  # Agents::DetectAbandonedPaymentsJob runs every 10 minutes and emits
  # `payment.abandoned` domain events for orders that have been in a
  # bill-requested or active state with no payment for too long.
  #
  # Idempotency: skips if a `payment.abandoned` event already exists in
  # AgentDomainEvent for the same ordr_id within the past 60 minutes.
  #
  # Abandoned threshold: configurable via ABANDONED_PAYMENT_THRESHOLD_MINUTES
  # (default: 30 minutes). An order is considered abandoned when:
  #   - status: billrequested AND last updated > threshold minutes ago
  #   - OR status in (ordered, preparing, ready, delivered) with no bill requested
  #     AND created_at > threshold minutes ago (table left without paying)
  class DetectAbandonedPaymentsJob < ApplicationJob
    queue_as :agent_default

    ABANDONED_PAYMENT_THRESHOLD_MINUTES = 30
    IDEMPOTENCY_WINDOW_MINUTES          = 60

    def perform
      detect_billrequested_abandoned
      detect_active_order_abandoned
    end

    private

    # Detect orders that requested the bill but have not been paid
    def detect_billrequested_abandoned
      threshold = ABANDONED_PAYMENT_THRESHOLD_MINUTES.minutes.ago

      Ordr
        .where(status: Ordr.statuses[:billrequested])
        .where(updated_at: ..threshold)
        .find_each do |ordr|
          emit_if_not_duplicate(ordr)
        end
    end

    # Detect orders with active items but no bill request and no activity
    # (table may have left without paying or ordering)
    def detect_active_order_abandoned
      threshold = ABANDONED_PAYMENT_THRESHOLD_MINUTES.minutes.ago
      active_statuses = %w[ordered preparing ready delivered].map { |s| Ordr.statuses[s] }

      Ordr
        .where(status: active_statuses)
        .where(updated_at: ..threshold)
        .where(paymentstatus: 0) # paymentstatus default: 0 = unpaid
        .find_each do |ordr|
          emit_if_not_duplicate(ordr)
        end
    end

    def emit_if_not_duplicate(ordr)
      # Check if a payment.abandoned event was already emitted for this order
      # within the past IDEMPOTENCY_WINDOW_MINUTES
      window = IDEMPOTENCY_WINDOW_MINUTES.minutes.ago
      already_emitted = AgentDomainEvent
        .where(event_type: 'payment.abandoned')
        .where(created_at: window..)
        .exists?(['payload @> ?', { ordr_id: ordr.id }.to_json])

      return if already_emitted

      AgentDomainEvent.publish!(
        event_type: 'payment.abandoned',
        source: ordr,
        payload: {
          'restaurant_id' => ordr.restaurant_id,
          'ordr_id' => ordr.id,
          'signal_type' => 'payment.abandoned',
          'ordr_status' => ordr.status.to_s,
          'gross' => ordr.gross,
          'elapsed_minutes' => ((Time.current - ordr.updated_at) / 60).round,
          'occurred_at' => Time.current.iso8601,
        },
        idempotency_key: "payment.abandoned:#{ordr.id}:#{Time.current.strftime('%Y%m%d%H%M')}",
      )

      Rails.logger.info("[DetectAbandonedPaymentsJob] Emitted payment.abandoned for ordr #{ordr.id}")
    rescue StandardError => e
      Rails.logger.error("[DetectAbandonedPaymentsJob] Failed for ordr #{ordr.id}: #{e.message}")
    end
  end
end
