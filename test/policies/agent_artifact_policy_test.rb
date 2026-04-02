# frozen_string_literal: true

require 'test_helper'

class AgentArtifactPolicyTest < ActiveSupport::TestCase
  def setup
    @owner      = users(:one)
    @other_user = users(:two)
    @super_admin = users(:super_admin)
    @artifact   = agent_artifacts(:draft_artifact)  # belongs to completed_run (restaurant: one)
  end

  test 'super_admin can show any artifact' do
    assert AgentArtifactPolicy.new(@super_admin, @artifact).show?
  end

  test 'owner can show their artifact' do
    assert AgentArtifactPolicy.new(@owner, @artifact).show?
  end

  test 'other user cannot show artifact from another restaurant' do
    assert_not AgentArtifactPolicy.new(@other_user, @artifact).show?
  end

  test 'owner can approve artifact' do
    assert AgentArtifactPolicy.new(@owner, @artifact).approve?
  end

  test 'other user cannot approve artifact' do
    assert_not AgentArtifactPolicy.new(@other_user, @artifact).approve?
  end

  test 'reject? delegates to approve?' do
    policy = AgentArtifactPolicy.new(@owner, @artifact)
    assert_equal policy.approve?, policy.reject?
  end
end
