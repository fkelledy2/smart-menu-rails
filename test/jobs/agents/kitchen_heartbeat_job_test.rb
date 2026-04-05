# frozen_string_literal: true

require 'test_helper'

class Agents::KitchenHeartbeatJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @restaurant = restaurants(:one)
    Flipper.enable(:agent_framework, @restaurant)
    Flipper.enable(:agent_service_operations, @restaurant)
  end

  def teardown
    Flipper.disable(:agent_framework, @restaurant)
    Flipper.disable(:agent_service_operations, @restaurant)
    AgentDomainEvent.where(event_type: 'kitchen.queue_check').delete_all
  end

  test 'emits kitchen.queue_check event for restaurant with active orders' do
    # Use an existing fixture ordr and set it to an active status
    ordr = ordrs(:one)
    ordr.update_column(:status, Ordr.statuses[:preparing])
    ordr.update_column(:updated_at, 1.minute.ago)

    assert_difference -> { AgentDomainEvent.where(event_type: 'kitchen.queue_check').count }, 1 do
      Agents::KitchenHeartbeatJob.new.perform
    end

    event = AgentDomainEvent.where(event_type: 'kitchen.queue_check').last
    assert_equal @restaurant.id, event.payload['restaurant_id']
  end

  test 'does not emit event when agent_service_operations flag is disabled' do
    Flipper.disable(:agent_service_operations, @restaurant)

    ordr = ordrs(:one)
    ordr.update_column(:status, Ordr.statuses[:preparing])
    ordr.update_column(:updated_at, 1.minute.ago)

    assert_no_difference -> { AgentDomainEvent.where(event_type: 'kitchen.queue_check').count } do
      Agents::KitchenHeartbeatJob.new.perform
    end
  end

  test 'does not emit event when agent_framework flag is disabled' do
    Flipper.disable(:agent_framework, @restaurant)

    ordr = ordrs(:one)
    ordr.update_column(:status, Ordr.statuses[:preparing])
    ordr.update_column(:updated_at, 1.minute.ago)

    assert_no_difference -> { AgentDomainEvent.where(event_type: 'kitchen.queue_check').count } do
      Agents::KitchenHeartbeatJob.new.perform
    end
  end

  test 'does not emit event for restaurant with no active orders' do
    # Set all orders for the restaurant to terminal status
    Ordr.where(restaurant_id: @restaurant.id).update_all(
      status: Ordr.statuses[:paid],
      updated_at: 30.minutes.ago,
    )

    assert_no_difference -> { AgentDomainEvent.where(event_type: 'kitchen.queue_check').count } do
      Agents::KitchenHeartbeatJob.new.perform
    end
  end

  test 'is idempotent — does not create duplicate events within the same minute' do
    ordr = ordrs(:one)
    ordr.update_column(:status, Ordr.statuses[:preparing])
    ordr.update_column(:updated_at, 1.minute.ago)

    Agents::KitchenHeartbeatJob.new.perform
    count_after_first = AgentDomainEvent.where(event_type: 'kitchen.queue_check').count

    Agents::KitchenHeartbeatJob.new.perform
    count_after_second = AgentDomainEvent.where(event_type: 'kitchen.queue_check').count

    assert_equal count_after_first, count_after_second, 'Second call within same minute should not create a duplicate event'
  end

  test 'is queued on agent_realtime queue' do
    assert_equal :agent_realtime, Agents::KitchenHeartbeatJob.queue_name.to_sym
  end
end
