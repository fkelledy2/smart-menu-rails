# frozen_string_literal: true

require 'test_helper'

class MenuExperimentExposureTest < ActiveSupport::TestCase
  def setup
    @menu = menus(:one)
    @dining_session = dining_sessions(:valid_session)

    @v1 = MenuVersion.create!(
      menu: @menu,
      version_number: 200,
      snapshot_json: { schema_version: 1 },
      is_active: false,
    )
    @v2 = MenuVersion.create!(
      menu: @menu,
      version_number: 201,
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
    @experiment.destroy! if @experiment&.persisted?
    @v1.destroy! if @v1&.persisted?
    @v2.destroy! if @v2&.persisted?
  end

  test 'valid exposure record' do
    exposure = MenuExperimentExposure.new(
      menu_experiment: @experiment,
      assigned_version: @v1,
      dining_session: @dining_session,
      exposed_at: Time.current,
    )
    assert exposure.valid?, exposure.errors.full_messages.join(', ')
  end

  test 'invalid without exposed_at' do
    exposure = MenuExperimentExposure.new(
      menu_experiment: @experiment,
      assigned_version: @v1,
      dining_session: @dining_session,
    )
    assert_not exposure.valid?
    assert exposure.errors[:exposed_at].any?
  end

  test 'unique per dining_session and menu_experiment' do
    MenuExperimentExposure.create!(
      menu_experiment: @experiment,
      assigned_version: @v1,
      dining_session: @dining_session,
      exposed_at: Time.current,
    )
    duplicate = MenuExperimentExposure.new(
      menu_experiment: @experiment,
      assigned_version: @v2,
      dining_session: @dining_session,
      exposed_at: Time.current,
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:dining_session_id].any?
  end
end
