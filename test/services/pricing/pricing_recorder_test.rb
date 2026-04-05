# frozen_string_literal: true

require 'test_helper'

class Pricing::PricingRecorderTest < ActiveSupport::TestCase
  setup do
    @plan         = plans(:pro)
    @user         = users(:one)
    @userplan     = userplans(:one)
    @super_admin  = users(:super_admin)
    @plain_user   = users(:one)
    @published_model = pricing_models(:legacy_v0)
  end

  # ---------------------------------------------------------------------------
  # record — no published model
  # ---------------------------------------------------------------------------

  test 'record without a published model still updates the plan' do
    PricingModel.where(status: PricingModel.statuses[:published]).update_all(status: PricingModel.statuses[:draft])

    result = Pricing::PricingRecorder.record(
      userplan: @userplan,
      plan: @plan,
      interval: 'month',
      currency: 'EUR',
    )

    assert result.success?
    assert_equal @plan.id, result.userplan.plan_id
  ensure
    PricingModel.where(version: 'legacy_v0').update_all(status: PricingModel.statuses[:published])
  end

  # ---------------------------------------------------------------------------
  # record — with published model + matching plan price
  # ---------------------------------------------------------------------------

  test 'record records pricing snapshot when plan price exists' do
    # Use the legacy_v0 model + legacy_pro_month fixture price record
    plan_price = pricing_model_plan_prices(:legacy_pro_month)

    result = Pricing::PricingRecorder.record(
      userplan: @userplan,
      plan: plan_price.plan,
      interval: plan_price.interval,
      currency: plan_price.currency,
    )

    assert result.success?, result.errors.inspect
    assert_equal @published_model.id, result.userplan.pricing_model_id
    assert_equal plan_price.price_cents, result.userplan.applied_price_cents
    assert_equal plan_price.currency, result.userplan.applied_currency
    assert_equal plan_price.interval, result.userplan.applied_interval
  end

  test 'record persists explicit stripe_price_id when provided' do
    plan_price = pricing_model_plan_prices(:legacy_pro_month)

    result = Pricing::PricingRecorder.record(
      userplan: @userplan,
      plan: plan_price.plan,
      interval: plan_price.interval,
      currency: plan_price.currency,
      stripe_price_id: 'price_explicit_test',
    )

    assert result.success?
    assert_equal 'price_explicit_test', result.userplan.applied_stripe_price_id
  end

  test 'record updates plan even when no matching plan price record exists' do
    # Use a plan+interval+currency combo with no PricingModelPlanPrice record
    result = Pricing::PricingRecorder.record(
      userplan: @userplan,
      plan: @plan,
      interval: 'year',
      currency: 'USD',
    )

    assert result.success?
    assert_equal @plan.id, result.userplan.plan_id
  end

  # ---------------------------------------------------------------------------
  # record_override
  # ---------------------------------------------------------------------------

  test 'record_override requires super_admin approver' do
    result = Pricing::PricingRecorder.record_override(
      userplan: @userplan,
      plan: @plan,
      approved_by: @plain_user,
      reason: 'Grandfathering legacy customer',
    )

    assert_not result.success?
    assert_includes result.errors.first, 'super_admin'
  end

  test 'record_override requires a non-blank reason' do
    result = Pricing::PricingRecorder.record_override(
      userplan: @userplan,
      plan: @plan,
      approved_by: @super_admin,
      reason: '   ',
    )

    assert_not result.success?
    assert_includes result.errors.first, 'reason is required'
  end

  test 'record_override sets pricing_override_keep_original_cohort and logs approver' do
    result = Pricing::PricingRecorder.record_override(
      userplan: @userplan,
      plan: @plan,
      approved_by: @super_admin,
      reason: 'Customer requested grandfathering',
    )

    assert result.success?, result.errors.inspect
    up = result.userplan
    assert up.pricing_override_keep_original_cohort
    assert_equal @super_admin.id, up.pricing_override_by_user_id
    assert_not_nil up.pricing_override_at
    assert_equal 'Customer requested grandfathering', up.pricing_override_reason
    assert_equal @plan.id, up.plan_id
  end
end
