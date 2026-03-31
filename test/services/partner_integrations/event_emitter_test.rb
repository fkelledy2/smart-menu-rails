# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrations::EventEmitterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  def setup
    @restaurant = restaurants(:one)
    @restaurant.update!(enabled_integrations: [])
    @event = PartnerIntegrations::CanonicalEvent.new(
      event_type: 'order.payment.succeeded',
      restaurant_id: @restaurant.id,
      occurred_at: Time.zone.now,
      payload: { provider: 'stripe' },
      idempotency_key: 'test-key',
    )
  end

  test 'does not enqueue job when Flipper flag is disabled' do
    Flipper.disable(:partner_integrations)
    @restaurant.update!(enabled_integrations: ['null'])

    assert_no_enqueued_jobs do
      PartnerIntegrations::EventEmitter.emit(restaurant: @restaurant, event: @event)
    end
  ensure
    Flipper.disable(:partner_integrations)
  end

  test 'does not enqueue job when no integrations enabled' do
    Flipper.enable(:partner_integrations, @restaurant)
    @restaurant.update!(enabled_integrations: [])

    assert_no_enqueued_jobs do
      PartnerIntegrations::EventEmitter.emit(restaurant: @restaurant, event: @event)
    end
  ensure
    Flipper.disable(:partner_integrations)
  end

  test 'enqueues PartnerIntegrationDispatchJob for each enabled adapter' do
    Flipper.enable(:partner_integrations, @restaurant)
    @restaurant.update!(enabled_integrations: ['null'])

    assert_enqueued_with(job: PartnerIntegrationDispatchJob) do
      PartnerIntegrations::EventEmitter.emit(restaurant: @restaurant, event: @event)
    end
  ensure
    Flipper.disable(:partner_integrations)
  end

  test 'skips unknown adapter types silently' do
    Flipper.enable(:partner_integrations, @restaurant)
    @restaurant.update!(enabled_integrations: ['unknown_adapter'])

    assert_no_enqueued_jobs do
      PartnerIntegrations::EventEmitter.emit(restaurant: @restaurant, event: @event)
    end
  ensure
    Flipper.disable(:partner_integrations)
  end
end
