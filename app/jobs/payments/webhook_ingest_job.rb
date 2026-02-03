class Payments::WebhookIngestJob < ApplicationJob
  queue_as :default

  def perform(provider:, provider_event_id:, provider_event_type:, occurred_at:, payload:)
    Rails.logger.info(
      "[WebhookIngestJob] start provider=#{provider} event_type=#{provider_event_type} event_id=#{provider_event_id} occurred_at=#{occurred_at}",
    )

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

    Rails.logger.info(
      "[WebhookIngestJob] done provider=#{provider} event_type=#{provider_event_type} event_id=#{provider_event_id}",
    )
  end
end
