# frozen_string_literal: true

require 'test_helper'

class MenuExperimentPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)            # owns restaurants(:one), plan :one (free)
    @other_user = users(:two)       # owns restaurants(:two)

    @restaurant = restaurants(:one)
    @menu = menus(:one)

    # Give the owner a Pro plan for experiment eligibility
    @pro_plan = plans(:pro)
    @owner.update_columns(plan_id: @pro_plan.id)

    @v1 = MenuVersion.create!(
      menu: @menu,
      version_number: 700,
      snapshot_json: { schema_version: 1 },
      is_active: false,
    )
    @v2 = MenuVersion.create!(
      menu: @menu,
      version_number: 701,
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
      status: :draft,
    )
  end

  def teardown
    @experiment.destroy! if @experiment&.persisted?
    @v1.destroy! if @v1&.persisted?
    @v2.destroy! if @v2&.persisted?
    # Restore owner plan
    @owner.update_columns(plan_id: plans(:one).id)
  end

  # === Owner on Pro plan — full access ===

  test 'owner on pro plan can index' do
    assert MenuExperimentPolicy.new(@owner, @experiment).index?
  end

  test 'owner on pro plan can show' do
    assert MenuExperimentPolicy.new(@owner, @experiment).show?
  end

  test 'owner on pro plan can create' do
    assert MenuExperimentPolicy.new(@owner, @experiment).create?
  end

  test 'owner on pro plan can update' do
    assert MenuExperimentPolicy.new(@owner, @experiment).update?
  end

  test 'owner on pro plan can destroy' do
    assert MenuExperimentPolicy.new(@owner, @experiment).destroy?
  end

  test 'owner on pro plan can pause' do
    assert MenuExperimentPolicy.new(@owner, @experiment).pause?
  end

  test 'owner on pro plan can end experiment' do
    assert MenuExperimentPolicy.new(@owner, @experiment).end_experiment?
  end

  # === Owner on free plan — denied ===

  test 'owner on free plan is denied' do
    @owner.update_columns(plan_id: plans(:one).id)
    assert_not MenuExperimentPolicy.new(@owner, @experiment).create?
  end

  # === Non-owner — denied ===

  test 'other user cannot access' do
    assert_not MenuExperimentPolicy.new(@other_user, @experiment).show?
  end

  test 'guest cannot access' do
    assert_not MenuExperimentPolicy.new(nil, @experiment).show?
  end

  # === Scope ===

  test 'scope returns experiments for menus owned by user' do
    scope = MenuExperimentPolicy::Scope.new(@owner, MenuExperiment).resolve
    assert_includes scope, @experiment
  end

  test 'scope excludes experiments for other users menus' do
    scope = MenuExperimentPolicy::Scope.new(@other_user, MenuExperiment).resolve
    assert_not_includes scope, @experiment
  end

  test 'scope returns all for super_admin' do
    @owner.update_columns(super_admin: true)
    scope = MenuExperimentPolicy::Scope.new(@owner, MenuExperiment).resolve
    assert scope.is_a?(ActiveRecord::Relation)
    @owner.update_columns(super_admin: false)
  end
end
