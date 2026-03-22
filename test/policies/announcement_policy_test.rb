require 'test_helper'

# AnnouncementPolicy grants index/show to user.present?
# ApplicationPolicy converts nil -> User.new, so User.new.present? == true.
# There is no meaningful "anonymous denial" path for index/show here.
class AnnouncementPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @announcement = announcements(:one)
  end

  test 'index is allowed for authenticated user' do
    policy = AnnouncementPolicy.new(@user, @announcement)
    assert policy.index?
  end

  test 'index is allowed for guest (User.new) because user.present? is true' do
    policy = AnnouncementPolicy.new(nil, @announcement)
    assert policy.index?
  end

  test 'show is allowed for authenticated user' do
    policy = AnnouncementPolicy.new(@user, @announcement)
    assert policy.show?
  end

  test 'show is allowed for guest (User.new) because user.present? is true' do
    policy = AnnouncementPolicy.new(nil, @announcement)
    assert policy.show?
  end

  test 'inherits from ApplicationPolicy' do
    assert AnnouncementPolicy < ApplicationPolicy
  end

  test 'scope resolves all announcements for authenticated user' do
    scope = AnnouncementPolicy::Scope.new(@user, Announcement.all)
    result = scope.resolve
    assert_equal Announcement.count, result.count
  end

  test 'scope resolves all announcements for any user' do
    scope = AnnouncementPolicy::Scope.new(nil, Announcement.all)
    result = scope.resolve
    assert_equal Announcement.count, result.count
  end
end
