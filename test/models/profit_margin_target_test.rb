# frozen_string_literal: true

require 'test_helper'

class ProfitMarginTargetTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menusection = menusections(:one)
    @menuitem = menuitems(:one)
  end

  def build_target(attrs = {})
    ProfitMarginTarget.new({
      restaurant: @restaurant,
      target_margin_percentage: 30,
      effective_from: Date.current,
    }.merge(attrs))
  end

  # === VALIDATIONS ===

  test 'valid when scoped to restaurant only' do
    target = build_target
    assert target.valid?, target.errors.full_messages.join(', ')
  end

  test 'valid when scoped to menusection only' do
    target = build_target(restaurant: nil, menusection: @menusection)
    assert target.valid?, target.errors.full_messages.join(', ')
  end

  test 'valid when scoped to menuitem only' do
    target = build_target(restaurant: nil, menuitem: @menuitem)
    assert target.valid?, target.errors.full_messages.join(', ')
  end

  test 'invalid when no scope is set' do
    target = build_target(restaurant: nil)
    assert_not target.valid?
    assert target.errors[:base].any?
  end

  test 'invalid when multiple scopes are set' do
    target = build_target(menusection: @menusection)
    assert_not target.valid?
    assert target.errors[:base].any?
  end

  test 'invalid when all three scopes are set' do
    target = build_target(menusection: @menusection, menuitem: @menuitem)
    assert_not target.valid?
    assert target.errors[:base].any?
  end

  test 'invalid without target_margin_percentage' do
    target = build_target(target_margin_percentage: nil)
    assert_not target.valid?
    assert target.errors[:target_margin_percentage].any?
  end

  test 'invalid when target_margin_percentage is negative' do
    target = build_target(target_margin_percentage: -1)
    assert_not target.valid?
    assert target.errors[:target_margin_percentage].any?
  end

  test 'invalid when target_margin_percentage exceeds 100' do
    target = build_target(target_margin_percentage: 101)
    assert_not target.valid?
    assert target.errors[:target_margin_percentage].any?
  end

  test 'valid at boundary values 0 and 100' do
    [0, 100].each do |val|
      target = build_target(target_margin_percentage: val)
      assert target.valid?, "Expected #{val}% to be valid: #{target.errors.full_messages}"
    end
  end

  test 'invalid without effective_from' do
    target = build_target(effective_from: nil)
    assert_not target.valid?
    assert target.errors[:effective_from].any?
  end

  test 'minimum_margin_percentage is optional' do
    target = build_target(minimum_margin_percentage: nil)
    assert target.valid?
  end

  test 'minimum_margin_percentage validates range when present' do
    target = build_target(minimum_margin_percentage: 110)
    assert_not target.valid?
    assert target.errors[:minimum_margin_percentage].any?
  end

  # === SCOPES ===

  test 'active scope returns targets within date range' do
    active = ProfitMarginTarget.create!(
      restaurant: @restaurant,
      target_margin_percentage: 25,
      effective_from: 1.week.ago,
      effective_to: nil,
    )
    past = ProfitMarginTarget.create!(
      restaurant: restaurants(:two),
      target_margin_percentage: 20,
      effective_from: 1.month.ago,
      effective_to: 1.day.ago,
    )

    active_ids = ProfitMarginTarget.active.pluck(:id)
    assert_includes active_ids, active.id
    assert_not_includes active_ids, past.id
  end

  test 'for_restaurant scope filters by restaurant_id' do
    target = ProfitMarginTarget.create!(
      restaurant: @restaurant,
      target_margin_percentage: 30,
      effective_from: Date.current,
    )

    ids = ProfitMarginTarget.for_restaurant(@restaurant.id).pluck(:id)
    assert_includes ids, target.id
  end
end
