require 'test_helper'

# IngredientPolicy: index? always true. create? checks user.present? (always true).
# show?/update?/destroy? check super_admin? OR restaurant ownership OR is_shared?.
class IngredientPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @super_admin = users(:super_admin)

    # Create a restaurant-specific ingredient for ownership tests
    @owned_ingredient = Ingredient.create!(
      name: 'Owner Ingredient',
      restaurant: restaurants(:one),
    )
    @other_ingredient = Ingredient.create!(
      name: 'Other Ingredient',
      restaurant: restaurants(:two),
    )
    # A shared global ingredient (no restaurant, is_shared true)
    @shared_ingredient = Ingredient.create!(
      name: 'Shared Ingredient',
      is_shared: true,
    )
    # An unshared ingredient with no restaurant (orphaned)
    @orphan_ingredient = Ingredient.create!(
      name: 'Orphan Ingredient',
      is_shared: false,
    )
  end

  test 'index is allowed publicly' do
    policy = IngredientPolicy.new(@owner, @owned_ingredient)
    assert policy.index?
  end

  test 'index is allowed for nil user (always public)' do
    policy = IngredientPolicy.new(nil, @shared_ingredient)
    assert policy.index?
  end

  test 'show is allowed for owner restaurant ingredient' do
    policy = IngredientPolicy.new(@owner, @owned_ingredient)
    assert policy.show?
  end

  test 'show is allowed for shared ingredient for any user' do
    policy = IngredientPolicy.new(@other_user, @shared_ingredient)
    assert policy.show?
  end

  test 'show is denied for non-owner restaurant ingredient' do
    policy = IngredientPolicy.new(@other_user, @owned_ingredient)
    assert_not policy.show?
  end

  test 'show is allowed for super admin' do
    policy = IngredientPolicy.new(@super_admin, @owned_ingredient)
    assert policy.show?
  end

  test 'show is denied for orphan non-shared ingredient when not owner' do
    policy = IngredientPolicy.new(@other_user, @orphan_ingredient)
    assert_not policy.show?
  end

  test 'create is allowed for authenticated user' do
    policy = IngredientPolicy.new(@owner, @owned_ingredient)
    assert policy.create?
  end

  test 'create is allowed for guest (user.present? always true via User.new)' do
    policy = IngredientPolicy.new(nil, @owned_ingredient)
    assert policy.create?
  end

  test 'update is allowed for owner' do
    policy = IngredientPolicy.new(@owner, @owned_ingredient)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = IngredientPolicy.new(@other_user, @owned_ingredient)
    assert_not policy.update?
  end

  test 'update is allowed for super admin' do
    policy = IngredientPolicy.new(@super_admin, @owned_ingredient)
    assert policy.update?
  end

  test 'destroy delegates to update' do
    policy_owner = IngredientPolicy.new(@owner, @owned_ingredient)
    policy_other = IngredientPolicy.new(@other_user, @owned_ingredient)
    assert policy_owner.destroy?
    assert_not policy_other.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert IngredientPolicy < ApplicationPolicy
  end
end
