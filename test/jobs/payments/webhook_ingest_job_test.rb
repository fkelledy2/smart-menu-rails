# frozen_string_literal: true

require 'test_helper'

class Payments::WebhookIngestJobTest < ActiveJob::TestCase
  # WebhookIngestJob dispatches to StripeIngestor or SquareIngestor based on
  # the provider argument, and raises ArgumentError for unknown providers.
  # We stub the ingestors to avoid needing real Stripe/Square payloads.

  OCCURRED_AT = Time.current.freeze

  def stripe_args(overrides = {})
    {
      provider: 'stripe',
      provider_event_id: "evt_#{SecureRandom.hex(8)}",
      provider_event_type: 'payment_intent.succeeded',
      occurred_at: OCCURRED_AT,
      payload: { 'id' => 'evt_test', 'data' => { 'object' => {} } },
    }.merge(overrides)
  end

  def square_args(overrides = {})
    {
      provider: 'square',
      provider_event_id: "sq_#{SecureRandom.hex(8)}",
      provider_event_type: 'payment.completed',
      occurred_at: OCCURRED_AT,
      payload: { 'type' => 'payment.completed', 'data' => {} },
    }.merge(overrides)
  end

  # ---------------------------------------------------------------------------
  # Routing to StripeIngestor
  # ---------------------------------------------------------------------------

  test 'routes stripe events to StripeIngestor#ingest!' do
    called = false

    fake_ingestor = Object.new
    fake_ingestor.define_singleton_method(:ingest!) { |**_kwargs| called = true }

    Payments::Webhooks::StripeIngestor.stub(:new, fake_ingestor) do
      Payments::WebhookIngestJob.perform_now(**stripe_args)
    end

    assert called, 'StripeIngestor#ingest! should have been called'
  end

  test 'passes all keyword args to StripeIngestor unchanged' do
    args = stripe_args
    received = nil

    fake_ingestor = Object.new
    fake_ingestor.define_singleton_method(:ingest!) do |**kwargs|
      received = kwargs
    end

    Payments::Webhooks::StripeIngestor.stub(:new, fake_ingestor) do
      Payments::WebhookIngestJob.perform_now(**args)
    end

    assert_equal args[:provider_event_id], received[:provider_event_id]
    assert_equal args[:provider_event_type], received[:provider_event_type]
    assert_equal args[:payload], received[:payload]
  end

  # ---------------------------------------------------------------------------
  # Routing to SquareIngestor
  # ---------------------------------------------------------------------------

  test 'routes square events to SquareIngestor#ingest!' do
    args = square_args
    received = nil

    fake_ingestor = Object.new
    fake_ingestor.define_singleton_method(:ingest!) do |**kwargs|
      received = kwargs
    end

    Payments::Webhooks::SquareIngestor.stub(:new, fake_ingestor) do
      Payments::WebhookIngestJob.perform_now(**args)
    end

    assert_equal args[:provider_event_id], received[:provider_event_id]
    assert_equal args[:provider_event_type], received[:provider_event_type]
  end

  # ---------------------------------------------------------------------------
  # Unknown provider raises ArgumentError
  # ---------------------------------------------------------------------------

  test 'raises ArgumentError for unsupported provider' do
    assert_raises ArgumentError do
      Payments::WebhookIngestJob.perform_now(
        provider: 'paypal',
        provider_event_id: 'abc123',
        provider_event_type: 'payment.completed',
        occurred_at: OCCURRED_AT,
        payload: {},
      )
    end
  end

  test 'ArgumentError message names the unknown provider' do
    error = assert_raises ArgumentError do
      Payments::WebhookIngestJob.perform_now(
        provider: 'braintree',
        provider_event_id: 'abc123',
        provider_event_type: 'sale.completed',
        occurred_at: OCCURRED_AT,
        payload: {},
      )
    end
    assert_match 'braintree', error.message
  end

  # ---------------------------------------------------------------------------
  # Queue configuration
  # ---------------------------------------------------------------------------

  test 'is enqueued on the default queue' do
    assert_enqueued_with(job: Payments::WebhookIngestJob, queue: 'default') do
      Payments::WebhookIngestJob.perform_later(**stripe_args)
    end
  end
end
