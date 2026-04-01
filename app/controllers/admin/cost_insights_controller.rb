# frozen_string_literal: true

module Admin
  # Dashboard: unified view of Heroku + vendor + staff costs for a month.
  class CostInsightsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee, raise: false
    skip_before_action :set_permissions, raise: false
    skip_before_action :redirect_to_onboarding_if_needed, raise: false

    before_action :authenticate_user!
    before_action :require_super_admin!

    def index
      authorize :cost_insights, :index?

      @month    = selected_month
      @currency = params[:currency].presence || 'EUR'
      @totals   = CostInsights::TotalCalculator.calculate(month: @month, currency: @currency)
      @margin_policy = ProfitMarginPolicy.current
    end

    def trigger_monthly_rollup
      authorize :cost_insights, :trigger_rollup?

      month = params[:month].present? ? Date.parse(params[:month]) : Date.current
      MonthlyCostRollupJob.perform_later(month: month.beginning_of_month.to_s)
      redirect_to admin_cost_insights_path, notice: "Monthly cost rollup enqueued for #{month.strftime('%B %Y')}."
    rescue Date::Error
      redirect_to admin_cost_insights_path, alert: 'Invalid month parameter.'
    end

    private

    def selected_month
      if params[:month].present?
        Date.parse(params[:month]).beginning_of_month
      else
        Date.current.beginning_of_month
      end
    rescue Date::Error
      Date.current.beginning_of_month
    end

    def require_super_admin!
      return if current_user&.admin? && current_user.super_admin?

      redirect_to root_path, alert: 'Access denied.', status: :see_other
    end
  end
end
