# frozen_string_literal: true

module Pricing
  # Records the pricing snapshot on a Userplan when a subscription begins or changes.
  #
  # For new signups: resolves the current published pricing model and records
  # the price, currency, interval, and Stripe price ID against the Userplan.
  #
  # For plan changes: by default uses the current published model. Admin/super_admin
  # can pass override_keep_original_cohort: true to preserve the original cohort
  # pricing, which is logged with approver and reason.
  class PricingRecorder
    Result = Struct.new(:success, :userplan, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    # Records pricing from the current published model onto a Userplan.
    #
    # @param userplan [Userplan]
    # @param plan [Plan]
    # @param interval [String] 'month' or 'year'
    # @param currency [String] 'EUR' or 'USD'
    # @param stripe_price_id [String, nil] explicit Stripe price ID (from checkout session)
    # @return [Result]
    def self.record(userplan:, plan:, interval:, currency:, stripe_price_id: nil)
      new(
        userplan: userplan,
        plan: plan,
        interval: interval,
        currency: currency,
        stripe_price_id: stripe_price_id,
      ).record
    end

    # Records an admin-approved override that keeps the original cohort pricing.
    #
    # @param userplan [Userplan]
    # @param plan [Plan]
    # @param approved_by [User]
    # @param reason [String]
    # @return [Result]
    def self.record_override(userplan:, plan:, approved_by:, reason:)
      new(userplan: userplan, plan: plan).record_override(
        approved_by: approved_by,
        reason: reason,
      )
    end

    def initialize(userplan:, plan:, interval: 'month', currency: 'EUR', stripe_price_id: nil)
      @userplan        = userplan
      @plan            = plan
      @interval        = interval
      @currency        = currency
      @stripe_price_id = stripe_price_id
    end

    def record
      model = Pricing::ModelResolver.current

      unless model
        # No published pricing model — record plan change without pricing snapshot.
        # This is valid when cost_indexed_pricing flag is off or no model has been published.
        @userplan.update!(plan: @plan)
        return Result.new(success: true, userplan: @userplan, errors: [])
      end

      plan_price = model.price_for(plan: @plan, interval: @interval, currency: @currency)

      attrs = {
        plan: @plan,
        pricing_model: model,
      }

      if plan_price
        attrs[:applied_price_cents]    = plan_price.price_cents
        attrs[:applied_currency]       = plan_price.currency
        attrs[:applied_interval]       = plan_price.interval
        attrs[:applied_stripe_price_id] = @stripe_price_id.presence || plan_price.stripe_price_id
      elsif @stripe_price_id.present?
        # Stripe price ID available from checkout but no matching plan price record.
        # This can happen if the model was published then the plan price was deleted.
        attrs[:applied_stripe_price_id] = @stripe_price_id
      end

      @userplan.update!(attrs)

      Result.new(success: true, userplan: @userplan.reload, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[Pricing::PricingRecorder] record failed: #{e.message}")
      Result.new(success: false, userplan: @userplan, errors: [e.message])
    end

    def record_override(approved_by:, reason:)
      unless approved_by.admin? && approved_by.super_admin?
        return Result.new(
          success: false,
          userplan: @userplan,
          errors: ['Only super_admin users can approve pricing overrides'],
        )
      end

      if reason.to_s.strip.blank?
        return Result.new(
          success: false,
          userplan: @userplan,
          errors: ['Override reason is required'],
        )
      end

      @userplan.update!(
        plan: @plan,
        pricing_override_keep_original_cohort: true,
        pricing_override_by_user_id: approved_by.id,
        pricing_override_at: Time.current,
        pricing_override_reason: reason,
      )

      Rails.logger.info(
        "[Pricing::PricingRecorder] Override approved: userplan_id=#{@userplan.id} " \
        "plan_id=#{@plan.id} approved_by=#{approved_by.id} reason=#{reason.truncate(100)}",
      )

      Result.new(success: true, userplan: @userplan.reload, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[Pricing::PricingRecorder] record_override failed: #{e.message}")
      Result.new(success: false, userplan: @userplan, errors: [e.message])
    end
  end
end
