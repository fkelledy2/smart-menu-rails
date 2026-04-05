# frozen_string_literal: true

require 'test_helper'

module Agents
  class DetectAbandonedPaymentsJobTest < ActiveJob::TestCase
    def setup
      @restaurant = restaurants(:one)
    end

    test 'emits payment.abandoned event for billrequested order over threshold' do
      ordr = Ordr.create!(
        restaurant: @restaurant,
        menu: menus(:one),
        tablesetting: tablesettings(:one),
        status: Ordr.statuses[:billrequested],
        updated_at: (Agents::DetectAbandonedPaymentsJob::ABANDONED_PAYMENT_THRESHOLD_MINUTES + 5).minutes.ago,
      )

      assert_difference -> { AgentDomainEvent.where(event_type: 'payment.abandoned').count }, 1 do
        Agents::DetectAbandonedPaymentsJob.new.perform
      end

      event = AgentDomainEvent.where(event_type: 'payment.abandoned').order(created_at: :desc).first
      assert_equal ordr.id, event.payload['ordr_id']
      assert_equal 'payment.abandoned', event.payload['signal_type']
    end

    test 'does not emit event for recent billrequested order' do
      Ordr.create!(
        restaurant: @restaurant,
        menu: menus(:one),
        tablesetting: tablesettings(:one),
        status: Ordr.statuses[:billrequested],
        updated_at: 5.minutes.ago,
      )

      assert_no_difference -> { AgentDomainEvent.where(event_type: 'payment.abandoned').count } do
        Agents::DetectAbandonedPaymentsJob.new.perform
      end
    end

    test 'does not emit event if already emitted within idempotency window' do
      ordr = Ordr.create!(
        restaurant: @restaurant,
        menu: menus(:one),
        tablesetting: tablesettings(:one),
        status: Ordr.statuses[:billrequested],
        updated_at: (Agents::DetectAbandonedPaymentsJob::ABANDONED_PAYMENT_THRESHOLD_MINUTES + 5).minutes.ago,
      )

      # Pre-seed an existing event within the idempotency window
      AgentDomainEvent.publish!(
        event_type: 'payment.abandoned',
        payload: { 'ordr_id' => ordr.id, 'restaurant_id' => @restaurant.id },
        idempotency_key: "payment.abandoned:#{ordr.id}:preseeded",
      )

      assert_no_difference -> { AgentDomainEvent.where(event_type: 'payment.abandoned').count } do
        Agents::DetectAbandonedPaymentsJob.new.perform
      end
    end

    test 'emits payment.abandoned event for old active-status order with no payment' do
      ordr = Ordr.create!(
        restaurant: @restaurant,
        menu: menus(:one),
        tablesetting: tablesettings(:one),
        status: Ordr.statuses[:ordered],
        paymentstatus: 0,
        updated_at: (Agents::DetectAbandonedPaymentsJob::ABANDONED_PAYMENT_THRESHOLD_MINUTES + 5).minutes.ago,
      )

      assert_difference -> { AgentDomainEvent.where(event_type: 'payment.abandoned').count }, 1 do
        Agents::DetectAbandonedPaymentsJob.new.perform
      end
    end

    test 'queued on agent_default queue' do
      assert_equal :agent_default, Agents::DetectAbandonedPaymentsJob.queue_name.to_sym
    end
  end
end
