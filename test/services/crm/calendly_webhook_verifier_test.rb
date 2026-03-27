# frozen_string_literal: true

require 'test_helper'

class Crm::CalendlyWebhookVerifierTest < ActiveSupport::TestCase
  FAKE_SECRET = 'test_secret_key_for_calendly'
  RAW_BODY = '{"event":"invitee.created","payload":{"invitee":{"email":"test@example.com"}}}'

  def build_header(body:, secret:, offset_seconds: 0)
    timestamp = (Time.current + offset_seconds.seconds).to_i
    signing_string = "#{timestamp}.#{body}"
    sig = OpenSSL::HMAC.hexdigest('SHA256', secret, signing_string)
    "t=#{timestamp},v1=#{sig}"
  end

  setup do
    Rails.application.credentials.stubs(:calendly_webhook_secret).returns(FAKE_SECRET)
  rescue StandardError
    nil
  end

  test 'passes with valid signature and fresh timestamp' do
    header = build_header(body: RAW_BODY, secret: FAKE_SECRET)

    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      assert Crm::CalendlyWebhookVerifier.verify!(
        request_headers: { 'Calendly-Webhook-Signature' => header },
        raw_body: RAW_BODY,
      )
    end
  end

  test 'raises on missing header' do
    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      assert_raises(Crm::CalendlyWebhookVerifier::WebhookVerificationError) do
        Crm::CalendlyWebhookVerifier.verify!(
          request_headers: {},
          raw_body: RAW_BODY,
        )
      end
    end
  end

  test 'raises on incorrect signature' do
    header = build_header(body: RAW_BODY, secret: 'wrong_secret')
    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      assert_raises(Crm::CalendlyWebhookVerifier::WebhookVerificationError) do
        Crm::CalendlyWebhookVerifier.verify!(
          request_headers: { 'Calendly-Webhook-Signature' => header },
          raw_body: RAW_BODY,
        )
      end
    end
  end

  test 'raises on timestamp too old (replay attack)' do
    header = build_header(body: RAW_BODY, secret: FAKE_SECRET, offset_seconds: -400)
    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      assert_raises(Crm::CalendlyWebhookVerifier::WebhookVerificationError) do
        Crm::CalendlyWebhookVerifier.verify!(
          request_headers: { 'Calendly-Webhook-Signature' => header },
          raw_body: RAW_BODY,
        )
      end
    end
  end

  test 'raises on malformed header' do
    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      assert_raises(Crm::CalendlyWebhookVerifier::WebhookVerificationError) do
        Crm::CalendlyWebhookVerifier.verify!(
          request_headers: { 'Calendly-Webhook-Signature' => 'malformed_no_equals' },
          raw_body: RAW_BODY,
        )
      end
    end
  end
end
