# frozen_string_literal: true

require 'test_helper'

class MenuExperimentTest < ActiveSupport::TestCase
  def setup
    @menu = menus(:one)
    @user = users(:one)

    # Create two versions — required for experiments
    @v1 = MenuVersion.create!(
      menu: @menu,
      version_number: 100,
      snapshot_json: { schema_version: 1, menu: { id: @menu.id } },
      is_active: false,
    )
    @v2 = MenuVersion.create!(
      menu: @menu,
      version_number: 101,
      snapshot_json: { schema_version: 1, menu: { id: @menu.id } },
      is_active: false,
    )

    @valid_attrs = {
      menu: @menu,
      control_version: @v1,
      variant_version: @v2,
      allocation_pct: 50,
      starts_at: 1.hour.from_now,
      ends_at: 24.hours.from_now,
      status: :draft,
    }
  end

  def teardown
    @v1.destroy!
    @v2.destroy!
  end

  # === VALIDATIONS ===

  test 'valid with required fields' do
    experiment = MenuExperiment.new(@valid_attrs)
    assert experiment.valid?, experiment.errors.full_messages.join(', ')
  end

  test 'invalid without menu' do
    experiment = MenuExperiment.new(@valid_attrs.merge(menu: nil))
    assert_not experiment.valid?
  end

  test 'invalid without control_version' do
    experiment = MenuExperiment.new(@valid_attrs.merge(control_version: nil))
    assert_not experiment.valid?
  end

  test 'invalid without variant_version' do
    experiment = MenuExperiment.new(@valid_attrs.merge(variant_version: nil))
    assert_not experiment.valid?
  end

  test 'invalid if allocation_pct is 0' do
    experiment = MenuExperiment.new(@valid_attrs.merge(allocation_pct: 0))
    assert_not experiment.valid?
    assert experiment.errors[:allocation_pct].any?
  end

  test 'invalid if allocation_pct is 100' do
    experiment = MenuExperiment.new(@valid_attrs.merge(allocation_pct: 100))
    assert_not experiment.valid?
    assert experiment.errors[:allocation_pct].any?
  end

  test 'valid at allocation_pct boundaries 1 and 99' do
    [1, 99].each do |pct|
      exp = MenuExperiment.new(@valid_attrs.merge(allocation_pct: pct))
      assert exp.valid?, "Expected valid at allocation_pct=#{pct}: #{exp.errors.full_messages}"
    end
  end

  test 'invalid if ends_at is before starts_at' do
    experiment = MenuExperiment.new(
      @valid_attrs.merge(starts_at: 10.hours.from_now, ends_at: 5.hours.from_now),
    )
    assert_not experiment.valid?
    assert experiment.errors[:ends_at].any?
  end

  test 'invalid if starts_at is in the past on create' do
    experiment = MenuExperiment.new(@valid_attrs.merge(starts_at: 1.hour.ago))
    assert_not experiment.valid?
    assert experiment.errors[:starts_at].any?
  end

  test 'does not re-validate starts_at in past on update' do
    exp = MenuExperiment.create!(@valid_attrs)
    # Travel past the starts_at and update a different field
    exp.reload
    travel_to 2.hours.from_now do
      # starts_at is now in the past, but updating ends_at should be fine
      exp.ends_at = 26.hours.from_now
      assert exp.valid?, exp.errors.full_messages.inspect
    end
  ensure
    exp.destroy! if exp&.persisted?
  end

  test 'invalid if menu has fewer than two versions' do
    other_menu = menus(:two)
    experiment = MenuExperiment.new(
      @valid_attrs.merge(menu: other_menu),
    )
    # other_menu has no versions
    assert_not experiment.valid?
    assert experiment.errors[:base].any?
  end

  test 'invalid if control_version does not belong to menu' do
    v_other = MenuVersion.create!(
      menu: menus(:two),
      version_number: 1,
      snapshot_json: { v: 1 },
      is_active: false,
    )
    experiment = MenuExperiment.new(@valid_attrs.merge(control_version: v_other))
    assert_not experiment.valid?
    assert experiment.errors[:control_version].any?
  ensure
    v_other&.destroy!
  end

  test 'rejects overlapping active experiments for same menu' do
    first = MenuExperiment.create!(@valid_attrs.merge(status: :active))
    second = MenuExperiment.new(@valid_attrs.merge(
                                  starts_at: 2.hours.from_now,
                                  ends_at: 12.hours.from_now,
                                ))
    assert_not second.valid?
    assert second.errors[:base].any?
  ensure
    first.destroy! if first&.persisted?
  end

  test 'allows non-overlapping experiments' do
    first = MenuExperiment.create!(@valid_attrs.merge(
                                     status: :active,
                                     starts_at: 1.hour.from_now,
                                     ends_at: 6.hours.from_now,
                                   ))
    second = MenuExperiment.new(@valid_attrs.merge(
                                  starts_at: 7.hours.from_now,
                                  ends_at: 12.hours.from_now,
                                ))
    assert second.valid?, second.errors.full_messages.inspect
  ensure
    first.destroy! if first&.persisted?
  end

  test 'ignores overlap with ended experiments' do
    ended = MenuExperiment.create!(@valid_attrs.merge(status: :ended))
    second = MenuExperiment.new(@valid_attrs.merge(
                                  starts_at: 2.hours.from_now,
                                  ends_at: 12.hours.from_now,
                                ))
    assert second.valid?, second.errors.full_messages.inspect
  ensure
    ended.destroy! if ended&.persisted?
  end

  test 'allocation_pct cannot be changed when active' do
    exp = MenuExperiment.create!(@valid_attrs.merge(status: :active))
    exp.allocation_pct = 75
    assert_not exp.valid?
    assert exp.errors[:allocation_pct].any?
  ensure
    exp.destroy! if exp&.persisted?
  end

  test 'allocation_pct can be changed when draft' do
    exp = MenuExperiment.create!(@valid_attrs.merge(status: :draft))
    exp.allocation_pct = 75
    assert exp.valid?, exp.errors.full_messages.inspect
  ensure
    exp.destroy! if exp&.persisted?
  end

  # === ENUM ===

  test 'status enum has expected values' do
    assert_equal 0, MenuExperiment.statuses[:draft]
    assert_equal 1, MenuExperiment.statuses[:active]
    assert_equal 2, MenuExperiment.statuses[:paused]
    assert_equal 3, MenuExperiment.statuses[:ended]
  end

  # === SCOPES ===

  test 'active_at scope returns experiments active at given time' do
    exp = MenuExperiment.create!(@valid_attrs.merge(
                                   status: :active,
                                   starts_at: 30.minutes.from_now,
                                   ends_at: 8.hours.from_now,
                                 ))

    travel_to 1.hour.from_now do
      assert_includes MenuExperiment.active_at, exp
    end
  ensure
    exp.destroy! if exp&.persisted?
  end

  test 'active_at scope excludes expired experiments' do
    exp = MenuExperiment.create!(@valid_attrs.merge(
                                   status: :active,
                                   starts_at: 1.hour.from_now,
                                   ends_at: 2.hours.from_now,
                                 ))
    exp.update_columns(starts_at: 10.hours.ago, ends_at: 1.hour.ago)
    assert_not_includes MenuExperiment.active_at, exp
  ensure
    exp.destroy! if exp&.persisted?
  end

  test 'active_for_menu returns first active experiment for menu' do
    exp = MenuExperiment.create!(@valid_attrs.merge(
                                   status: :active,
                                   starts_at: 30.minutes.from_now,
                                   ends_at: 8.hours.from_now,
                                 ))

    travel_to 1.hour.from_now do
      result = MenuExperiment.active_for_menu(@menu)
      assert_equal exp, result
    end
  ensure
    exp.destroy! if exp&.persisted?
  end

  test 'active_for_menu returns nil when no active experiment' do
    assert_nil MenuExperiment.active_for_menu(@menu)
  end

  # === ASSOCIATIONS ===

  test 'belongs_to menu' do
    exp = MenuExperiment.new(@valid_attrs)
    assert_equal @menu, exp.menu
  end

  test 'belongs_to control_version' do
    exp = MenuExperiment.new(@valid_attrs)
    assert_equal @v1, exp.control_version
  end

  test 'belongs_to variant_version' do
    exp = MenuExperiment.new(@valid_attrs)
    assert_equal @v2, exp.variant_version
  end
end
