# frozen_string_literal: true

require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @super_admin = users(:super_admin)
  end

  test 'manage_two_factor? allows user to manage own 2FA' do
    policy = UserPolicy.new(@user, @user)
    assert policy.manage_two_factor?
  end

  test 'manage_two_factor? denies user from managing another user 2FA' do
    policy = UserPolicy.new(@user, @other_user)
    assert_not policy.manage_two_factor?
  end

  test 'manage_two_factor? allows super_admin to manage any user 2FA' do
    policy = UserPolicy.new(@super_admin, @other_user)
    assert policy.manage_two_factor?
  end

  test 'manage_two_factor? denies guest (nil user)' do
    policy = UserPolicy.new(nil, @user)
    assert_not policy.manage_two_factor?
  end

  test 'Scope resolves to own user record' do
    scope = UserPolicy::Scope.new(@user, User).resolve
    assert_includes scope, @user
    assert_not_includes scope, @other_user
  end

  test 'Scope resolves to all users for super_admin' do
    scope = UserPolicy::Scope.new(@super_admin, User).resolve
    assert_includes scope, @user
    assert_includes scope, @other_user
  end
end
