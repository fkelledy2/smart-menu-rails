# frozen_string_literal: true

require 'test_helper'

class AgentWorkflowRunTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @valid_attrs = {
      restaurant: @restaurant,
      workflow_type: 'menu_import',
      trigger_event: 'menu.import_requested',
      status: 'pending',
      context_snapshot: { 'restaurant_id' => @restaurant.id },
    }
  end

  # --- Associations ---

  test 'belongs to restaurant' do
    run = AgentWorkflowRun.new(@valid_attrs)
    assert_equal @restaurant, run.restaurant
  end

  test 'has many agent_workflow_steps' do
    run = agent_workflow_runs(:completed_run)
    assert_respond_to run, :agent_workflow_steps
    assert_equal 2, run.agent_workflow_steps.count
  end

  test 'has many agent_artifacts' do
    run = agent_workflow_runs(:completed_run)
    assert_respond_to run, :agent_artifacts
    assert_equal 2, run.agent_artifacts.count
  end

  test 'has many agent_approvals' do
    run = agent_workflow_runs(:completed_run)
    assert_respond_to run, :agent_approvals
  end

  # --- Validations ---

  test 'valid with all required attributes' do
    assert AgentWorkflowRun.new(@valid_attrs).valid?
  end

  test 'invalid without workflow_type' do
    run = AgentWorkflowRun.new(@valid_attrs.merge(workflow_type: nil))
    assert_not run.valid?
    assert_includes run.errors[:workflow_type], "can't be blank"
  end

  test 'invalid without trigger_event' do
    run = AgentWorkflowRun.new(@valid_attrs.merge(trigger_event: nil))
    assert_not run.valid?
  end

  test 'invalid with unknown status' do
    run = AgentWorkflowRun.new(@valid_attrs.merge(status: 'bogus'))
    assert_not run.valid?
    assert_includes run.errors[:status], 'is not included in the list'
  end

  test 'all valid statuses are accepted' do
    AgentWorkflowRun::STATUSES.each do |s|
      run = AgentWorkflowRun.new(@valid_attrs.merge(status: s))
      assert run.valid?, "Expected status '#{s}' to be valid, errors: #{run.errors.full_messages}"
    end
  end

  # --- Scopes ---

  test 'for_restaurant filters by restaurant' do
    runs = AgentWorkflowRun.for_restaurant(@restaurant.id)
    assert(runs.all? { |r| r.restaurant_id == @restaurant.id })
  end

  test 'active scope returns pending/running/awaiting_approval' do
    active_statuses = %w[pending running awaiting_approval]
    runs = AgentWorkflowRun.active
    assert(runs.all? { |r| active_statuses.include?(r.status) })
  end

  test 'completed scope returns only completed runs' do
    runs = AgentWorkflowRun.completed
    assert(runs.all? { |r| r.status == 'completed' })
  end

  test 'recent scope orders newest first' do
    runs = AgentWorkflowRun.recent
    created_ats = runs.map(&:created_at)
    assert_equal created_ats, created_ats.sort.reverse
  end

  # --- State predicates ---

  test 'pending? returns true for pending run' do
    assert agent_workflow_runs(:pending_run).pending?
  end

  test 'running? returns true for running run' do
    assert agent_workflow_runs(:running_run).running?
  end

  test 'completed? returns true for completed run' do
    assert agent_workflow_runs(:completed_run).completed?
  end

  test 'failed? returns true for failed run' do
    assert agent_workflow_runs(:failed_run).failed?
  end

  test 'awaiting_approval? returns true for awaiting_approval run' do
    assert agent_workflow_runs(:awaiting_approval_run).awaiting_approval?
  end

  # --- State transitions ---

  test 'mark_running! transitions to running' do
    run = AgentWorkflowRun.create!(@valid_attrs)
    run.mark_running!
    assert_equal 'running', run.reload.status
    assert_not_nil run.started_at
  end

  test 'mark_completed! transitions to completed' do
    run = AgentWorkflowRun.create!(@valid_attrs.merge(status: 'running', started_at: 5.minutes.ago))
    run.mark_completed!
    assert_equal 'completed', run.reload.status
    assert_not_nil run.completed_at
  end

  test 'mark_failed! transitions to failed with error message' do
    run = AgentWorkflowRun.create!(@valid_attrs.merge(status: 'running', started_at: 5.minutes.ago))
    run.mark_failed!('Something went wrong')
    run.reload
    assert_equal 'failed', run.status
    assert_equal 'Something went wrong', run.error_message
  end

  test 'mark_awaiting_approval! transitions to awaiting_approval' do
    run = AgentWorkflowRun.create!(@valid_attrs.merge(status: 'running', started_at: 5.minutes.ago))
    run.mark_awaiting_approval!
    assert_equal 'awaiting_approval', run.reload.status
  end

  # --- resume_from_step_index ---

  test 'resume_from_step_index returns 0 when no completed steps' do
    run = AgentWorkflowRun.create!(@valid_attrs)
    assert_equal 0, run.resume_from_step_index
  end

  test 'resume_from_step_index returns next index after last completed step' do
    run = agent_workflow_runs(:completed_run)
    # completed_run has steps at index 0 and 1 both completed
    assert_equal 2, run.resume_from_step_index
  end
end
