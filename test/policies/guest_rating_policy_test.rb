# frozen_string_literal: true

require 'test_helper'

class GuestRatingPolicyTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @other_restaurant = restaurants(:two)
    @owner = users(:one)
    @other_user = users(:two)
    @rating = GuestRating.new(restaurant: @restaurant, ordr: ordrs(:one), stars: 3, source: 'in_app')
  end

  test 'create? returns true for unauthenticated guest' do
    policy = GuestRatingPolicy.new(nil, @rating)
    assert policy.create?
  end

  test 'create? returns true for authenticated user' do
    policy = GuestRatingPolicy.new(@owner, @rating)
    assert policy.create?
  end

  test 'index? returns false for unauthenticated user' do
    policy = GuestRatingPolicy.new(nil, GuestRating.new(restaurant: @restaurant))
    assert_not policy.index?
  end

  test 'index? returns true for restaurant owner' do
    # owner is user_id on restaurant
    @restaurant.update!(user: @owner)
    policy = GuestRatingPolicy.new(@owner, GuestRating.new(restaurant: @restaurant))
    assert policy.index?
  end

  test 'index? returns false for unrelated user' do
    # Make sure other_user does not own or work at restaurant
    @restaurant.update!(user: @owner)
    policy = GuestRatingPolicy.new(@other_user, GuestRating.new(restaurant: @restaurant))
    # Other user should not have access unless they're a manager employee
    assert_not policy.index?
  end

  test 'index? returns true for super admin' do
    admin = users(:super_admin) if respond_to?(:super_admin)
    skip 'No super_admin fixture' unless defined?(admin) && admin
    policy = GuestRatingPolicy.new(admin, GuestRating.new(restaurant: @restaurant))
    assert policy.index?
  end
end
