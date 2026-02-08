require 'test_helper'

class ResourceLockTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @menu = menus(:one)
    @lock = ResourceLock.create!(
      user: @user,
      resource_type: 'Menu',
      resource_id: @menu.id,
      session_id: 'test-session-123',
    )
  end

  test 'belongs to user' do
    assert_respond_to @lock, :user
    assert_not_nil @lock.user
    assert_equal @user, @lock.user
  end

  test 'requires user' do
    lock = ResourceLock.new
    assert_not lock.valid?
    assert_includes lock.errors[:user], 'must exist'
  end

  test 'can create lock with valid attributes' do
    lock = ResourceLock.new(
      user: @user,
      resource_type: 'Menu',
      resource_id: @menu.id,
      session_id: 'new-session-456',
    )
    assert lock.valid?
    assert lock.save
  end

  test 'can destroy lock' do
    assert_difference 'ResourceLock.count', -1 do
      @lock.destroy
    end
  end

  test 'multiple locks can exist for same user' do
    menu2 = menus(:two)
    lock2 = ResourceLock.create!(
      user: @user,
      resource_type: 'Menu',
      resource_id: menu2.id,
      session_id: 'session-menu2',
    )
    assert_not_nil lock2
    assert_equal @user, lock2.user
  end
end
