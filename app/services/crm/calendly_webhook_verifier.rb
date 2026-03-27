# frozen_string_literal: true

module Crm
  # Verifies incoming Calendly webhook payloads using HMAC-SHA256.
  # Raises WebhookVerificationError if signature is invalid or missing.
  #
  # Calendly signature format:
  #   Calendly-Webhook-Signature: t=<timestamp>,v1=<hmac_hex>
  #
  # Verification steps per Calendly docs:
  #   1. Extract timestamp (t) and signature (v1) from header
  #   2. Build signing string: "#{timestamp}.#{raw_body}"
  #   3. Compute HMAC-SHA256 of signing string using shared secret
  #   4. Compare computed vs provided signature (constant-time)
  #   5. Optionally verify timestamp is within tolerance (replay protection)
  class CalendlyWebhookVerifier
    SIGNATURE_TOLERANCE_SECONDS = 300 # 5 minutes

    class WebhookVerificationError < StandardError; end

    def self.verify!(request_headers:, raw_body:)
      new(request_headers: request_headers, raw_body: raw_body).verify!
    end

    def initialize(request_headers:, raw_body:)
      @request_headers = request_headers
      @raw_body = raw_body
    end

    def verify!
      header = @request_headers['Calendly-Webhook-Signature'].to_s
      raise WebhookVerificationError, 'Missing Calendly-Webhook-Signature header' if header.blank?

      parts = parse_header(header)
      timestamp = parts['t']
      provided_sig = parts['v1']

      raise WebhookVerificationError, 'Malformed signature header' if timestamp.blank? || provided_sig.blank?

      verify_timestamp!(timestamp)

      signing_string = "#{timestamp}.#{@raw_body}"
      secret = Rails.application.credentials.calendly_webhook_secret.to_s

      if secret.blank?
        raise WebhookVerificationError, 'Calendly webhook secret not configured in credentials'
      end

      expected_sig = OpenSSL::HMAC.hexdigest('SHA256', secret, signing_string)

      unless ActiveSupport::SecurityUtils.secure_compare(expected_sig, provided_sig)
        raise WebhookVerificationError, 'Signature mismatch'
      end

      true
    end

    private

    def parse_header(header)
      header.split(',').each_with_object({}) do |part, h|
        key, value = part.split('=', 2)
        h[key.strip] = value.strip if key && value
      end
    end

    def verify_timestamp!(timestamp)
      event_time = Time.zone.at(timestamp.to_i)
      age = (Time.current - event_time).abs

      if age > SIGNATURE_TOLERANCE_SECONDS
        raise WebhookVerificationError,
              "Webhook timestamp too old (#{age.to_i}s); possible replay attack"
      end
    end
  end
end
