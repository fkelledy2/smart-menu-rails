# frozen_string_literal: true

require 'test_helper'

class Admin::Webhooks::CalendlyControllerTest < ActionDispatch::IntegrationTest
  FAKE_SECRET = 'test_calendly_secret_key'
  VALID_BODY = '{"event":"invitee.created","payload":{"event":{"uuid":"wh-test-uuid-001"},"invitee":{"email":"webhook.test@example.com","name":"Webhook Tester"}}}'

  def build_signature_header(body:, secret: FAKE_SECRET, offset_seconds: 0)
    timestamp = (Time.current + offset_seconds.seconds).to_i
    signing_string = "#{timestamp}.#{body}"
    sig = OpenSSL::HMAC.hexdigest('SHA256', secret, signing_string)
    "t=#{timestamp},v1=#{sig}"
  end

  # ---------------------------------------------------------------------------
  # Valid signature — enqueue job and return 200
  # ---------------------------------------------------------------------------

  test 'returns 200 and enqueues job for valid signature' do
    header = build_signature_header(body: VALID_BODY)

    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      assert_enqueued_with(job: Crm::ProcessCalendlyWebhookJob) do
        post admin_webhooks_calendly_path,
             params: VALID_BODY,
             headers: {
               'Content-Type' => 'application/json',
               'Calendly-Webhook-Signature' => header,
             }
      end
    end

    assert_response :ok
    assert_equal 'ok', response.parsed_body['status']
  end

  # ---------------------------------------------------------------------------
  # Invalid / missing signature — return 401
  # ---------------------------------------------------------------------------

  test 'returns 401 when signature header is missing' do
    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      post admin_webhooks_calendly_path,
           params: VALID_BODY,
           headers: { 'Content-Type' => 'application/json' }
    end

    assert_response :unauthorized
  end

  test 'returns 401 when signature is incorrect' do
    header = build_signature_header(body: VALID_BODY, secret: 'wrong_secret')

    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      post admin_webhooks_calendly_path,
           params: VALID_BODY,
           headers: {
             'Content-Type' => 'application/json',
             'Calendly-Webhook-Signature' => header,
           }
    end

    assert_response :unauthorized
  end

  test 'returns 401 when timestamp is too old (replay attack)' do
    header = build_signature_header(body: VALID_BODY, offset_seconds: -400)

    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      post admin_webhooks_calendly_path,
           params: VALID_BODY,
           headers: {
             'Content-Type' => 'application/json',
             'Calendly-Webhook-Signature' => header,
           }
    end

    assert_response :unauthorized
  end

  # ---------------------------------------------------------------------------
  # Malformed JSON body — return 422
  # ---------------------------------------------------------------------------

  test 'returns 422 for unparseable JSON payload' do
    malformed_body = 'not json at all {'
    header = build_signature_header(body: malformed_body)

    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      # Use env 'RAW_POST_DATA' to bypass Rails param parsing for malformed JSON
      post admin_webhooks_calendly_path,
           env: {
             'RAW_POST_DATA' => malformed_body,
             'CONTENT_TYPE' => 'text/plain',
           },
           headers: {
             'Calendly-Webhook-Signature' => header,
           }
    end

    assert_response :unprocessable_entity
  end

  # ---------------------------------------------------------------------------
  # Duplicate event UUID — 200, no double-processing
  # ---------------------------------------------------------------------------

  test 'returns 200 and is idempotent for duplicate event UUID' do
    # demo_booked_lead already has calendly_event_uuid = 'abc-123-existing-uuid'
    body = '{"event":"invitee.created","payload":{"event":{"uuid":"abc-123-existing-uuid"},"invitee":{"email":"kenji@sushinori.com","name":"Kenji Tanaka"}}}'
    header = build_signature_header(body: body)

    Rails.application.credentials.stub(:calendly_webhook_secret, FAKE_SECRET) do
      # First call processed already; second call should be a no-op
      assert_no_difference 'CrmLead.count' do
        post admin_webhooks_calendly_path,
             params: body,
             headers: {
               'Content-Type' => 'application/json',
               'Calendly-Webhook-Signature' => header,
             }
      end
    end

    assert_response :ok
  end
end
