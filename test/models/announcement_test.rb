require 'test_helper'

class AnnouncementTest < ActiveSupport::TestCase
  def setup
    @announcement = Announcement.new(
      name: 'Test Announcement',
      description: 'This is a test announcement',
      announcement_type: 'new',
      published_at: Time.zone.now,
    )
  end

  # === VALIDATION TESTS ===

  test 'should be valid with valid attributes' do
    assert @announcement.valid?
  end

  test 'should require name' do
    @announcement.name = nil
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:name], "can't be blank"
  end

  test 'should require name not empty' do
    @announcement.name = ''
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:name], "can't be blank"
  end

  test 'should require description' do
    @announcement.description = nil
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:description], "can't be blank"
  end

  test 'should require description not empty' do
    @announcement.description = ''
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:description], "can't be blank"
  end

  test 'should require announcement_type' do
    @announcement.announcement_type = nil
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:announcement_type], "can't be blank"
  end

  test 'should require announcement_type not empty' do
    @announcement.announcement_type = ''
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:announcement_type], "can't be blank"
  end

  test 'should require published_at' do
    @announcement.published_at = nil
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:published_at], "can't be blank"
  end

  test 'should validate announcement_type inclusion' do
    @announcement.announcement_type = 'invalid_type'
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:announcement_type], 'is not included in the list'
  end

  test 'should accept valid announcement_type new' do
    @announcement.announcement_type = 'new'
    assert @announcement.valid?
  end

  test 'should accept valid announcement_type fix' do
    @announcement.announcement_type = 'fix'
    assert @announcement.valid?
  end

  test 'should accept valid announcement_type update' do
    @announcement.announcement_type = 'update'
    assert @announcement.valid?
  end

  # === DEFAULT VALUE TESTS ===

  test 'should set default published_at on initialize' do
    announcement = Announcement.new
    assert_not_nil announcement.published_at
    assert_kind_of Time, announcement.published_at
  end

  test 'should set default announcement_type on initialize' do
    announcement = Announcement.new
    assert_equal 'new', announcement.announcement_type
  end

  test 'should not override provided published_at' do
    custom_time = 1.day.ago
    announcement = Announcement.new(published_at: custom_time)
    assert_equal custom_time.to_i, announcement.published_at.to_i
  end

  test 'should not override provided announcement_type' do
    announcement = Announcement.new(announcement_type: 'fix')
    assert_equal 'fix', announcement.announcement_type
  end

  # === FACTORY/CREATION TESTS ===

  test 'should create announcement with valid data' do
    announcement = Announcement.new(
      name: 'New Feature Release',
      description: "We've added exciting new features to improve your experience",
      announcement_type: 'new',
    )
    assert announcement.save
    assert_equal 'New Feature Release', announcement.name
    assert_equal "We've added exciting new features to improve your experience", announcement.description
    assert_equal 'new', announcement.announcement_type
  end

  test 'should create fix announcement' do
    announcement = Announcement.new(
      name: 'Bug Fix',
      description: 'Fixed an issue with menu loading',
      announcement_type: 'fix',
    )
    assert announcement.save
    assert_equal 'fix', announcement.announcement_type
  end

  test 'should create update announcement' do
    announcement = Announcement.new(
      name: 'System Update',
      description: 'System maintenance completed successfully',
      announcement_type: 'update',
    )
    assert announcement.save
    assert_equal 'update', announcement.announcement_type
  end

  # === CONSTANTS TESTS ===

  test 'should have correct TYPES constant' do
    assert_equal %w[new fix update], Announcement::TYPES
  end

  # === EDGE CASE TESTS ===

  test 'should handle whitespace in required fields' do
    @announcement.name = '   '
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:name], "can't be blank"

    @announcement.description = '   '
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:description], "can't be blank"

    @announcement.announcement_type = '   '
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:announcement_type], "can't be blank"
  end

  test 'should handle case sensitivity in announcement_type' do
    @announcement.announcement_type = 'NEW'
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:announcement_type], 'is not included in the list'

    @announcement.announcement_type = 'Fix'
    assert_not @announcement.valid?
    assert_includes @announcement.errors[:announcement_type], 'is not included in the list'
  end
end
