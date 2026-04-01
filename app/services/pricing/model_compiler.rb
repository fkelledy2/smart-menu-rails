# frozen_string_literal: true

module Pricing
  # Validates cost inputs, computes plan prices deterministically,
  # and writes PricingModelPlanPrice records for a PricingModel.
  class ModelCompiler
    Result = Struct.new(:success, :plan_prices, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    REQUIRED_INPUTS = %w[total_cost_cents target_gross_margin_pct currency].freeze

    def self.compile(pricing_model:)
      new(pricing_model: pricing_model).compile
    end

    def initialize(pricing_model:)
      @model = pricing_model
    end

    def compile
      return Result.new(success: false, plan_prices: [], errors: ['PricingModel must be in draft status']) unless @model.draft?

      errors = validate_inputs
      return Result.new(success: false, plan_prices: [], errors: errors) if errors.any?

      inputs = @model.inputs
      total_cost_cents = inputs['total_cost_cents'].to_i
      target_margin    = inputs['target_gross_margin_pct'].to_f
      currency         = inputs['currency'] || @model.currency

      margin_result = CostInsights::MarginEngine.compute(
        total_cost_cents: total_cost_cents,
        target_margin_pct: target_margin,
        currency: currency,
      )

      saved_prices = []
      save_errors  = []

      PricingModelPlanPrice.transaction do
        @model.pricing_model_plan_prices.delete_all

        margin_result.plan_prices.each do |pp|
          [
            { interval: 'month', price_cents: pp.monthly_price_cents },
            { interval: 'year', price_cents: pp.annual_price_cents },
          ].each do |combo|
            record = PricingModelPlanPrice.create(
              pricing_model: @model,
              plan_id: pp.plan_id,
              interval: combo[:interval],
              price_cents: combo[:price_cents],
              currency: currency,
            )

            if record.persisted?
              saved_prices << record
            else
              save_errors << record.errors.full_messages
            end
          end
        end

        raise ActiveRecord::Rollback if save_errors.any?
      end

      return Result.new(success: false, plan_prices: [], errors: save_errors.flatten) if save_errors.any?

      # Store computed outputs on the model
      @model.update!(outputs_json: {
        required_revenue_cents: margin_result.required_revenue_cents,
        per_weight_unit_cents: margin_result.per_weight_unit_cents,
        plan_prices: margin_result.plan_prices.map do |pp|
          {
            plan_id: pp.plan_id,
            plan_key: pp.plan_key,
            monthly_price_cents: pp.monthly_price_cents,
            annual_price_cents: pp.annual_price_cents,
          }
        end,
      })

      Result.new(success: true, plan_prices: saved_prices, errors: [])
    end

    private

    def validate_inputs
      errors = []
      inputs = @model.inputs

      REQUIRED_INPUTS.each do |key|
        errors << "inputs.#{key} is required" if inputs[key].blank?
      end

      if (margin = inputs['target_gross_margin_pct'].to_f).positive? && (1..99).exclude?(margin)
        errors << 'target_gross_margin_pct must be between 1 and 99'
      end

      if inputs['total_cost_cents'].to_i <= 0
        errors << 'total_cost_cents must be greater than 0'
      end

      errors
    end
  end
end
