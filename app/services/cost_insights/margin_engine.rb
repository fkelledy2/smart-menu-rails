# frozen_string_literal: true

module CostInsights
  # Computes required revenue and plan prices from total cost + margin target + plan weights.
  #
  # Algorithm:
  #   total_required_revenue = total_cost / (1 - target_margin_pct / 100)
  #   per_weight_unit_revenue = total_required_revenue / sum_of_all_weight_units
  #   plan_price = per_weight_unit_revenue * plan.weight_multiplier
  #
  # Annual pricing: monthly × 10 (2 months free)
  # Decision: plan weights are manual multiplier coefficients per Plan record (weight_multiplier column).
  class MarginEngine
    ANNUAL_FACTOR = 10 # annual = monthly × 10 (2 months free)

    Result = Struct.new(
      :plan_prices,
      :required_revenue_cents,
      :per_weight_unit_cents,
      :total_cost_cents,
      :target_margin_pct,
      keyword_init: true,
    )

    PlanPrice = Struct.new(
      :plan_id,
      :plan_key,
      :plan_name,
      :weight_multiplier,
      :monthly_price_cents,
      :annual_price_cents,
      keyword_init: true,
    )

    def self.compute(total_cost_cents:, target_margin_pct:, plans: nil, currency: 'EUR')
      new(
        total_cost_cents: total_cost_cents,
        target_margin_pct: target_margin_pct,
        plans: plans,
        currency: currency,
      ).compute
    end

    def initialize(total_cost_cents:, target_margin_pct:, plans: nil, currency: 'EUR')
      @total_cost_cents  = total_cost_cents.to_i
      @target_margin_pct = target_margin_pct.to_f
      @plans = plans || Plan.active.display_order.to_a
      @currency = currency
    end

    def compute
      required_revenue = (@total_cost_cents / (1.0 - (@target_margin_pct / 100.0))).ceil
      weight_sum = @plans.sum { |p| p.weight_multiplier.to_f }

      if weight_sum.zero?
        raise ArgumentError, 'Sum of plan weight multipliers must be greater than zero'
      end

      per_weight_unit = (required_revenue / weight_sum).ceil

      plan_prices = @plans.map do |plan|
        monthly = (per_weight_unit * plan.weight_multiplier.to_f).ceil
        annual  = monthly * ANNUAL_FACTOR

        PlanPrice.new(
          plan_id: plan.id,
          plan_key: plan.key,
          plan_name: plan.name,
          weight_multiplier: plan.weight_multiplier.to_f,
          monthly_price_cents: monthly,
          annual_price_cents: annual,
        )
      end

      Result.new(
        plan_prices: plan_prices,
        required_revenue_cents: required_revenue,
        per_weight_unit_cents: per_weight_unit,
        total_cost_cents: @total_cost_cents,
        target_margin_pct: @target_margin_pct,
      )
    end
  end
end
