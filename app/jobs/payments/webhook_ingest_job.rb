class Payments::WebhookIngestJob < ApplicationJob
  queue_as :default

  def perform(provider:, provider_event_id:, provider_event_type:, occurred_at:, payload:)
    case provider.to_s
    when 'stripe'
      Payments::Webhooks::StripeIngestor.new.ingest!(
        provider_event_id: provider_event_id,
        provider_event_type: provider_event_type,
        occurred_at: occurred_at,
        payload: payload,
      )
    else
      raise ArgumentError, "Unsupported provider: #{provider}"
    end
  end
end
