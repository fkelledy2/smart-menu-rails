# frozen_string_literal: true

require 'test_helper'

class Agents::ServiceOperationsWorkflowJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @restaurant = restaurants(:one)
    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'service_operations',
      trigger_event: 'kitchen.queue_check',
      status: 'pending',
      context_snapshot: { 'restaurant_id' => @restaurant.id },
    )
    Flipper.enable(:agent_service_operations, @restaurant)
  end

  def teardown
    Flipper.disable(:agent_service_operations, @restaurant)
  end

  test 'skips when run is not found' do
    assert_nothing_raised do
      Agents::ServiceOperationsWorkflowJob.new.perform(999_999)
    end
  end

  test 'skips when run is completed' do
    @run.update!(status: 'completed', completed_at: Time.current)
    workflow_called = false
    Agents::Workflows::ServiceOperationsWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::ServiceOperationsWorkflowJob.new.perform(@run.id)
    end
    assert_not workflow_called
  end

  test 'skips when run is cancelled' do
    @run.update!(status: 'cancelled')
    workflow_called = false
    Agents::Workflows::ServiceOperationsWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::ServiceOperationsWorkflowJob.new.perform(@run.id)
    end
    assert_not workflow_called
  end

  test 'skips when agent_service_operations flag is disabled' do
    Flipper.disable(:agent_service_operations, @restaurant)
    workflow_called = false
    Agents::Workflows::ServiceOperationsWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::ServiceOperationsWorkflowJob.new.perform(@run.id)
    end
    assert_not workflow_called
  end

  test 'calls ServiceOperationsWorkflow when flag is enabled and run is pending' do
    workflow_called = false
    Agents::Workflows::ServiceOperationsWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::ServiceOperationsWorkflowJob.new.perform(@run.id)
    end
    assert workflow_called
  end

  test 'is queued on agent_realtime queue' do
    assert_equal :agent_realtime, Agents::ServiceOperationsWorkflowJob.queue_name.to_sym
  end
end
