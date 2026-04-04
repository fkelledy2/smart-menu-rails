# frozen_string_literal: true

require 'test_helper'

class Agents::EmitMenuOptimizationEventsJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @restaurant = restaurants(:one)
    Flipper.enable(:agent_framework, @restaurant)
    Flipper.enable(:agent_menu_optimization, @restaurant)
  end

  def teardown
    Flipper.disable(:agent_framework, @restaurant)
    Flipper.disable(:agent_menu_optimization, @restaurant)
  end

  test 'is queued on agent_low queue' do
    assert_equal :agent_low, Agents::EmitMenuOptimizationEventsJob.queue_name.to_sym
  end

  test 'MIN_ORDER_HISTORY_DAYS constant is set' do
    assert_equal(
      Agents::Workflows::MenuOptimizationWorkflow::MIN_ORDERS_WINDOW,
      Agents::EmitMenuOptimizationEventsJob::MIN_ORDER_HISTORY_DAYS,
    )
  end

  test 'perform completes without error when no eligible restaurants' do
    # With no restaurants having old orders, job should complete cleanly
    Flipper.disable(:agent_menu_optimization, @restaurant)
    Flipper.disable(:agent_framework, @restaurant)

    assert_nothing_raised do
      Agents::EmitMenuOptimizationEventsJob.new.perform
    end
  ensure
    Flipper.disable(:agent_menu_optimization, @restaurant)
    Flipper.disable(:agent_framework, @restaurant)
  end
end
