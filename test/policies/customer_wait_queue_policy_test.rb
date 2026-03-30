require 'test_helper'

class CustomerWaitQueuePolicyTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @owner      = users(:one)  # restaurant one owner
    @employee   = users(:two)  # has employee record for restaurant one
    @outsider   = User.new     # not persisted
    @entry      = customer_wait_queues(:waiting_one)
  end

  # Helper to build a policy instance
  def policy_for(user, record)
    CustomerWaitQueuePolicy.new(user, record)
  end

  # ---------------------------------------------------------------------------
  # Owner
  # ---------------------------------------------------------------------------

  test 'owner can index' do
    assert policy_for(@owner, @entry).index?
  end

  test 'owner can show' do
    assert policy_for(@owner, @entry).show?
  end

  test 'owner can create' do
    assert policy_for(@owner, @entry).create?
  end

  test 'owner can update' do
    assert policy_for(@owner, @entry).update?
  end

  test 'owner can seat' do
    assert policy_for(@owner, @entry).seat?
  end

  test 'owner can notify' do
    assert policy_for(@owner, @entry).notify_customer?
  end

  test 'owner can mark no_show' do
    assert policy_for(@owner, @entry).no_show?
  end

  test 'owner can cancel' do
    assert policy_for(@owner, @entry).cancel?
  end

  test 'owner can destroy' do
    assert policy_for(@owner, @entry).destroy?
  end

  # ---------------------------------------------------------------------------
  # Employee (active for restaurant)
  # ---------------------------------------------------------------------------

  test 'active employee can create queue entry' do
    # Verify employee fixture for restaurant one exists
    employee_record = Employee.find_by(user: @employee, restaurant: @restaurant, status: :active)
    skip 'No active employee fixture for users(:two) at restaurant(:one)' unless employee_record

    assert policy_for(@employee, @entry).create?
  end

  test 'active employee can seat' do
    employee_record = Employee.find_by(user: @employee, restaurant: @restaurant, status: :active)
    skip 'No active employee fixture' unless employee_record

    assert policy_for(@employee, @entry).seat?
  end

  test 'active employee cannot destroy' do
    employee_record = Employee.find_by(user: @employee, restaurant: @restaurant, status: :active)
    skip 'No active employee fixture' unless employee_record

    # Only owner can destroy — employee gets false via owner? check
    # Employee is not the owner, so destroy? should be false
    assert_not policy_for(@employee, @entry).destroy?
  end

  # ---------------------------------------------------------------------------
  # Unauthenticated / outsider
  # ---------------------------------------------------------------------------

  test 'unpersisted user cannot index' do
    assert_not policy_for(@outsider, @entry).index?
  end

  test 'unpersisted user cannot create' do
    assert_not policy_for(@outsider, @entry).create?
  end

  test 'unpersisted user cannot seat' do
    assert_not policy_for(@outsider, @entry).seat?
  end
end
