# frozen_string_literal: true

require 'test_helper'

class MenuVersionSchedulerJobTest < ActiveJob::TestCase
  # MenuVersionSchedulerJob:
  #   - Activates MenuVersions where starts_at <= now AND is_active = false
  #     AND (ends_at IS NULL OR ends_at > now)
  #   - Deactivates MenuVersions where ends_at <= now AND is_active = true
  # It acquires a per-menu lock before activation and deactivates the
  # previously active version for the same menu.

  SNAPSHOT = { 'sections' => [] }.to_json

  def setup
    @menu = menus(:one)
    # Remove any pre-existing versions that could interfere.
    MenuVersion.where(menu: @menu).delete_all
  end

  def build_version(overrides = {})
    MenuVersion.create!(
      {
        menu: @menu,
        version_number: MenuVersion.maximum(:version_number).to_i + 1,
        snapshot_json: SNAPSHOT,
        is_active: false,
        starts_at: nil,
        ends_at: nil,
      }.merge(overrides),
    )
  end

  # ---------------------------------------------------------------------------
  # Activation path
  # ---------------------------------------------------------------------------

  test 'activates a version whose starts_at has passed' do
    version = build_version(starts_at: 1.minute.ago, is_active: false)
    MenuVersionSchedulerJob.perform_now
    assert version.reload.is_active
  end

  test 'does not activate a version whose starts_at is in the future' do
    version = build_version(starts_at: 1.minute.from_now, is_active: false)
    MenuVersionSchedulerJob.perform_now
    assert_not version.reload.is_active
  end

  test 'does not activate a version that is already active' do
    # Already active versions are excluded by the is_active: false condition
    version = build_version(starts_at: 1.minute.ago, is_active: true)
    MenuVersionSchedulerJob.perform_now
    assert version.reload.is_active # unchanged
  end

  test 'does not activate a version whose ends_at has already passed' do
    version = build_version(
      starts_at: 5.minutes.ago,
      ends_at: 1.minute.ago,
      is_active: false,
    )
    MenuVersionSchedulerJob.perform_now
    assert_not version.reload.is_active
  end

  test 'activates a version whose ends_at is in the future' do
    version = build_version(
      starts_at: 5.minutes.ago,
      ends_at: 1.hour.from_now,
      is_active: false,
    )
    MenuVersionSchedulerJob.perform_now
    assert version.reload.is_active
  end

  test 'deactivates the previously active version when a new one is activated' do
    old_version = build_version(starts_at: 1.hour.ago, is_active: true)
    new_version = build_version(starts_at: 1.minute.ago, is_active: false)

    MenuVersionSchedulerJob.perform_now

    assert_not old_version.reload.is_active, 'Previously active version should be deactivated'
    assert new_version.reload.is_active, 'New version should be activated'
  end

  # ---------------------------------------------------------------------------
  # Deactivation (expiry) path
  # ---------------------------------------------------------------------------

  test 'deactivates an active version whose ends_at has passed' do
    version = build_version(
      starts_at: 1.hour.ago,
      ends_at: 1.minute.ago,
      is_active: true,
    )
    MenuVersionSchedulerJob.perform_now
    assert_not version.reload.is_active
  end

  test 'does not deactivate an active version with no ends_at' do
    version = build_version(starts_at: 1.hour.ago, ends_at: nil, is_active: true)
    MenuVersionSchedulerJob.perform_now
    assert version.reload.is_active
  end

  test 'does not deactivate an active version whose ends_at is in the future' do
    version = build_version(
      starts_at: 1.hour.ago,
      ends_at: 1.hour.from_now,
      is_active: true,
    )
    MenuVersionSchedulerJob.perform_now
    assert version.reload.is_active
  end

  # ---------------------------------------------------------------------------
  # Idempotency
  # ---------------------------------------------------------------------------

  test 'running the job twice does not duplicate activations' do
    version = build_version(starts_at: 1.minute.ago, is_active: false)
    MenuVersionSchedulerJob.perform_now
    MenuVersionSchedulerJob.perform_now
    assert version.reload.is_active
    assert_equal 1, MenuVersion.where(menu: @menu, is_active: true).count
  end

  # ---------------------------------------------------------------------------
  # No-op when nothing needs to change
  # ---------------------------------------------------------------------------

  test 'runs without error when there are no scheduled versions' do
    assert_nothing_raised { MenuVersionSchedulerJob.perform_now }
  end

  # ---------------------------------------------------------------------------
  # Queue
  # ---------------------------------------------------------------------------

  test 'is enqueued on the default queue' do
    assert_enqueued_with(job: MenuVersionSchedulerJob, queue: 'default') do
      MenuVersionSchedulerJob.perform_later
    end
  end
end
