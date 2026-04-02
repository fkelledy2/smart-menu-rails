# frozen_string_literal: true

require 'test_helper'

class Agents::ExpireAgentApprovalsJobTest < ActiveSupport::TestCase
  test 'marks pending expired approvals as expired' do
    # Create a pending approval with past expires_at
    approval = AgentApproval.create!(
      agent_workflow_run: agent_workflow_runs(:awaiting_approval_run),
      action_type: 'propose_menu_patch',
      risk_level: 'medium',
      proposed_payload: {},
      status: 'pending',
      expires_at: 1.hour.ago,
    )

    assert_equal 'pending', approval.status

    Agents::ExpireAgentApprovalsJob.new.perform

    assert_equal 'expired', approval.reload.status
  end

  test 'does not mark non-pending approvals' do
    approved = agent_approvals(:approved_approval)
    original_status = approved.status

    Agents::ExpireAgentApprovalsJob.new.perform

    assert_equal original_status, approved.reload.status
  end

  test 'does not mark pending approvals that have not yet expired' do
    approval = AgentApproval.create!(
      agent_workflow_run: agent_workflow_runs(:awaiting_approval_run),
      action_type: 'propose_menu_patch',
      risk_level: 'low',
      proposed_payload: {},
      status: 'pending',
      expires_at: 48.hours.from_now,
    )

    Agents::ExpireAgentApprovalsJob.new.perform

    assert_equal 'pending', approval.reload.status
  end
end
