# frozen_string_literal: true

module Admin
  # Admin-only actions on Userplan records.
  # Provides the pricing override endpoint that allows super_admin users
  # to approve a plan change while keeping a customer's original cohort pricing.
  class UserplansController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee, raise: false
    skip_before_action :set_permissions, raise: false
    skip_before_action :redirect_to_onboarding_if_needed, raise: false

    before_action :authenticate_user!
    before_action :require_super_admin!
    before_action :set_userplan

    # POST /admin/userplans/:id/pricing_override
    # Applies a plan change while preserving the customer's original cohort pricing.
    # Requires: plan_id, reason
    def pricing_override
      authorize @userplan, :pricing_override?

      plan = Plan.find_by(id: params[:plan_id])
      unless plan
        redirect_to admin_pricing_models_path, alert: 'Plan not found.'
        return
      end

      reason = params[:reason].to_s.strip
      if reason.blank?
        redirect_back_or_to(admin_pricing_models_path), alert: 'Override reason is required.'
        return
      end

      result = Pricing::PricingRecorder.record_override(
        userplan: @userplan,
        plan: plan,
        approved_by: current_user,
        reason: reason,
      )

      if result.success?
        @userplan.user&.update!(plan: plan)
        redirect_back_or_to(admin_pricing_models_path),
          notice: "Plan changed to #{plan.name} with original cohort pricing preserved."
      else
        redirect_back_or_to(admin_pricing_models_path), alert: result.errors.join(', ')
      end
    end

    private

    def set_userplan
      @userplan = Userplan.find(params[:id])
    end

    def require_super_admin!
      return if current_user&.admin? && current_user.super_admin?

      redirect_to root_path, alert: 'Access denied.', status: :see_other
    end
  end
end
