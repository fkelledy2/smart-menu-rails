# frozen_string_literal: true

require 'test_helper'

class Payments::WebhooksControllerTest < ActionDispatch::IntegrationTest
  # ---------------------------------------------------------------------------
  # POST /payments/webhooks/stripe
  #
  # This controller has no Pundit after_action :verify_authorized — it is a
  # public ingest endpoint. CSRF is skipped via skip_before_action.
  # ---------------------------------------------------------------------------

  # Build a minimal Stripe event double that responds to :type, :id, :livemode,
  # and :created.
  def fake_stripe_event(type: 'checkout.session.completed', id: 'evt_test_001')
    obj = Object.new
    obj.define_singleton_method(:type) { type }
    obj.define_singleton_method(:id) { id }
    obj.define_singleton_method(:livemode) { false }
    obj.define_singleton_method(:created) { Time.now.to_i }
    obj
  end

  test 'stripe: returns bad_request when no webhook secret is configured and signature missing' do
    # When build_stripe_event returns nil (no secret + signature mismatch), controller returns 400
    ENV_BACKUP = ENV['STRIPE_WEBHOOK_SECRET']
    ENV.delete('STRIPE_WEBHOOK_SECRET')

    Rails.application.credentials.stub(:dig, ->(*_args) { nil }) do
      post payments_webhooks_stripe_path,
        params: '{"id":"evt_none","type":"test"}',
        headers: { 'Content-Type' => 'application/json' }
    end

    assert_response :bad_request
  ensure
    ENV['STRIPE_WEBHOOK_SECRET'] = ENV_BACKUP if defined?(ENV_BACKUP) && ENV_BACKUP
  end

  test 'stripe: returns ok when event signature validates and job is enqueued' do
    evt = fake_stripe_event
    secret = 'whsec_test_webhook_secret'

    # Set ENV secret so build_stripe_event has a non-blank secret to use
    prev_secret = ENV['STRIPE_WEBHOOK_SECRET']
    ENV['STRIPE_WEBHOOK_SECRET'] = secret

    # Stub Stripe::Webhook.construct_event to return our fake event
    Stripe::Webhook.stub(:construct_event, evt) do
      Payments::WebhookIngestJob.stub(:perform_later, ->(**_kwargs) { OpenStruct.new(job_id: 'jid_test') }) do
        post payments_webhooks_stripe_path,
          params: '{"id":"evt_test_001","type":"checkout.session.completed","created":1234567890}',
          headers: {
            'Content-Type' => 'application/json',
            'HTTP_STRIPE_SIGNATURE' => 't=1234567890,v1=fakesig',
          }
      end
    end

    assert_response :ok
  ensure
    ENV['STRIPE_WEBHOOK_SECRET'] = prev_secret
  end

  test 'stripe: returns ok and falls back to inline ingest when enqueue fails' do
    evt = fake_stripe_event
    secret = 'whsec_test_webhook_secret'

    prev_secret = ENV['STRIPE_WEBHOOK_SECRET']
    ENV['STRIPE_WEBHOOK_SECRET'] = secret

    fake_ingestor = Object.new
    fake_ingestor.define_singleton_method(:ingest!) { |**_kwargs| nil }

    Stripe::Webhook.stub(:construct_event, evt) do
      Payments::WebhookIngestJob.stub(:perform_later, ->(**_kwargs) { raise 'Redis unavailable' }) do
        Payments::Webhooks::StripeIngestor.stub(:new, fake_ingestor) do
          post payments_webhooks_stripe_path,
            params: '{"id":"evt_test_001","type":"checkout.session.completed","created":1234567890}',
            headers: {
              'Content-Type' => 'application/json',
              'HTTP_STRIPE_SIGNATURE' => 't=1234567890,v1=fakesig',
            }
        end
      end
    end

    assert_response :ok
  ensure
    ENV['STRIPE_WEBHOOK_SECRET'] = prev_secret
  end

  test 'stripe: returns bad_request when construct_event raises SignatureVerificationError' do
    prev_secret = ENV['STRIPE_WEBHOOK_SECRET']
    ENV['STRIPE_WEBHOOK_SECRET'] = 'whsec_test'

    Stripe::Webhook.stub(
      :construct_event,
      ->(*_args) { raise Stripe::SignatureVerificationError.new('Invalid signature', 'sig') },
    ) do
      post payments_webhooks_stripe_path,
        params: '{"id":"evt_bad"}',
        headers: {
          'Content-Type' => 'application/json',
          'HTTP_STRIPE_SIGNATURE' => 'invalid_sig',
        }
    end

    assert_response :bad_request
  ensure
    ENV['STRIPE_WEBHOOK_SECRET'] = prev_secret
  end
end
