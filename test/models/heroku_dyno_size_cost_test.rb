# frozen_string_literal: true

require 'test_helper'

class HerokuDynoSizeCostTest < ActiveSupport::TestCase
  test 'valid with required attributes' do
    cost = HerokuDynoSizeCost.new(dyno_size: 'performance-m', cost_cents_per_month: 25000)
    assert cost.valid?
  end

  test 'requires dyno_size' do
    cost = HerokuDynoSizeCost.new(cost_cents_per_month: 5000)
    assert_not cost.valid?
    assert_includes cost.errors[:dyno_size], "can't be blank"
  end

  test 'requires unique dyno_size' do
    # standard-2x already exists via fixtures
    duplicate = HerokuDynoSizeCost.new(dyno_size: 'standard-2x', cost_cents_per_month: 9999)
    assert_not duplicate.valid?
  end

  test 'cost_cents_per_month must be non-negative' do
    cost = HerokuDynoSizeCost.new(dyno_size: 'test-size', cost_cents_per_month: -1)
    assert_not cost.valid?
  end

  test 'cost_euros returns cents / 100' do
    cost = HerokuDynoSizeCost.new(cost_cents_per_month: 5000)
    assert_equal 50.0, cost.cost_euros
  end

  test 'ordered scope returns by dyno_size' do
    HerokuDynoSizeCost.delete_all
    HerokuDynoSizeCost.create!(dyno_size: 'standard-2x', cost_cents_per_month: 5000)
    HerokuDynoSizeCost.create!(dyno_size: 'eco', cost_cents_per_month: 500)
    result = HerokuDynoSizeCost.ordered.map(&:dyno_size)
    assert_equal %w[eco standard-2x], result
  end
end
