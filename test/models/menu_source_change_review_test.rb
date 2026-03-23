require 'test_helper'

class MenuSourceChangeReviewTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menu_source = MenuSource.create!(
      restaurant: @restaurant,
      source_url: 'https://example.com/menu',
      source_type: :html,
      status: :active,
    )
    @review = MenuSourceChangeReview.new(
      menu_source: @menu_source,
      status: :pending,
      detected_at: Time.current,
      previous_fingerprint: 'abc123',
      new_fingerprint: 'def456',
    )
  end

  test 'valid review saves' do
    assert @review.save
  end

  test 'requires status' do
    @review.status = nil
    assert_not @review.valid?
  end

  test 'requires detected_at' do
    @review.detected_at = nil
    assert_not @review.valid?
  end

  test 'pending status works' do
    @review.save!
    assert @review.pending?
  end

  test 'resolved status works' do
    @review.status = :resolved
    @review.save!
    assert @review.resolved?
  end

  test 'ignored status works' do
    @review.status = :ignored
    @review.save!
    assert @review.ignored?
  end

  test 'diff_pending diff_status works' do
    @review.diff_status = :diff_pending
    @review.save!
    assert @review.diff_diff_pending?
  end

  test 'diff_complete diff_status works' do
    @review.diff_status = :diff_complete
    @review.save!
    assert @review.diff_diff_complete?
  end

  test 'diff_failed diff_status works' do
    @review.diff_status = :diff_failed
    @review.save!
    assert @review.diff_diff_failed?
  end

  test 'pending scope returns pending reviews' do
    @review.save!
    assert_includes MenuSourceChangeReview.pending, @review
  end

  test 'pending scope excludes resolved reviews' do
    @review.status = :resolved
    @review.save!
    assert_not_includes MenuSourceChangeReview.pending, @review
  end

  test 'belongs to menu_source' do
    @review.save!
    assert_equal @menu_source, @review.menu_source
  end
end
