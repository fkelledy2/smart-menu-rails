# frozen_string_literal: true

require 'test_helper'

class CostInsights::MarginEngineTest < ActiveSupport::TestCase
  setup do
    # Ensure we have at least one active plan with a known weight
    @plan = Plan.find_by(key: 'plan.pro.key') || plans(:pro)
    @plan.update_column(:weight_multiplier, 2.0) if @plan.persisted?
  end

  test 'compute returns a Result with plan_prices' do
    result = CostInsights::MarginEngine.compute(
      total_cost_cents: 100_000,
      target_margin_pct: 50.0,
    )

    assert_kind_of CostInsights::MarginEngine::Result, result
    assert result.plan_prices.any?
    assert result.required_revenue_cents > 100_000
  end

  test 'required revenue is correctly computed for 50% margin' do
    # total_cost / (1 - 0.5) = total_cost * 2
    result = CostInsights::MarginEngine.compute(
      total_cost_cents: 100_000,
      target_margin_pct: 50.0,
    )
    assert_equal 200_000, result.required_revenue_cents
  end

  test 'annual price is 10x monthly' do
    result = CostInsights::MarginEngine.compute(
      total_cost_cents: 100_000,
      target_margin_pct: 50.0,
    )
    result.plan_prices.each do |pp|
      assert_equal pp.monthly_price_cents * 10, pp.annual_price_cents
    end
  end

  test 'raises ArgumentError when weight sum is zero' do
    # Temporarily create a plan with zero weight
    assert_raises(ArgumentError) do
      CostInsights::MarginEngine.compute(
        total_cost_cents: 100_000,
        target_margin_pct: 50.0,
        plans: [Plan.new(weight_multiplier: 0)],
      )
    end
  end

  test 'higher weight multiplier results in higher plan price' do
    plan_low  = Plan.new(key: 'low', weight_multiplier: 1.0, status: :active)
    plan_high = Plan.new(key: 'high', weight_multiplier: 4.0, status: :active)

    result = CostInsights::MarginEngine.compute(
      total_cost_cents: 100_000,
      target_margin_pct: 50.0,
      plans: [plan_low, plan_high],
    )

    pp_low  = result.plan_prices.find { |p| p.plan_key == 'low' }
    pp_high = result.plan_prices.find { |p| p.plan_key == 'high' }

    assert pp_high.monthly_price_cents > pp_low.monthly_price_cents
  end
end
