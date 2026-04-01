# frozen_string_literal: true

require 'test_helper'

class PricingModelTest < ActiveSupport::TestCase
  test 'valid with required attributes' do
    model = PricingModel.new(version: 'test_v1', currency: 'EUR', status: :draft)
    assert model.valid?
  end

  test 'requires unique version' do
    PricingModel.create!(version: 'unique_v1', currency: 'EUR', status: :draft)
    dup = PricingModel.new(version: 'unique_v1', currency: 'EUR', status: :draft)
    assert_not dup.valid?
  end

  test 'requires valid currency' do
    model = PricingModel.new(version: 'test_v2', currency: 'GBP', status: :draft)
    assert_not model.valid?
  end

  test 'immutable? returns true for published' do
    model = PricingModel.new(status: :published)
    assert model.immutable?
  end

  test 'immutable? returns true for retired' do
    model = PricingModel.new(status: :retired)
    assert model.immutable?
  end

  test 'immutable? returns false for draft' do
    model = PricingModel.new(status: :draft)
    assert_not model.immutable?
  end

  test 'current returns the most recently published model by effective_from' do
    PricingModel.where(status: :published).update_all(status: :retired)
    PricingModel.create!(
      version: 'old_v1', currency: 'EUR', status: :published,
      effective_from: 2.months.ago,
    )
    newer = PricingModel.create!(
      version: 'new_v1', currency: 'EUR', status: :published,
      effective_from: 1.month.ago,
    )
    assert_equal newer, PricingModel.current
  end

  test 'legacy_sentinel returns the legacy_v0 model' do
    legacy = pricing_models(:legacy_v0)
    assert_equal legacy, PricingModel.legacy_sentinel
  end

  test 'price_for returns correct plan price' do
    model = pricing_models(:legacy_v0)
    plan  = plans(:pro)
    price = model.price_for(plan: plan, interval: 'month', currency: 'EUR')
    assert_not_nil price
    assert_equal 4999, price.price_cents
  end
end
