# frozen_string_literal: true

module Crm
  # Processes a verified Calendly webhook payload asynchronously.
  # Enqueued by Admin::Webhooks::CalendlyController after signature verification.
  # Idempotent via calendly_event_uuid — safe to retry on failure.
  class ProcessCalendlyWebhookJob < ApplicationJob
    queue_as :crm

    sidekiq_options retry: 25

    def perform(payload)
      Crm::CalendlyEventHandler.call(payload: payload)
    end
  end
end
