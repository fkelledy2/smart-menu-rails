# frozen_string_literal: true

require 'test_helper'

class MenuExperimentExposureJobTest < ActiveJob::TestCase
  def setup
    @menu = menus(:one)
    @dining_session = dining_sessions(:valid_session)

    @v1 = MenuVersion.create!(
      menu: @menu,
      version_number: 500,
      snapshot_json: { schema_version: 1 },
      is_active: false,
    )
    @v2 = MenuVersion.create!(
      menu: @menu,
      version_number: 501,
      snapshot_json: { schema_version: 1 },
      is_active: false,
    )

    @experiment = MenuExperiment.create!(
      menu: @menu,
      control_version: @v1,
      variant_version: @v2,
      allocation_pct: 50,
      starts_at: 1.hour.from_now,
      ends_at: 24.hours.from_now,
      status: :active,
    )
  end

  def teardown
    MenuExperimentExposure.where(menu_experiment: @experiment).delete_all
    @experiment.destroy! if @experiment&.persisted?
    @v1.destroy! if @v1&.persisted?
    @v2.destroy! if @v2&.persisted?
  end

  test 'creates exposure record' do
    assert_difference 'MenuExperimentExposure.count', 1 do
      MenuExperimentExposureJob.perform_now(
        @dining_session.id,
        @experiment.id,
        @v1.id,
      )
    end

    exposure = MenuExperimentExposure.find_by(
      dining_session: @dining_session,
      menu_experiment: @experiment,
    )
    assert_not_nil exposure
    assert_equal @v1.id, exposure.assigned_version_id
    assert_not_nil exposure.exposed_at
  end

  test 'is idempotent — second call is a no-op' do
    MenuExperimentExposureJob.perform_now(@dining_session.id, @experiment.id, @v1.id)

    assert_no_difference 'MenuExperimentExposure.count' do
      MenuExperimentExposureJob.perform_now(@dining_session.id, @experiment.id, @v1.id)
    end
  end

  test 'skips gracefully when dining session not found' do
    assert_no_difference 'MenuExperimentExposure.count' do
      MenuExperimentExposureJob.perform_now(0, @experiment.id, @v1.id)
    end
  end

  test 'skips gracefully when experiment not found' do
    assert_no_difference 'MenuExperimentExposure.count' do
      MenuExperimentExposureJob.perform_now(@dining_session.id, 0, @v1.id)
    end
  end

  test 'skips gracefully when version not found' do
    assert_no_difference 'MenuExperimentExposure.count' do
      MenuExperimentExposureJob.perform_now(@dining_session.id, @experiment.id, 0)
    end
  end
end
