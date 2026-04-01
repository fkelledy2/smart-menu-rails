# frozen_string_literal: true

require 'test_helper'

class ProfitMarginPolicyTest < ActiveSupport::TestCase
  test 'valid with required attributes' do
    policy = ProfitMarginPolicy.new(
      key: 'test_policy',
      target_gross_margin_pct: 60,
      floor_gross_margin_pct: 40,
    )
    assert policy.valid?
  end

  test 'requires key' do
    policy = ProfitMarginPolicy.new(
      target_gross_margin_pct: 60,
      floor_gross_margin_pct: 40,
    )
    assert_not policy.valid?
  end

  test 'requires unique key' do
    ProfitMarginPolicy.create!(key: 'unique_key', target_gross_margin_pct: 60, floor_gross_margin_pct: 40)
    dup = ProfitMarginPolicy.new(key: 'unique_key', target_gross_margin_pct: 60, floor_gross_margin_pct: 40)
    assert_not dup.valid?
  end

  test 'floor must be less than target' do
    policy = ProfitMarginPolicy.new(
      key: 'bad_policy',
      target_gross_margin_pct: 40,
      floor_gross_margin_pct: 60,
    )
    assert_not policy.valid?
    assert_includes policy.errors[:floor_gross_margin_pct], 'must be less than target gross margin'
  end

  test 'current returns the active policy' do
    active = profit_margin_policies(:default)
    assert_equal active, ProfitMarginPolicy.current
  end

  test 'status enum works' do
    policy = ProfitMarginPolicy.new(status: :active)
    assert policy.active?
    assert_not policy.inactive?
  end
end
