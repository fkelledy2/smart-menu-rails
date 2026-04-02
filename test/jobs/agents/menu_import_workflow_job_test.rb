# frozen_string_literal: true

require 'test_helper'

class Agents::MenuImportWorkflowJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @restaurant = restaurants(:one)
    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'menu_import',
      trigger_event: 'menu.import.requested',
      status: 'pending',
      context_snapshot: { 'restaurant_id' => @restaurant.id, 'ocr_menu_import_id' => 1 },
    )
  end

  test 'skips when run is not found' do
    assert_nothing_raised do
      Agents::MenuImportWorkflowJob.new.perform(999_999)
    end
  end

  test 'skips when run is completed' do
    @run.update!(status: 'completed', completed_at: Time.current)
    workflow_called = false
    Agents::Workflows::MenuImportWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::MenuImportWorkflowJob.new.perform(@run.id)
    end
    assert_not workflow_called
  end

  test 'skips when run is cancelled' do
    @run.update!(status: 'cancelled')
    workflow_called = false
    Agents::Workflows::MenuImportWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::MenuImportWorkflowJob.new.perform(@run.id)
    end
    assert_not workflow_called
  end

  test 'skips when agent_menu_import flag is disabled' do
    Flipper.disable(:agent_menu_import, @restaurant)
    workflow_called = false
    Agents::Workflows::MenuImportWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::MenuImportWorkflowJob.new.perform(@run.id)
    end
    assert_not workflow_called
  ensure
    Flipper.disable(:agent_menu_import, @restaurant)
  end

  test 'calls MenuImportWorkflow when flag is enabled and run is active' do
    Flipper.enable(:agent_menu_import, @restaurant)
    workflow_called = false
    Agents::Workflows::MenuImportWorkflow.stub(:call, ->(_r) { workflow_called = true }) do
      Agents::MenuImportWorkflowJob.new.perform(@run.id)
    end
    assert workflow_called
  ensure
    Flipper.disable(:agent_menu_import, @restaurant)
  end

  test 'is queued on agent_high queue' do
    assert_equal :agent_high, Agents::MenuImportWorkflowJob.queue_name.to_sym
  end
end
