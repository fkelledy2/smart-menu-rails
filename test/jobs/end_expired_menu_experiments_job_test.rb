# frozen_string_literal: true

require 'test_helper'

class EndExpiredMenuExperimentsJobTest < ActiveJob::TestCase
  def setup
    @menu = menus(:one)

    @v1 = MenuVersion.create!(
      menu: @menu,
      version_number: 600,
      snapshot_json: { schema_version: 1 },
      is_active: false,
    )
    @v2 = MenuVersion.create!(
      menu: @menu,
      version_number: 601,
      snapshot_json: { schema_version: 1 },
      is_active: false,
    )
  end

  def teardown
    MenuExperiment.where(menu: @menu, control_version: @v1).delete_all
    @v1.destroy! if @v1&.persisted?
    @v2.destroy! if @v2&.persisted?
  end

  test 'marks expired active experiments as ended' do
    expired_exp = MenuExperiment.create!(
      menu: @menu,
      control_version: @v1,
      variant_version: @v2,
      allocation_pct: 50,
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now,
      status: :active,
    )
    expired_exp.update_columns(starts_at: 10.hours.ago, ends_at: 1.hour.ago)

    EndExpiredMenuExperimentsJob.perform_now
    expired_exp.reload
    assert expired_exp.status_ended?
  ensure
    expired_exp&.destroy!
  end

  test 'does not affect experiments that have not yet ended' do
    future_exp = MenuExperiment.create!(
      menu: @menu,
      control_version: @v1,
      variant_version: @v2,
      allocation_pct: 50,
      starts_at: 1.hour.from_now,
      ends_at: 24.hours.from_now,
      status: :active,
    )

    EndExpiredMenuExperimentsJob.perform_now
    future_exp.reload
    assert future_exp.status_active?
  ensure
    future_exp&.destroy!
  end

  test 'does not affect draft experiments' do
    draft_exp = MenuExperiment.create!(
      menu: @menu,
      control_version: @v1,
      variant_version: @v2,
      allocation_pct: 50,
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now,
      status: :draft,
    )
    draft_exp.update_columns(starts_at: 10.hours.ago, ends_at: 1.hour.ago)

    EndExpiredMenuExperimentsJob.perform_now
    draft_exp.reload
    assert draft_exp.status_draft?
  ensure
    draft_exp&.destroy!
  end

  test 'running twice for same experiment is idempotent' do
    exp = MenuExperiment.create!(
      menu: @menu,
      control_version: @v1,
      variant_version: @v2,
      allocation_pct: 50,
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now,
      status: :active,
    )
    exp.update_columns(starts_at: 10.hours.ago, ends_at: 1.hour.ago)

    EndExpiredMenuExperimentsJob.perform_now
    EndExpiredMenuExperimentsJob.perform_now

    exp.reload
    assert exp.status_ended?
  ensure
    exp&.destroy!
  end
end
