# frozen_string_literal: true

module Pricing
  # Creates the legacy_v0 sentinel PricingModel and backfills all existing
  # Userplan records to it. This ensures audit trails are complete
  # when the cost-indexed pricing system is activated.
  #
  # Safe to run multiple times — idempotent.
  class LegacyBackfillService
    Result = Struct.new(:created, :updated_count, :errors, keyword_init: true) do
      def success?
        errors.empty?
      end
    end

    def self.run
      new.run
    end

    def run
      legacy = find_or_create_legacy_sentinel
      return Result.new(created: false, updated_count: 0, errors: [legacy.errors.full_messages]) unless legacy.persisted?

      count = Userplan.where(pricing_model_id: nil).update_all(pricing_model_id: legacy.id)

      Rails.logger.info("[Pricing::LegacyBackfillService] Backfilled #{count} Userplan records to legacy_v0")

      Result.new(created: legacy.previously_new_record?, updated_count: count, errors: [])
    rescue StandardError => e
      Rails.logger.error("[Pricing::LegacyBackfillService] #{e.class}: #{e.message}")
      Result.new(created: false, updated_count: 0, errors: [e.message])
    end

    private

    def find_or_create_legacy_sentinel
      PricingModel.find_or_create_by(version: PricingModel::LEGACY_VERSION) do |pm|
        pm.status       = :published
        pm.currency     = 'EUR'
        pm.effective_from = Time.zone.at(0) # epoch — before any real customers
        pm.inputs_json  = { note: 'Legacy sentinel — pre-cost-indexed pricing' }
        pm.outputs_json = {}
      end
    end
  end
end
