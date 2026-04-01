# frozen_string_literal: true

module Pricing
  # Resolves the current active pricing model and looks up plan prices.
  class ModelResolver
    # Returns the most recently published PricingModel, or nil if none exists.
    def self.current
      PricingModel.current
    end

    # Resolves the price for a plan+interval+currency combination
    # from the current pricing model. Returns nil if not found.
    #
    # @param plan [Plan]
    # @param interval [String] 'month' or 'year'
    # @param currency [String] 'EUR' or 'USD'
    # @return [PricingModelPlanPrice, nil]
    def self.resolve_price(plan:, interval:, currency:)
      model = current
      return nil unless model

      model.price_for(plan: plan, interval: interval, currency: currency)
    end

    # Infers the billing currency from a restaurant's country.
    # Defaults to EUR.
    def self.currency_for_restaurant(restaurant)
      country = restaurant.try(:country).to_s.upcase
      CountryCurrencyInference.call(country) || 'EUR'
    end
  end
end
