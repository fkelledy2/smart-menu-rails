# frozen_string_literal: true

require 'test_helper'

class WaitTimePolicyTest < ActiveSupport::TestCase
  # WaitTimePolicy record is a Restaurant instance.
  # Access is granted to owners (restaurant.user_id == user.id) and active employees.

  def setup
    @restaurant  = restaurants(:one)
    @owner       = users(:one)    # user_id of restaurants(:one) is users(:one)
    @other_user  = users(:two)
    @super_admin = users(:super_admin)

    # users(:one) has an employee record for restaurants(:one) via employees(:one),
    # but the owner check fires first, so we create a separate staff user.
    @staff_user = User.create!(
      email: 'staff_waittimetest@example.com',
      password: 'password123',
    )
    Employee.create!(
      name: 'Wait Time Staff',
      eid: 'wts1',
      status: 1,
      role: 1,
      restaurant: @restaurant,
      user: @staff_user,
    )
  end

  # ---------------------------------------------------------------------------
  # show?
  # ---------------------------------------------------------------------------

  test 'show? allowed for restaurant owner' do
    policy = WaitTimePolicy.new(@owner, @restaurant)
    assert policy.show?
  end

  test 'show? allowed for active employee' do
    policy = WaitTimePolicy.new(@staff_user, @restaurant)
    assert policy.show?
  end

  test 'show? denied for unrelated user' do
    policy = WaitTimePolicy.new(@other_user, @restaurant)
    assert_not policy.show?
  end

  test 'show? denied for nil user (nil becomes User.new, not persisted)' do
    policy = WaitTimePolicy.new(nil, @restaurant)
    assert_not policy.show?
  end

  # ---------------------------------------------------------------------------
  # create_queue_entry?
  # ---------------------------------------------------------------------------

  test 'create_queue_entry? allowed for owner' do
    policy = WaitTimePolicy.new(@owner, @restaurant)
    assert policy.create_queue_entry?
  end

  test 'create_queue_entry? denied for unrelated user' do
    policy = WaitTimePolicy.new(@other_user, @restaurant)
    assert_not policy.create_queue_entry?
  end

  # ---------------------------------------------------------------------------
  # seat_queue_entry?
  # ---------------------------------------------------------------------------

  test 'seat_queue_entry? allowed for staff' do
    policy = WaitTimePolicy.new(@staff_user, @restaurant)
    assert policy.seat_queue_entry?
  end

  test 'seat_queue_entry? denied for unrelated user' do
    policy = WaitTimePolicy.new(@other_user, @restaurant)
    assert_not policy.seat_queue_entry?
  end

  # ---------------------------------------------------------------------------
  # no_show_queue_entry?
  # ---------------------------------------------------------------------------

  test 'no_show_queue_entry? allowed for owner' do
    policy = WaitTimePolicy.new(@owner, @restaurant)
    assert policy.no_show_queue_entry?
  end

  test 'no_show_queue_entry? denied for other user' do
    policy = WaitTimePolicy.new(@other_user, @restaurant)
    assert_not policy.no_show_queue_entry?
  end

  # ---------------------------------------------------------------------------
  # cancel_queue_entry?
  # ---------------------------------------------------------------------------

  test 'cancel_queue_entry? allowed for staff' do
    policy = WaitTimePolicy.new(@staff_user, @restaurant)
    assert policy.cancel_queue_entry?
  end

  test 'cancel_queue_entry? denied for other user' do
    policy = WaitTimePolicy.new(@other_user, @restaurant)
    assert_not policy.cancel_queue_entry?
  end

  # ---------------------------------------------------------------------------
  # Record that does not respond to user_id — owner? returns false, but staff
  # path can still grant access.
  # ---------------------------------------------------------------------------

  test 'show? denied when record does not respond to user_id and user is not staff' do
    policy = WaitTimePolicy.new(@other_user, Object.new)
    assert_not policy.show?
  end

  test 'inherits from ApplicationPolicy' do
    assert WaitTimePolicy < ApplicationPolicy
  end
end
