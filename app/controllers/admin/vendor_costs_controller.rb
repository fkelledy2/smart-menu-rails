# frozen_string_literal: true

module Admin
  class VendorCostsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee, raise: false
    skip_before_action :set_permissions, raise: false
    skip_before_action :redirect_to_onboarding_if_needed, raise: false

    before_action :authenticate_user!
    before_action :require_super_admin!
    before_action :set_cost, only: %i[edit update destroy]

    def index
      authorize ExternalServiceMonthlyCost, :index?

      @month    = selected_month
      @currency = params[:currency].presence || 'EUR'
      @costs    = policy_scope(ExternalServiceMonthlyCost)
        .for_month(@month)
        .for_currency(@currency)
        .order(:service)

      @services = ExternalServiceMonthlyCost::SERVICES
    end

    def new
      authorize ExternalServiceMonthlyCost, :create?
      @cost = ExternalServiceMonthlyCost.new(
        month: Date.current.beginning_of_month,
        currency: 'EUR',
        source: 'manual',
      )
    end

    def edit
      authorize @cost, :update?
    end

    def create
      authorize ExternalServiceMonthlyCost, :create?

      @cost = ExternalServiceMonthlyCost.new(cost_params)
      @cost.created_by_user_id = current_user.id

      if @cost.save
        redirect_to admin_vendor_costs_path, notice: 'Vendor cost entry saved.'
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      authorize @cost, :update?

      if @cost.update(cost_params)
        redirect_to admin_vendor_costs_path, notice: 'Vendor cost entry updated.'
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @cost, :destroy?
      @cost.destroy!
      redirect_to admin_vendor_costs_path, notice: 'Vendor cost entry deleted.'
    end

    private

    def set_cost
      @cost = ExternalServiceMonthlyCost.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_vendor_costs_path, alert: 'Vendor cost entry not found.', status: :see_other
    end

    def cost_params
      params.require(:external_service_monthly_cost).permit(
        :month, :service, :currency, :amount_cents, :source, :notes,
      )
    end

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
