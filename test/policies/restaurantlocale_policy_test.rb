require 'test_helper'

# RestaurantlocalePolicy: index/create check user.present? (always true via User.new).
# show/update/destroy check user.present? AND owns_restaurant_locale?.
class RestaurantlocalePolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @restaurantlocale = restaurantlocales(:one) # belongs to restaurant :one => user :one
  end

  test 'index is allowed for authenticated user' do
    policy = RestaurantlocalePolicy.new(@owner, @restaurantlocale)
    assert policy.index?
  end

  test 'index is allowed for guest (user.present? always true)' do
    policy = RestaurantlocalePolicy.new(nil, @restaurantlocale)
    assert policy.index?
  end

  test 'create is allowed for authenticated user' do
    policy = RestaurantlocalePolicy.new(@owner, @restaurantlocale)
    assert policy.create?
  end

  test 'create is allowed for guest (user.present? always true)' do
    policy = RestaurantlocalePolicy.new(nil, @restaurantlocale)
    assert policy.create?
  end

  test 'show is allowed for owner' do
    policy = RestaurantlocalePolicy.new(@owner, @restaurantlocale)
    assert policy.show?
  end

  test 'show is denied for non-owner' do
    policy = RestaurantlocalePolicy.new(@other_user, @restaurantlocale)
    assert_not policy.show?
  end

  test 'update is allowed for owner' do
    policy = RestaurantlocalePolicy.new(@owner, @restaurantlocale)
    assert policy.update?
  end

  test 'update is denied for non-owner' do
    policy = RestaurantlocalePolicy.new(@other_user, @restaurantlocale)
    assert_not policy.update?
  end

  test 'destroy is allowed for owner' do
    policy = RestaurantlocalePolicy.new(@owner, @restaurantlocale)
    assert policy.destroy?
  end

  test 'destroy is denied for non-owner' do
    policy = RestaurantlocalePolicy.new(@other_user, @restaurantlocale)
    assert_not policy.destroy?
  end

  test 'inherits from ApplicationPolicy' do
    assert RestaurantlocalePolicy < ApplicationPolicy
  end

  test 'scope returns locales for owned restaurants only' do
    scope = RestaurantlocalePolicy::Scope.new(@owner, Restaurantlocale.all)
    result = scope.resolve
    restaurant_ids = @owner.restaurants.pluck(:id)
    result.each do |locale|
      assert_includes restaurant_ids, locale.restaurant_id
    end
  end

  test 'scope returns none for guest user (no restaurants)' do
    scope = RestaurantlocalePolicy::Scope.new(nil, Restaurantlocale.all)
    assert_equal 0, scope.resolve.count
  end
end
