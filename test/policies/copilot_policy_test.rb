# frozen_string_literal: true

require 'test_helper'

class CopilotPolicyTest < ActiveSupport::TestCase
  def setup
    @restaurant  = restaurants(:one)
    @owner       = users(:one)
    @manager     = users(:two)       # employee with role: manager of restaurant :one
    @staff_user  = users(:employee_staff)
    @other_user  = users(:two)       # restaurant :two owner, no access to restaurant :one
    @super_admin = users(:super_admin)
  end

  # ---------------------------------------------------------------------------
  # query?
  # ---------------------------------------------------------------------------

  test 'owner can query' do
    assert policy_for(@owner).query?
  end

  test 'manager employee can query' do
    assert policy_for(@manager).query?
  end

  test 'staff employee can query' do
    assert policy_for(@staff_user).query?
  end

  test 'super admin can query' do
    assert policy_for(@super_admin).query?
  end

  test 'unrelated user cannot query' do
    assert_not policy_for(@other_user).query?
  end

  test 'unauthenticated user cannot query' do
    assert_not policy_for(nil).query?
  end

  # ---------------------------------------------------------------------------
  # confirm?
  # ---------------------------------------------------------------------------

  test 'owner can confirm' do
    assert policy_for(@owner).confirm?
  end

  test 'staff employee can confirm' do
    assert policy_for(@staff_user).confirm?
  end

  test 'unrelated user cannot confirm' do
    assert_not policy_for(@other_user).confirm?
  end

  private

  def policy_for(user)
    CopilotPolicy.new(user, @restaurant)
  end
end
