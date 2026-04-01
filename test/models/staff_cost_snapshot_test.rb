# frozen_string_literal: true

require 'test_helper'

class StaffCostSnapshotTest < ActiveSupport::TestCase
  def valid_attrs
    {
      month: 2.months.ago.beginning_of_month,
      currency: 'EUR',
      support_cost_cents: 10000,
      staff_cost_cents: 50000,
      other_ops_cost_cents: 5000,
    }
  end

  test 'valid with required attributes' do
    snap = StaffCostSnapshot.new(valid_attrs)
    assert snap.valid?
  end

  test 'requires month' do
    snap = StaffCostSnapshot.new(valid_attrs.except(:month))
    assert_not snap.valid?
  end

  test 'requires valid currency' do
    snap = StaffCostSnapshot.new(valid_attrs.merge(currency: 'GBP'))
    assert_not snap.valid?
  end

  test 'unique on month + currency' do
    StaffCostSnapshot.where(month: valid_attrs[:month], currency: valid_attrs[:currency]).delete_all
    StaffCostSnapshot.create!(valid_attrs)
    dup = StaffCostSnapshot.new(valid_attrs)
    assert_not dup.valid?
  end

  test 'total_cost_cents sums all components' do
    snap = StaffCostSnapshot.new(
      support_cost_cents: 10000,
      staff_cost_cents: 50000,
      other_ops_cost_cents: 5000,
    )
    assert_equal 65000, snap.total_cost_cents
  end

  test 'total_cost_euros returns correct value' do
    snap = StaffCostSnapshot.new(
      support_cost_cents: 10000,
      staff_cost_cents: 50000,
      other_ops_cost_cents: 5000,
    )
    assert_equal 650.0, snap.total_cost_euros
  end
end
