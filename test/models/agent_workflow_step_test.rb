# frozen_string_literal: true

require 'test_helper'

class AgentWorkflowStepTest < ActiveSupport::TestCase
  def setup
    @run = agent_workflow_runs(:pending_run)
    @valid_attrs = {
      agent_workflow_run: @run,
      step_name: 'fetch_context',
      step_index: 99, # Use a high index to avoid conflict with fixtures at 0
      status: 'pending',
    }
  end

  # --- Associations ---

  test 'belongs to agent_workflow_run' do
    step = AgentWorkflowStep.new(@valid_attrs)
    assert_equal @run, step.agent_workflow_run
  end

  test 'has many tool_invocation_logs' do
    step = agent_workflow_steps(:step_one_completed)
    assert_respond_to step, :tool_invocation_logs
    assert_equal 1, step.tool_invocation_logs.count
  end

  # --- Validations ---

  test 'valid with required attributes' do
    assert AgentWorkflowStep.new(@valid_attrs).valid?
  end

  test 'invalid without step_name' do
    step = AgentWorkflowStep.new(@valid_attrs.merge(step_name: nil))
    assert_not step.valid?
  end

  test 'invalid without step_index' do
    step = AgentWorkflowStep.new(@valid_attrs.merge(step_index: nil))
    assert_not step.valid?
  end

  test 'invalid with negative step_index' do
    step = AgentWorkflowStep.new(@valid_attrs.merge(step_index: -1))
    assert_not step.valid?
  end

  test 'invalid with unknown status' do
    step = AgentWorkflowStep.new(@valid_attrs.merge(status: 'bogus'))
    assert_not step.valid?
  end

  # --- Predicates ---

  test 'retriable? returns true when failed and under MAX_RETRIES' do
    step = AgentWorkflowStep.new(@valid_attrs.merge(status: 'failed', retry_count: 1))
    assert step.retriable?
  end

  test 'retriable? returns false when retry_count equals MAX_RETRIES' do
    step = AgentWorkflowStep.new(@valid_attrs.merge(
                                   status: 'failed',
                                   retry_count: AgentWorkflowStep::MAX_RETRIES,
                                 ))
    assert_not step.retriable?
  end

  test 'retriable? returns false when completed' do
    step = AgentWorkflowStep.new(@valid_attrs.merge(status: 'completed', retry_count: 0))
    assert_not step.retriable?
  end

  # --- State transitions ---

  test 'mark_running! sets status and started_at' do
    step = AgentWorkflowStep.create!(@valid_attrs)
    step.mark_running!
    assert_equal 'running', step.reload.status
    assert_not_nil step.started_at
  end

  test 'mark_completed! sets status, output_snapshot, and completed_at' do
    step = AgentWorkflowStep.create!(@valid_attrs.merge(status: 'running', started_at: 5.seconds.ago))
    output = { 'result' => 'done' }
    step.mark_completed!(output)
    step.reload
    assert_equal 'completed', step.status
    assert_equal output, step.output_snapshot
    assert_not_nil step.completed_at
  end

  test 'mark_failed! increments retry_count' do
    step = AgentWorkflowStep.create!(@valid_attrs.merge(status: 'running', started_at: 5.seconds.ago, retry_count: 1))
    step.mark_failed!(StandardError.new('oops'))
    step.reload
    assert_equal 'failed', step.status
    assert_equal 2, step.retry_count
    assert_equal 'oops', step.last_error
  end

  test 'mark_skipped! sets status to skipped' do
    step = AgentWorkflowStep.create!(@valid_attrs)
    step.mark_skipped!
    assert_equal 'skipped', step.reload.status
  end

  # --- Scopes ---

  test 'ordered scope returns steps in step_index order' do
    steps = agent_workflow_runs(:completed_run).agent_workflow_steps.ordered
    indices = steps.map(&:step_index)
    assert_equal indices, indices.sort
  end
end
