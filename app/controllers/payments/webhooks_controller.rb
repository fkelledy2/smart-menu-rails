class Payments::WebhooksController < ApplicationController
  require 'stripe'

  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.raw_post
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    Rails.logger.info("[StripeWebhook] Incoming request signature_header_present=#{sig_header.present?}")

    evt = build_stripe_event(payload, sig_header)
    return head :bad_request unless evt

    Rails.logger.warn("[StripeWebhook] Received event type=#{evt.type} id=#{evt.id} livemode=#{evt.livemode}")

    enqueue_ingest!(evt, payload)

    head :ok
  end

  private

  def enqueue_ingest!(evt, payload)
    raw = begin
      JSON.parse(payload)
    rescue StandardError
      {}
    end

    occurred_at = begin
      Time.zone.at(evt.created.to_i)
    rescue StandardError
      Time.current
    end

    job = Payments::WebhookIngestJob.perform_later(
      provider: 'stripe',
      provider_event_id: evt.id.to_s,
      provider_event_type: evt.type.to_s,
      occurred_at: occurred_at,
      payload: raw,
    )

    Rails.logger.info("[StripeWebhook] Enqueued ingest job event_id=#{evt.id} job_id=#{job.job_id}")
  rescue StandardError => e
    Rails.logger.warn("[StripeWebhook] Failed to enqueue ingest job (falling back to inline ingest): #{e.class}: #{e.message}")
    begin
      Payments::Webhooks::StripeIngestor.new.ingest!(
        provider_event_id: evt.id.to_s,
        provider_event_type: evt.type.to_s,
        occurred_at: occurred_at,
        payload: raw,
      )
    rescue StandardError => ee
      Rails.logger.error("[StripeWebhook] Inline ingest failed: #{ee.class}: #{ee.message}")
    end
  end

  def build_stripe_event(payload, sig_header)
    env_secret = ENV['STRIPE_WEBHOOK_SECRET'].presence

    credentials_secret = begin
      Rails.application.credentials.dig(:stripe, :webhook_secret) ||
        Rails.application.credentials[:stripe_webhook_secret]
    rescue StandardError
      nil
    end

    secret = if Rails.env.production?
               env_secret || credentials_secret
             else
               credentials_secret.presence || env_secret
             end

    secret_source = if secret.blank?
                      'none'
                    elsif secret == env_secret
                      'env'
                    else
                      'credentials'
                    end

    Rails.logger.info("[StripeWebhook] webhook_secret_source=#{secret_source}")

    if secret.present?
      Stripe::Webhook.construct_event(payload, sig_header, secret)
    else
      Rails.logger.error('[StripeWebhook] STRIPE_WEBHOOK_SECRET not configured; rejecting unsigned event')
      nil
    end
  rescue StandardError => e
    Rails.logger.warn("[StripeWebhook] Invalid payload/signature: #{e.class}: #{e.message}")
    nil
  end
end
