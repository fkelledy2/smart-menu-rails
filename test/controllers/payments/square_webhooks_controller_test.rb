# frozen_string_literal: true

require 'test_helper'

class Payments::SquareWebhooksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @webhook_key = 'test-square-webhook-key'
    @url = payments_webhooks_square_url
  end

  # --- signature verification ---

  test 'rejects request with missing signature' do
    SquareConfig.stub :webhook_signature_key, @webhook_key do
      post @url, params: '{}', headers: { 'Content-Type' => 'application/json' }
      assert_response :unauthorized
    end
  end

  test 'rejects request with invalid signature' do
    SquareConfig.stub :webhook_signature_key, @webhook_key do
      post @url,
           params: '{"event_id":"evt_1","type":"payment.completed"}',
           headers: {
             'Content-Type' => 'application/json',
             'x-square-hmacsha256-signature' => 'invalid-sig',
           }
      assert_response :unauthorized
    end
  end

  test 'accepts request with valid signature and returns 200' do
    body = { event_id: 'evt_test_1', type: 'payment.completed', created_at: Time.current.iso8601 }.to_json

    SquareConfig.stub :webhook_signature_key, @webhook_key do
      signature = compute_signature(body, @url)

      # Stub the job enqueue so it doesn't actually run
      Payments::WebhookIngestJob.stub :perform_later, OpenStruct.new(job_id: 'fake') do
        post @url,
             params: body,
             headers: {
               'Content-Type' => 'application/json',
               'x-square-hmacsha256-signature' => signature,
             }
        assert_response :ok
      end
    end
  end

  test 'rejects request when webhook key not configured' do
    SquareConfig.stub :webhook_signature_key, nil do
      post @url,
           params: '{"event_id":"evt_1"}',
           headers: {
             'Content-Type' => 'application/json',
             'x-square-hmacsha256-signature' => 'some-sig',
           }
      assert_response :unauthorized
    end
  end

  private

  def compute_signature(body, url)
    string_to_sign = url + body
    Base64.strict_encode64(
      OpenSSL::HMAC.digest('sha256', @webhook_key, string_to_sign),
    )
  end
end
