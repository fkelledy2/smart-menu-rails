# frozen_string_literal: true

require 'test_helper'

class OrdrAutoPayPolicyTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @owner = @restaurant.user
    @ordr = ordrs(:one)
    # Ensure ordr belongs to this restaurant
    @ordr.update!(restaurant: @restaurant)
  end

  # payment_method?

  test 'payment_method? allows anonymous user (customer)' do
    policy = OrdrPolicy.new(User.new, @ordr)
    assert policy.payment_method?
  end

  test 'payment_method? allows restaurant owner' do
    policy = OrdrPolicy.new(@owner, @ordr)
    assert policy.payment_method?
  end

  test 'payment_method? denies unrelated authenticated user' do
    other_user = users(:two)
    # Ensure other_user is not an employee of this restaurant
    Employee.where(user: other_user, restaurant: @restaurant).destroy_all
    policy = OrdrPolicy.new(other_user, @ordr)
    assert_not policy.payment_method?
  end

  # auto_pay?

  test 'auto_pay? allows anonymous user' do
    policy = OrdrPolicy.new(User.new, @ordr)
    assert policy.auto_pay?
  end

  test 'auto_pay? allows restaurant owner' do
    policy = OrdrPolicy.new(@owner, @ordr)
    assert policy.auto_pay?
  end

  test 'auto_pay? denies unrelated user' do
    other_user = users(:two)
    Employee.where(user: other_user, restaurant: @restaurant).destroy_all
    policy = OrdrPolicy.new(other_user, @ordr)
    assert_not policy.auto_pay?
  end

  # view_bill?

  test 'view_bill? allows anonymous user' do
    policy = OrdrPolicy.new(User.new, @ordr)
    assert policy.view_bill?
  end

  test 'view_bill? allows owner' do
    policy = OrdrPolicy.new(@owner, @ordr)
    assert policy.view_bill?
  end

  # capture?

  test 'capture? denies anonymous user' do
    policy = OrdrPolicy.new(User.new, @ordr)
    assert_not policy.capture?
  end

  test 'capture? allows restaurant owner' do
    policy = OrdrPolicy.new(@owner, @ordr)
    assert policy.capture?
  end

  test 'capture? denies unrelated user' do
    other_user = users(:two)
    Employee.where(user: other_user, restaurant: @restaurant).destroy_all
    policy = OrdrPolicy.new(other_user, @ordr)
    assert_not policy.capture?
  end
end
