# frozen_string_literal: true

require 'test_helper'

class ExternalServiceMonthlyCostPolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin  = users(:super_admin)
    @plain_admin  = users(:admin)
    @regular_user = users(:one)
    @cost         = external_service_monthly_costs(:openai_march)
  end

  test 'super admin can index' do
    assert ExternalServiceMonthlyCostPolicy.new(@super_admin, ExternalServiceMonthlyCost).index?
  end

  test 'super admin can create' do
    assert ExternalServiceMonthlyCostPolicy.new(@super_admin, ExternalServiceMonthlyCost).create?
  end

  test 'super admin can update' do
    assert ExternalServiceMonthlyCostPolicy.new(@super_admin, @cost).update?
  end

  test 'super admin can destroy' do
    assert ExternalServiceMonthlyCostPolicy.new(@super_admin, @cost).destroy?
  end

  test 'plain admin cannot index' do
    assert_not ExternalServiceMonthlyCostPolicy.new(@plain_admin, ExternalServiceMonthlyCost).index?
  end

  test 'regular user cannot index' do
    assert_not ExternalServiceMonthlyCostPolicy.new(@regular_user, ExternalServiceMonthlyCost).index?
  end

  test 'super admin scope returns all costs' do
    scope = ExternalServiceMonthlyCostPolicy::Scope.new(@super_admin, ExternalServiceMonthlyCost).resolve
    assert_includes scope, @cost
  end

  test 'non-super-admin scope returns none' do
    scope = ExternalServiceMonthlyCostPolicy::Scope.new(@plain_admin, ExternalServiceMonthlyCost).resolve
    assert scope.none?
  end
end
