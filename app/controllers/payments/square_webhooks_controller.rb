# frozen_string_literal: true

class Payments::SquareWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  # POST /webhooks/square
  def receive
    payload = request.raw_post
    signature = request.headers['x-square-hmacsha256-signature']

    Rails.logger.info("[SquareWebhook] Incoming request signature_present=#{signature.present?}")

    unless verify_signature(payload, signature)
      Rails.logger.warn('[SquareWebhook] Invalid signature — rejecting')
      return head :unauthorized
    end

    # rubocop:disable Lint/NoReturnInBeginEndBlocks
    parsed = begin
      JSON.parse(payload)
    rescue JSON::ParserError => e
      Rails.logger.warn("[SquareWebhook] Invalid JSON: #{e.message}")
      return head :bad_request
    end
    # rubocop:enable Lint/NoReturnInBeginEndBlocks

    event_id = parsed['event_id'].to_s
    event_type = parsed['type'].to_s
    occurred_at = begin
      Time.zone.parse(parsed['created_at'])
    rescue StandardError
      Time.current
    end

    Rails.logger.info("[SquareWebhook] Received event type=#{event_type} id=#{event_id}")

    enqueue_ingest!(
      event_id: event_id,
      event_type: event_type,
      occurred_at: occurred_at,
      payload: parsed,
    )

    head :ok
  end

  private

  def enqueue_ingest!(event_id:, event_type:, occurred_at:, payload:)
    job = Payments::WebhookIngestJob.perform_later(
      provider: 'square',
      provider_event_id: event_id,
      provider_event_type: event_type,
      occurred_at: occurred_at,
      payload: payload,
    )

    Rails.logger.info("[SquareWebhook] Enqueued ingest job event_id=#{event_id} job_id=#{job.job_id}")
  rescue StandardError => e
    Rails.logger.warn("[SquareWebhook] Failed to enqueue job (falling back to inline): #{e.class}: #{e.message}")
    begin
      Payments::Webhooks::SquareIngestor.new.ingest!(
        provider_event_id: event_id,
        provider_event_type: event_type,
        occurred_at: occurred_at,
        payload: payload,
      )
    rescue StandardError => ee
      Rails.logger.error("[SquareWebhook] Inline ingest failed: #{ee.class}: #{ee.message}")
    end
  end

  def verify_signature(payload, signature)
    key = SquareConfig.webhook_signature_key
    if key.blank?
      Rails.logger.error('[SquareWebhook] SQUARE_WEBHOOK_SIGNATURE_KEY not configured')
      return false
    end

    return false if signature.blank?

    # Square signature = Base64(HMAC-SHA256(signature_key, notification_url + body))
    # Must use the registered webhook URL without query parameters — Square does not
    # include query params when computing the signature.
    notification_url = request.base_url + request.path
    string_to_sign = notification_url + payload
    expected = Base64.strict_encode64(
      OpenSSL::HMAC.digest('sha256', key, string_to_sign),
    )

    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end
end
