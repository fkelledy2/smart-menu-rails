# frozen_string_literal: true

require 'test_helper'

class Pricing::ModelPublisherTest < ActiveSupport::TestCase
  setup do
    @user = users(:super_admin)
    @model = PricingModel.create!(
      version: "pub_test_#{SecureRandom.hex(4)}",
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
    @model.destroy! if @model.persisted?
  end

  test 'returns failure result when model is not in draft status' do
    @model.update_column(:status, 1) # published

    result = Pricing::ModelPublisher.publish(
      pricing_model: @model,
      published_by: @user,
    )

    assert_not result.success?
    assert_includes result.errors.first, 'draft'
  end

  test 'returns failure result when inputs are invalid' do
    @model.update_column(:inputs_json, {})

    result = Pricing::ModelPublisher.publish(
      pricing_model: @model,
      published_by: @user,
    )

    assert_not result.success?
    assert result.errors.any?
  end

  test 'publish method requires draft status — published model is rejected immediately' do
    # Ensure the model is already published
    @model.update_columns(
      status: 1,
      published_by_user_id: @user.id,
      published_at: Time.current,
      effective_from: Time.current,
    )

    result = Pricing::ModelPublisher.publish(
      pricing_model: @model,
      published_by: @user,
    )

    assert_not result.success?
    assert_includes result.errors.first, 'draft'
  end

  test 'accepts an optional reason parameter' do
    result = Pricing::ModelPublisher.publish(
      pricing_model: @model,
      published_by: @user,
      reason: nil,
    )
    # Even if Stripe fails, the result struct should always have an errors array.
    assert_respond_to result, :errors
  end

  test 'result struct responds to success? method' do
    result = Pricing::ModelPublisher.publish(
      pricing_model: @model,
      published_by: @user,
    )
    assert_respond_to result, :success?
  end
end
