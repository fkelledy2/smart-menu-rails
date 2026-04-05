# frozen_string_literal: true

require 'test_helper'

class ProfitMarginPolicyPolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin  = users(:super_admin)
    @plain_admin  = users(:admin)
    @regular_user = users(:one)
    @policy       = profit_margin_policies(:default)
  end

  test 'super admin can index' do
    assert ProfitMarginPolicyPolicy.new(@super_admin, ProfitMarginPolicy).index?
  end

  test 'super admin can create' do
    assert ProfitMarginPolicyPolicy.new(@super_admin, ProfitMarginPolicy).create?
  end

  test 'super admin can update' do
    assert ProfitMarginPolicyPolicy.new(@super_admin, @policy).update?
  end

  test 'super admin can destroy' do
    assert ProfitMarginPolicyPolicy.new(@super_admin, @policy).destroy?
  end

  test 'plain admin cannot index' do
    assert_not ProfitMarginPolicyPolicy.new(@plain_admin, ProfitMarginPolicy).index?
  end

  test 'regular user cannot create' do
    assert_not ProfitMarginPolicyPolicy.new(@regular_user, ProfitMarginPolicy).create?
  end

  test 'super admin scope returns all policies' do
    scope = ProfitMarginPolicyPolicy::Scope.new(@super_admin, ProfitMarginPolicy).resolve
    assert_includes scope, @policy
  end

  test 'non-super-admin scope returns none' do
    scope = ProfitMarginPolicyPolicy::Scope.new(@plain_admin, ProfitMarginPolicy).resolve
    assert scope.none?
  end
end
