# frozen_string_literal: true

require 'test_helper'

class AgentWorkflowRunPolicyTest < ActiveSupport::TestCase
  def setup
    @owner      = users(:one)       # owns restaurants(:one)
    @other_user = users(:two)       # owns restaurants(:two)
    @super_admin = users(:super_admin)
    @run        = agent_workflow_runs(:pending_run)  # restaurant: one
    @other_run  = agent_workflow_runs(:other_restaurant_run) # restaurant: two
  end

  # --- super_admin ---

  test 'super_admin can index any run' do
    assert AgentWorkflowRunPolicy.new(@super_admin, @run).index?
  end

  test 'super_admin can show any run' do
    assert AgentWorkflowRunPolicy.new(@super_admin, @other_run).show?
  end

  # --- restaurant owner ---

  test 'owner can index their own runs' do
    assert AgentWorkflowRunPolicy.new(@owner, @run).index?
  end

  test 'owner can show their own run' do
    assert AgentWorkflowRunPolicy.new(@owner, @run).show?
  end

  test 'owner cannot show another restaurant run' do
    assert_not AgentWorkflowRunPolicy.new(@owner, @other_run).show?
  end

  # --- other user ---

  test 'other user cannot index restaurant one runs' do
    assert_not AgentWorkflowRunPolicy.new(@other_user, @run).index?
  end

  test 'other user cannot show restaurant one run' do
    assert_not AgentWorkflowRunPolicy.new(@other_user, @run).show?
  end

  # --- Scope ---

  test 'scope returns only runs for the user restaurant' do
    scope = AgentWorkflowRunPolicy::Scope.new(@owner, AgentWorkflowRun.all).resolve
    scope.each { |r| assert_equal @owner.id, r.restaurant.user_id }
  end

  test 'super_admin scope returns all runs' do
    scope = AgentWorkflowRunPolicy::Scope.new(@super_admin, AgentWorkflowRun.all).resolve
    assert scope.count >= AgentWorkflowRun.count
  end
end
