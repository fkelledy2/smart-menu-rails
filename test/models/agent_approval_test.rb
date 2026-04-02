# frozen_string_literal: true

require 'test_helper'

class AgentApprovalTest < ActiveSupport::TestCase
  def setup
    @run  = agent_workflow_runs(:awaiting_approval_run)
    @user = users(:one)
    @valid_attrs = {
      agent_workflow_run: @run,
      action_type: 'propose_menu_patch',
      risk_level: 'medium',
      proposed_payload: { 'key' => 'value' },
      status: 'pending',
      expires_at: 72.hours.from_now,
    }
  end

  # --- Validations ---

  test 'valid with required attributes' do
    assert AgentApproval.new(@valid_attrs).valid?
  end

  test 'invalid without action_type' do
    approval = AgentApproval.new(@valid_attrs.merge(action_type: nil))
    assert_not approval.valid?
  end

  test 'invalid without expires_at' do
    approval = AgentApproval.new(@valid_attrs.merge(expires_at: nil))
    assert_not approval.valid?
  end

  test 'invalid with unknown status' do
    approval = AgentApproval.new(@valid_attrs.merge(status: 'bogus'))
    assert_not approval.valid?
  end

  test 'invalid with unknown risk_level' do
    approval = AgentApproval.new(@valid_attrs.merge(risk_level: 'critical'))
    assert_not approval.valid?
  end

  # --- Predicates ---

  test 'pending? returns true for pending approval' do
    assert agent_approvals(:pending_approval).pending?
  end

  test 'expired? returns true for expired approval' do
    assert agent_approvals(:expired_approval).expired?
  end

  test 'expired_at_time? returns true when expires_at is in the past' do
    approval = AgentApproval.new(@valid_attrs.merge(expires_at: 1.hour.ago))
    assert approval.expired_at_time?
  end

  test 'expired_at_time? returns false when expires_at is in the future' do
    approval = AgentApproval.new(@valid_attrs)
    assert_not approval.expired_at_time?
  end

  # --- State transitions ---

  test 'approve! sets status and reviewer' do
    approval = AgentApproval.create!(@valid_attrs)
    approval.approve!(@user, notes: 'Looks good')
    approval.reload
    assert_equal 'approved', approval.status
    assert_equal @user, approval.reviewer
    assert_equal 'Looks good', approval.reviewer_notes
    assert_not_nil approval.reviewed_at
  end

  test 'approve! raises when expired' do
    approval = AgentApproval.create!(@valid_attrs.merge(expires_at: 1.hour.ago))
    assert_raises(RuntimeError, /expired/) { approval.approve!(@user) }
  end

  test 'reject! sets status and reviewer' do
    approval = AgentApproval.create!(@valid_attrs)
    approval.reject!(@user, notes: 'Not appropriate')
    approval.reload
    assert_equal 'rejected', approval.status
    assert_equal 'Not appropriate', approval.reviewer_notes
  end

  test 'expire! sets status to expired' do
    approval = AgentApproval.create!(@valid_attrs.merge(expires_at: 1.hour.ago))
    approval.expire!
    assert_equal 'expired', approval.reload.status
  end

  # --- Scopes ---

  test 'pending scope returns only pending approvals' do
    AgentApproval.pending.each { |a| assert_equal 'pending', a.status }
  end

  test 'expired_but_not_marked scope returns pending records with past expires_at' do
    expired = AgentApproval.expired_but_not_marked
    expired.each do |a|
      assert_equal 'pending', a.status
      assert a.expires_at <= Time.current
    end
  end
end
