# frozen_string_literal: true

require 'test_helper'

class FloorplanPolicyTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @owner = @restaurant.user || users(:one)
    @restaurant.update!(user: @owner) unless @restaurant.user_id == @owner.id
  end

  test 'show? allows restaurant owner' do
    policy = FloorplanPolicy.new(@owner, @restaurant)
    assert policy.show?
  end

  test 'show? allows active employee' do
    employee_user = users(:two)
    Employee.create!(
      user: employee_user,
      restaurant: @restaurant,
      status: :active,
      role: :staff,
      name: 'Floor Staff',
      eid: "EMP-#{SecureRandom.hex(4)}",
    )
    policy = FloorplanPolicy.new(employee_user, @restaurant)
    assert policy.show?
  end

  test 'show? denies anonymous user (User.new — no id)' do
    policy = FloorplanPolicy.new(User.new, @restaurant)
    assert_not policy.show?
  end

  test 'show? denies user with no relation to restaurant' do
    other_user = users(:two)
    policy = FloorplanPolicy.new(other_user, @restaurant)
    assert_not policy.show?
  end

  test 'show? denies nil user' do
    policy = FloorplanPolicy.new(nil, @restaurant)
    assert_not policy.show?
  end
end
