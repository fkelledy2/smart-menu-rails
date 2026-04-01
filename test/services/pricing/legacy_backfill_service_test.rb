# frozen_string_literal: true

require 'test_helper'

class Pricing::LegacyBackfillServiceTest < ActiveSupport::TestCase
  test 'creates legacy_v0 sentinel if not present' do
    # Remove FK children first, then delete the sentinel
    legacy = PricingModel.find_by(version: 'legacy_v0')
    if legacy
      PricingModelPlanPrice.where(pricing_model_id: legacy.id).delete_all
      Userplan.where(pricing_model_id: legacy.id).update_all(pricing_model_id: nil)
      legacy.delete
    end

    result = Pricing::LegacyBackfillService.run

    assert result.success?
    assert PricingModel.find_by(version: 'legacy_v0').present?
  end

  test 'is idempotent — does not create duplicates' do
    Pricing::LegacyBackfillService.run
    count_before = PricingModel.where(version: 'legacy_v0').count

    Pricing::LegacyBackfillService.run
    count_after = PricingModel.where(version: 'legacy_v0').count

    assert_equal count_before, count_after
    assert_equal 1, count_after
  end

  test 'backfills userplans without pricing_model_id' do
    legacy = PricingModel.find_or_create_by!(version: 'legacy_v0') do |pm|
      pm.status    = :published
      pm.currency  = 'EUR'
      pm.effective_from = Time.zone.at(0)
      pm.inputs_json = {}
      pm.outputs_json = {}
    end

    userplan = Userplan.first
    userplan&.update_column(:pricing_model_id, nil)

    result = Pricing::LegacyBackfillService.run
    assert result.success?
    assert_equal legacy.id, userplan&.reload&.pricing_model_id
  end
end
