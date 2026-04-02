# frozen_string_literal: true

require 'test_helper'

class Agents::ManagerDigestWorkflowJobTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'growth_digest',
      trigger_event: 'manager_digest.scheduled',
      status: 'pending',
      context_snapshot: { 'restaurant_id' => @restaurant.id },
    )
  end

  test 'skips when run not found' do
    assert_nothing_raised do
      Agents::ManagerDigestWorkflowJob.new.perform(999_999)
    end
  end

  test 'skips completed runs' do
    @run.update!(status: 'completed')
    called = false
    Agents::Workflows::ManagerDigestWorkflow.stub(:call, ->(_r) { called = true }) do
      Agents::ManagerDigestWorkflowJob.new.perform(@run.id)
    end
    assert_not called, 'Workflow should not be called for completed runs'
  end

  test 'skips cancelled runs' do
    @run.update!(status: 'cancelled')
    called = false
    Agents::Workflows::ManagerDigestWorkflow.stub(:call, ->(_r) { called = true }) do
      Agents::ManagerDigestWorkflowJob.new.perform(@run.id)
    end
    assert_not called, 'Workflow should not be called for cancelled runs'
  end

  test 'skips when agent_growth_digest flag is disabled' do
    Flipper.disable(:agent_growth_digest, @restaurant)
    called = false
    Agents::Workflows::ManagerDigestWorkflow.stub(:call, ->(_r) { called = true }) do
      Agents::ManagerDigestWorkflowJob.new.perform(@run.id)
    end
    assert_not called, 'Workflow should not be called when flag is disabled'
  end

  test 'delegates to ManagerDigestWorkflow when flag enabled' do
    Flipper.enable(:agent_growth_digest, @restaurant)
    called = false
    Agents::Workflows::ManagerDigestWorkflow.stub(:call, ->(_r) { called = true }) do
      Agents::ManagerDigestWorkflowJob.new.perform(@run.id)
    end
    assert called
  ensure
    Flipper.disable(:agent_growth_digest, @restaurant)
  end
end
