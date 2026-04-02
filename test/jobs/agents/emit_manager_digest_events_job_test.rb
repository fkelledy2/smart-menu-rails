# frozen_string_literal: true

require 'test_helper'

class Agents::EmitManagerDigestEventsJobTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    # Disable both flags by default — tests explicitly enable as needed
    Flipper.disable(:agent_framework, @restaurant)
    Flipper.disable(:agent_growth_digest, @restaurant)
  end

  teardown do
    Flipper.disable(:agent_framework, @restaurant)
    Flipper.disable(:agent_growth_digest, @restaurant)
  end

  test 'does not emit events when no restaurants have sufficient orders' do
    # Ensure no orders exist within the window for restaurant one
    assert_no_difference 'AgentDomainEvent.count' do
      Agents::EmitManagerDigestEventsJob.new.perform
    end
  end

  test 'does not emit event when flags are disabled' do
    # Create orders to meet threshold but leave flags disabled
    create_recent_orders(5)

    assert_no_difference 'AgentDomainEvent.count' do
      Agents::EmitManagerDigestEventsJob.new.perform
    end
  end

  test 'emits event when both flags enabled and sufficient orders exist' do
    Flipper.enable(:agent_framework, @restaurant)
    Flipper.enable(:agent_growth_digest, @restaurant)
    create_recent_orders(5)

    assert_difference 'AgentDomainEvent.count', 1 do
      Agents::EmitManagerDigestEventsJob.new.perform
    end

    event = AgentDomainEvent.last
    assert_equal 'manager_digest.scheduled', event.event_type
    assert_equal @restaurant.id, event.payload['restaurant_id']
  end

  test 'idempotent: second run in same week does not create duplicate event' do
    Flipper.enable(:agent_framework, @restaurant)
    Flipper.enable(:agent_growth_digest, @restaurant)
    create_recent_orders(5)

    assert_difference 'AgentDomainEvent.count', 1 do
      Agents::EmitManagerDigestEventsJob.new.perform
      Agents::EmitManagerDigestEventsJob.new.perform
    end
  end

  test 'does not emit event when agent_framework flag disabled' do
    Flipper.enable(:agent_growth_digest, @restaurant)
    create_recent_orders(5)

    assert_no_difference 'AgentDomainEvent.count' do
      Agents::EmitManagerDigestEventsJob.new.perform
    end
  end

  private

  def create_recent_orders(count)
    menu = @restaurant.menus.first
    return unless menu

    tablesetting = @restaurant.tablesettings.first
    return unless tablesetting

    count.times do
      Ordr.create!(
        restaurant: @restaurant,
        menu: menu,
        tablesetting: tablesetting,
        status: 'opened',
        ordercapacity: 2,
        created_at: 1.day.ago,
      )
    end
  end
end
