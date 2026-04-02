# frozen_string_literal: true

require 'test_helper'

class Agents::ApprovalRouterTest < ActiveSupport::TestCase
  def setup
    @run = agent_workflow_runs(:running_run)
  end

  test 'creates a pending AgentApproval' do
    assert_difference 'AgentApproval.count', 1 do
      result = Agents::ApprovalRouter.call(
        workflow_run: @run,
        action_type: 'propose_menu_patch',
        risk_level: 'medium',
        proposed_payload: { 'changes' => [] },
      )
      assert result.success?
      assert_equal 'pending', result.approval.status
      assert_equal 'propose_menu_patch', result.approval.action_type
    end
  end

  test 'sets expires_at based on policy expiry hours' do
    # require_approval_patch has expiry_hours: 48
    result = Agents::ApprovalRouter.call(
      workflow_run: @run,
      action_type: 'propose_menu_patch',
      risk_level: 'medium',
      proposed_payload: {},
    )
    expected_expiry = 48.hours.from_now
    assert_in_delta expected_expiry.to_i, result.approval.expires_at.to_i, 5
  end

  test 'sets expires_at to default when no policy found' do
    result = Agents::ApprovalRouter.call(
      workflow_run: @run,
      action_type: 'unknown_action_xyz',
      risk_level: 'low',
      proposed_payload: {},
    )
    expected_expiry = AgentApproval::DEFAULT_EXPIRY_HOURS.hours.from_now
    assert_in_delta expected_expiry.to_i, result.approval.expires_at.to_i, 5
  end

  test 'transitions workflow run to awaiting_approval' do
    Agents::ApprovalRouter.call(
      workflow_run: @run,
      action_type: 'propose_menu_patch',
      risk_level: 'high',
      proposed_payload: {},
    )
    assert_equal 'awaiting_approval', @run.reload.status
  end
end
