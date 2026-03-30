# frozen_string_literal: true

require 'test_helper'

class MenuitemCostPolicyTest < ActiveSupport::TestCase
  def setup
    @owner       = users(:one) # owns restaurants(:one) → menus(:one) → menuitems(:one)
    @other_user  = users(:two)
    @super_admin = users(:super_admin)

    @menuitem = menuitems(:one)

    @cost = MenuitemCost.create!(
      menuitem: @menuitem,
      ingredient_cost: 2.0,
      labor_cost: 1.0,
      packaging_cost: 0.5,
      overhead_cost: 0.5,
      effective_date: Time.zone.today,
      cost_source: 'manual',
      is_active: true,
      created_by_user: @owner,
    )
  end

  # ---------------------------------------------------------------------------
  # create? / new?
  # ---------------------------------------------------------------------------

  test 'create? allowed for restaurant owner' do
    policy = MenuitemCostPolicy.new(@owner, @cost)
    assert policy.create?
  end

  test 'create? denied for non-owner' do
    policy = MenuitemCostPolicy.new(@other_user, @cost)
    assert_not policy.create?
  end

  test 'create? allowed for super_admin' do
    policy = MenuitemCostPolicy.new(@super_admin, @cost)
    assert policy.create?
  end

  test 'new? delegates to create?' do
    policy = MenuitemCostPolicy.new(@owner, @cost)
    assert_equal policy.create?, policy.new?
  end

  # ---------------------------------------------------------------------------
  # update? / edit?
  # ---------------------------------------------------------------------------

  test 'update? allowed for restaurant owner' do
    policy = MenuitemCostPolicy.new(@owner, @cost)
    assert policy.update?
  end

  test 'update? denied for non-owner' do
    policy = MenuitemCostPolicy.new(@other_user, @cost)
    assert_not policy.update?
  end

  test 'update? allowed for super_admin' do
    policy = MenuitemCostPolicy.new(@super_admin, @cost)
    assert policy.update?
  end

  test 'edit? delegates to update?' do
    policy = MenuitemCostPolicy.new(@owner, @cost)
    assert_equal policy.update?, policy.edit?
  end

  # ---------------------------------------------------------------------------
  # destroy?
  # ---------------------------------------------------------------------------

  test 'destroy? allowed for restaurant owner' do
    policy = MenuitemCostPolicy.new(@owner, @cost)
    assert policy.destroy?
  end

  test 'destroy? denied for non-owner' do
    policy = MenuitemCostPolicy.new(@other_user, @cost)
    assert_not policy.destroy?
  end

  # ---------------------------------------------------------------------------
  # owner? guard — record with no menuitem_id returns false
  # ---------------------------------------------------------------------------

  test 'create? denied when cost has no menuitem_id (unsaved record)' do
    blank_cost = MenuitemCost.new
    policy = MenuitemCostPolicy.new(@owner, blank_cost)
    assert_not policy.create?
  end

  # ---------------------------------------------------------------------------
  # Scope
  # ---------------------------------------------------------------------------

  test 'scope returns costs for owner restaurants' do
    scope = MenuitemCostPolicy::Scope.new(@owner, MenuitemCost.all)
    result = scope.resolve
    assert_includes result, @cost
  end

  test 'scope excludes costs for other users restaurants' do
    scope = MenuitemCostPolicy::Scope.new(@other_user, MenuitemCost.all)
    result = scope.resolve
    assert_not_includes result, @cost
  end

  test 'scope returns all for super_admin' do
    scope = MenuitemCostPolicy::Scope.new(@super_admin, MenuitemCost.all)
    result = scope.resolve
    assert_includes result, @cost
  end

  test 'inherits from ApplicationPolicy' do
    assert MenuitemCostPolicy < ApplicationPolicy
  end
end
