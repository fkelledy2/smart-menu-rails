# frozen_string_literal: true

module Pricing
  # Orchestrates the full publish workflow for a PricingModel:
  #   1. Compile plan prices (if not already done)
  #   2. Create Stripe Prices
  #   3. Lock the model as published
  #   4. Log the publish event
  #
  # The entire flow is wrapped in a database transaction.
  # If Stripe price creation fails, the publish rolls back.
  class ModelPublisher
    Result = Struct.new(:success, :pricing_model, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def self.publish(pricing_model:, published_by:, reason: nil)
      new(pricing_model: pricing_model, published_by: published_by, reason: reason).publish
    end

    def initialize(pricing_model:, published_by:, reason:)
      @model = pricing_model
      @published_by = published_by
      @reason = reason
    end

    def publish
      return Result.new(success: false, pricing_model: @model, errors: ['Model is not in draft status']) unless @model.draft?

      compile_result = Pricing::ModelCompiler.compile(pricing_model: @model)
      unless compile_result.success?
        return Result.new(success: false, pricing_model: @model, errors: compile_result.errors)
      end

      PricingModel.transaction do
        stripe_result = Pricing::StripePricePublisher.publish(pricing_model: @model)

        unless stripe_result.success?
          raise ActiveRecord::Rollback
        end

        @model.update!(
          status: :published,
          effective_from: Time.current,
          published_by_user_id: @published_by.id,
          published_at: Time.current,
          publish_reason: @reason,
        )

        Rails.logger.info(
          "[Pricing::ModelPublisher] Published pricing_model=#{@model.version} " \
          "by user_id=#{@published_by.id}",
        )
      end

      Result.new(success: true, pricing_model: @model.reload, errors: [])
    rescue ActiveRecord::Rollback
      Result.new(success: false, pricing_model: @model, errors: ['Stripe price creation failed — publish rolled back'])
    rescue StandardError => e
      Rails.logger.error("[Pricing::ModelPublisher] #{e.class}: #{e.message}")
      Result.new(success: false, pricing_model: @model, errors: [e.message])
    end
  end
end
