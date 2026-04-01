# frozen_string_literal: true

module Pricing
  # Creates Stripe Price objects for each PricingModelPlanPrice in a pricing model.
  # Must be called within the publish transaction — rolls back if any Price fails.
  class StripePricePublisher
    Result = Struct.new(:success, :stripe_price_ids, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def self.publish(pricing_model:)
      new(pricing_model: pricing_model).publish
    end

    def initialize(pricing_model:)
      @model = pricing_model
    end

    def publish
      errors = []
      stripe_price_ids = {}

      @model.pricing_model_plan_prices.includes(:plan).find_each do |pmpp|
        stripe_price = create_stripe_price(pmpp)

        if stripe_price
          stripe_price_ids[pmpp.id] = stripe_price.id
          pmpp.update_column(:stripe_price_id, stripe_price.id)
        else
          errors << "Failed to create Stripe price for plan=#{pmpp.plan.key} interval=#{pmpp.interval} currency=#{pmpp.currency}"
        end
      rescue Stripe::StripeError => e
        errors << "Stripe error for plan=#{pmpp.plan.key}: #{e.message}"
      end

      if errors.any?
        # Attempt cleanup of any prices already created
        stripe_price_ids.each_value do |price_id|
          Stripe::Price.update(price_id, active: false)
        rescue StandardError
          nil
        end
        return Result.new(success: false, stripe_price_ids: {}, errors: errors)
      end

      Result.new(success: true, stripe_price_ids: stripe_price_ids, errors: [])
    end

    private

    def create_stripe_price(pmpp)
      # Stripe requires an amount in the smallest currency unit
      currency = pmpp.currency.downcase

      params = {
        currency: currency,
        unit_amount: pmpp.price_cents,
        recurring: {
          interval: pmpp.interval == 'year' ? 'year' : 'month',
        },
        metadata: {
          pricing_model_version: @model.version,
          plan_key: pmpp.plan.key,
          pricing_model_plan_price_id: pmpp.id.to_s,
        },
      }

      # Find or create a Product for the plan
      product_id = find_or_create_stripe_product(pmpp.plan, pmpp.currency)
      params[:product] = product_id if product_id

      Stripe::Price.create(params)
    end

    def find_or_create_stripe_product(plan, currency)
      # If the plan already has a Stripe product ID, reuse it.
      # Otherwise create a new product.
      existing_price_id = plan.stripe_price_id_month
      if existing_price_id.present?
        existing = begin
          Stripe::Price.retrieve(existing_price_id)
        rescue StandardError
          nil
        end
        return existing.product if existing
      end

      product = Stripe::Product.create(
        name: "mellow.menu #{plan.name} (#{currency})",
        metadata: { plan_key: plan.key, pricing_model: 'cost_indexed' },
      )

      product.id
    rescue Stripe::StripeError
      nil
    end
  end
end
