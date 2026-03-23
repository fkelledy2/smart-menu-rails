require 'test_helper'

class AnnouncementsHelperTest < ActionView::TestCase
  def create_announcement(published_at: 1.hour.ago)
    Announcement.create!(
      name: 'Test Announcement',
      description: 'Test body',
      published_at: published_at,
      announcement_type: 'new',
    )
  end

  test 'unread_announcements returns nil when no announcements exist' do
    Announcement.delete_all
    result = unread_announcements(users(:one))
    assert_nil result
  end

  test 'unread_announcements returns class when user is nil' do
    create_announcement
    result = unread_announcements(nil)
    assert_equal 'unread-announcements', result
  end

  test 'unread_announcements returns class when user has never read announcements' do
    create_announcement
    user = users(:one)
    user.update_column(:announcements_last_read_at, nil)
    result = unread_announcements(user)
    assert_equal 'unread-announcements', result
  end

  test 'unread_announcements returns nil when user read after latest announcement' do
    user = users(:one)
    create_announcement(published_at: 2.hours.ago)
    user.update_column(:announcements_last_read_at, 1.hour.ago)
    result = unread_announcements(user)
    assert_nil result
  end

  test 'announcement_class returns text-success for new' do
    assert_equal 'text-success', announcement_class('new')
  end

  test 'announcement_class returns text-warning for update' do
    assert_equal 'text-warning', announcement_class('update')
  end

  test 'announcement_class returns text-danger for fix' do
    assert_equal 'text-danger', announcement_class('fix')
  end

  test 'announcement_class returns text-success for unknown type' do
    assert_equal 'text-success', announcement_class('unknown')
  end
end
