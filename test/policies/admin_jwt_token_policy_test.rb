# frozen_string_literal: true

require 'test_helper'

class AdminJwtTokenPolicyTest < ActiveSupport::TestCase
  def setup
    @mellow_admin   = users(:super_admin) # admin@mellow.menu, admin: true
    @plain_admin    = users(:admin)       # admin@gmail.com, admin: true
    @regular_user   = users(:one)
    @token          = admin_jwt_tokens(:active_token)
  end

  # --- mellow.menu admin CAN do everything except destroy ---

  test 'mellow admin can index' do
    assert AdminJwtTokenPolicy.new(@mellow_admin, AdminJwtToken).index?
  end

  test 'mellow admin can show' do
    assert AdminJwtTokenPolicy.new(@mellow_admin, @token).show?
  end

  test 'mellow admin can create' do
    assert AdminJwtTokenPolicy.new(@mellow_admin, AdminJwtToken.new).create?
  end

  test 'mellow admin can revoke' do
    assert AdminJwtTokenPolicy.new(@mellow_admin, @token).revoke?
  end

  test 'mellow admin can send_email' do
    assert AdminJwtTokenPolicy.new(@mellow_admin, @token).send_email?
  end

  test 'mellow admin can download_link' do
    assert AdminJwtTokenPolicy.new(@mellow_admin, @token).download_link?
  end

  test 'mellow admin cannot destroy (always false)' do
    assert_not AdminJwtTokenPolicy.new(@mellow_admin, @token).destroy?
  end

  # --- plain admin (not @mellow.menu) cannot access ---

  test 'plain admin cannot index' do
    assert_not AdminJwtTokenPolicy.new(@plain_admin, AdminJwtToken).index?
  end

  test 'plain admin cannot create' do
    assert_not AdminJwtTokenPolicy.new(@plain_admin, AdminJwtToken.new).create?
  end

  test 'plain admin cannot revoke' do
    assert_not AdminJwtTokenPolicy.new(@plain_admin, @token).revoke?
  end

  # --- regular user cannot access ---

  test 'regular user cannot index' do
    assert_not AdminJwtTokenPolicy.new(@regular_user, AdminJwtToken).index?
  end

  test 'regular user cannot create' do
    assert_not AdminJwtTokenPolicy.new(@regular_user, AdminJwtToken.new).create?
  end

  # --- Scope ---

  test 'scope returns all tokens for mellow admin' do
    scope = AdminJwtTokenPolicy::Scope.new(@mellow_admin, AdminJwtToken).resolve
    assert scope.is_a?(ActiveRecord::Relation), 'Expected an ActiveRecord::Relation'
    # Should return all (not none)
    assert_operator scope.count, :>=, 1
  end

  test 'scope returns none for non-mellow admin' do
    scope = AdminJwtTokenPolicy::Scope.new(@plain_admin, AdminJwtToken).resolve
    assert_equal 0, scope.count
  end
end
