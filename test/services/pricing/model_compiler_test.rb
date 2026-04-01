# frozen_string_literal: true

require 'test_helper'

class Pricing::ModelCompilerTest < ActiveSupport::TestCase
  setup do
    @model = PricingModel.create!(
      version: "test_compiler_#{SecureRandom.hex(4)}",
      currency: 'EUR',
      status: :draft,
      inputs_json: {
        'total_cost_cents' => 500_000,
        'target_gross_margin_pct' => 60,
        'currency' => 'EUR',
      },
    )
  end

  teardown do
    @model.pricing_model_plan_prices.delete_all
    @model.destroy!
  end

  test 'compile creates PricingModelPlanPrice records' do
    Plan.active.any? || skip('No active plans in test database')

    result = Pricing::ModelCompiler.compile(pricing_model: @model)

    if Plan.active.none?
      skip 'No active plans'
    end

    assert result.success?, result.errors.inspect
    assert result.plan_prices.any?
  end

  test 'compile fails for published model' do
    @model.update_column(:status, 1) # published

    result = Pricing::ModelCompiler.compile(pricing_model: @model)
    assert_not result.success?
    assert_includes result.errors.first, 'draft status'
  end

  test 'compile fails with missing inputs' do
    @model.update_column(:inputs_json, {})

    result = Pricing::ModelCompiler.compile(pricing_model: @model)
    assert_not result.success?
    assert result.errors.any?
  end

  test 'compile fails with zero cost' do
    @model.update_column(:inputs_json, {
      'total_cost_cents' => 0,
      'target_gross_margin_pct' => 60,
      'currency' => 'EUR',
    })

    result = Pricing::ModelCompiler.compile(pricing_model: @model)
    assert_not result.success?
  end

  test 'compile fails with out of range margin' do
    @model.update_column(:inputs_json, {
      'total_cost_cents' => 100_000,
      'target_gross_margin_pct' => 101,
      'currency' => 'EUR',
    })

    result = Pricing::ModelCompiler.compile(pricing_model: @model)
    assert_not result.success?
  end
end
