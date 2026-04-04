# frozen_string_literal: true

require 'test_helper'

class Agents::MenuOptimizationWorkflowJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @restaurant = restaurants(:one)
    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'menu_optimization',
      trigger_event: 'menu_optimization.requested',
      status: 'pending',
      context_snapshot: { 'restaurant_id' => @restaurant.id },
    )
  end

  test 'skips when run is not found' do
    assert_nothing_raised do
      Agents::MenuOptimizationWorkflowJob.new.perform(999_999)
    end
  end

  test 'skips when run is completed' do
    @run.update!(status: 'completed', completed_at: Time.current)
    workflow_called = false
    Agents::Workflows::MenuOptimizationWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::MenuOptimizationWorkflowJob.new.perform(@run.id)
    end
    assert_not workflow_called
  end

  test 'skips when run is cancelled' do
    @run.update!(status: 'cancelled')
    workflow_called = false
    Agents::Workflows::MenuOptimizationWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::MenuOptimizationWorkflowJob.new.perform(@run.id)
    end
    assert_not workflow_called
  end

  test 'skips when agent_menu_optimization flag is disabled' do
    Flipper.disable(:agent_menu_optimization, @restaurant)
    workflow_called = false
    Agents::Workflows::MenuOptimizationWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::MenuOptimizationWorkflowJob.new.perform(@run.id)
    end
    assert_not workflow_called
  ensure
    Flipper.disable(:agent_menu_optimization, @restaurant)
  end

  test 'calls MenuOptimizationWorkflow when flag is enabled and run is pending' do
    Flipper.enable(:agent_menu_optimization, @restaurant)
    workflow_called = false
    Agents::Workflows::MenuOptimizationWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::MenuOptimizationWorkflowJob.new.perform(@run.id)
    end
    assert workflow_called
  ensure
    Flipper.disable(:agent_menu_optimization, @restaurant)
  end

  test 'is queued on agent_default queue' do
    assert_equal :agent_default, Agents::MenuOptimizationWorkflowJob.queue_name.to_sym
  end
end
