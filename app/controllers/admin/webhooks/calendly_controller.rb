# frozen_string_literal: true

module Admin
  module Webhooks
    # Inbound Calendly webhook handler.
    # Authentication: HMAC-SHA256 signature verification (not admin session).
    # This controller is intentionally exempt from the admin session before_action.
    class CalendlyController < ApplicationController
      # Protect from forgery is disabled — webhooks use HMAC signature auth instead.
      protect_from_forgery with: :null_session

      def create
        raw_body = request.raw_post

        unless verify_signature(raw_body)
          render json: { error: 'Unauthorized' }, status: :unauthorized
          return
        end

        payload = parse_payload(raw_body)
        unless payload
          render json: { error: 'Invalid JSON payload' }, status: :unprocessable_content
          return
        end

        ::Crm::ProcessCalendlyWebhookJob.perform_later(payload)

        render json: { status: 'ok' }, status: :ok
      end

      private

      def verify_signature(raw_body)
        ::Crm::CalendlyWebhookVerifier.verify!(
          request_headers: request.headers,
          raw_body: raw_body,
        )
        true
      rescue ::Crm::CalendlyWebhookVerifier::WebhookVerificationError => e
        Rails.logger.warn("[Calendly Webhook] Verification failed: #{e.message}")
        false
      end

      def parse_payload(raw_body)
        JSON.parse(raw_body)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
