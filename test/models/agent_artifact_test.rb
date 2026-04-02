# frozen_string_literal: true

require 'test_helper'

class AgentArtifactTest < ActiveSupport::TestCase
  def setup
    @run = agent_workflow_runs(:completed_run)
    @user = users(:one)
    @valid_attrs = {
      agent_workflow_run: @run,
      artifact_type: 'menu_patch',
      content: { 'changes' => [] },
      status: 'draft',
    }
  end

  # --- Associations ---

  test 'belongs to agent_workflow_run' do
    artifact = AgentArtifact.new(@valid_attrs)
    assert_equal @run, artifact.agent_workflow_run
  end

  # --- Validations ---

  test 'valid with required attributes' do
    assert AgentArtifact.new(@valid_attrs).valid?
  end

  test 'invalid without artifact_type' do
    artifact = AgentArtifact.new(@valid_attrs.merge(artifact_type: nil))
    assert_not artifact.valid?
  end

  test 'invalid with unknown status' do
    artifact = AgentArtifact.new(@valid_attrs.merge(status: 'bogus'))
    assert_not artifact.valid?
  end

  # --- State transitions ---

  test 'approve! sets status approved with user and timestamp' do
    artifact = AgentArtifact.create!(@valid_attrs)
    artifact.approve!(@user)
    artifact.reload
    assert_equal 'approved', artifact.status
    assert_equal @user, artifact.approved_by
    assert_not_nil artifact.approved_at
  end

  test 'reject! sets status rejected' do
    artifact = AgentArtifact.create!(@valid_attrs)
    artifact.reject!(@user)
    assert_equal 'rejected', artifact.reload.status
  end

  test 'apply! transitions from approved to applied' do
    artifact = AgentArtifact.create!(@valid_attrs.merge(status: 'approved', approved_by: @user, approved_at: Time.current))
    artifact.apply!
    assert_equal 'applied', artifact.reload.status
  end

  test 'apply! raises when not approved' do
    artifact = AgentArtifact.create!(@valid_attrs)
    assert_raises(RuntimeError, /must be approved/) { artifact.apply! }
  end

  # --- Predicates ---

  test 'draft? returns true for draft artifact' do
    assert agent_artifacts(:draft_artifact).draft?
  end

  test 'approved? returns true for approved artifact' do
    assert agent_artifacts(:approved_artifact).approved?
  end

  # --- Scopes ---

  test 'draft scope returns only draft artifacts' do
    AgentArtifact.draft.each { |a| assert_equal 'draft', a.status }
  end
end
