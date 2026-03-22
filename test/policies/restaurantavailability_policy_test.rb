require 'test_helper'

# RestaurantavailabilityPolicy:
# index?/create? — user.present? (always true via User.new coercion)
# show?/update?/destroy? — user.present? && owns_restaurant_availability?
#   (user.restaurants.exists?(id: record.restaurant_id))
# Scope — filters to restaurant_ids owned by the user; returns none for guest
class RestaurantavailabilityPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @availability = restaurantavailabilities(:one) # restaurant: one (owned by users(:one))
  end

  test 'index is allowed for authenticated user' do
    policy = RestaurantavailabilityPolicy.new(@owner, @availability)
    assert policy.index?
  end

  test 'index is allowed for nil user (User.new coercion)' do
    policy = RestaurantavailabilityPolicy.new(nil, @availability)
    assert policy.index?
  end

  test 'create is allowed for authenticated user' do
    policy = RestaurantavailabilityPolicy.new(@owner, @availability)
    assert policy.create?
  end

  test 'show is allowed for restaurant owner' do
    policy = RestaurantavailabilityPolicy.new(@owner, @availability)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = RestaurantavailabilityPolicy.new(@other_user, @availability)
    assert_not policy.show?
  end

  test 'update is allowed for restaurant owner' do
    policy = RestaurantavailabilityPolicy.new(@owner, @availability)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = RestaurantavailabilityPolicy.new(@other_user, @availability)
    assert_not policy.update?
  end

  test 'destroy is allowed for restaurant owner' do
    policy = RestaurantavailabilityPolicy.new(@owner, @availability)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner' do
    policy = RestaurantavailabilityPolicy.new(@other_user, @availability)
    assert_not policy.destroy?
  end

  test 'scope returns availabilities for user restaurants' do
    scope = RestaurantavailabilityPolicy::Scope.new(@owner, Restaurantavailability.all)
    result = scope.resolve
    owner_restaurant_ids = @owner.restaurants.pluck(:id)
    result.each do |a|
      assert_includes owner_restaurant_ids, a.restaurant_id
    end
  end

  test 'scope returns none for nil user' do
    scope = RestaurantavailabilityPolicy::Scope.new(nil, Restaurantavailability.all)
    assert_empty scope.resolve
  end

  test 'inherits from ApplicationPolicy' do
    assert RestaurantavailabilityPolicy < ApplicationPolicy
  end
end
