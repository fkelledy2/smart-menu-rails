# frozen_string_literal: true

module Admin
  class MarginPoliciesController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee, raise: false
    skip_before_action :set_permissions, raise: false
    skip_before_action :redirect_to_onboarding_if_needed, raise: false

    before_action :authenticate_user!
    before_action :require_super_admin!
    before_action :set_policy_record, only: %i[edit update destroy activate deactivate]

    def index
      authorize ProfitMarginPolicy, :index?
      @policies = policy_scope(ProfitMarginPolicy).ordered
    end

    def new
      authorize ProfitMarginPolicy, :create?
      @policy = ProfitMarginPolicy.new(
        key: 'default',
        target_gross_margin_pct: 60,
        floor_gross_margin_pct: 40,
      )
    end

    def edit
      authorize @policy, :update?
    end

    def create
      authorize ProfitMarginPolicy, :create?

      @policy = ProfitMarginPolicy.new(policy_params)
      @policy.created_by_user_id = current_user.id

      if @policy.save
        redirect_to admin_margin_policies_path, notice: 'Margin policy created.'
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      authorize @policy, :update?

      if @policy.update(policy_params)
        redirect_to admin_margin_policies_path, notice: 'Margin policy updated.'
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @policy, :destroy?
      @policy.destroy!
      redirect_to admin_margin_policies_path, notice: 'Margin policy deleted.'
    end

    def activate
      authorize @policy, :update?
      @policy.update!(status: :active)
      redirect_to admin_margin_policies_path, notice: "#{@policy.key} activated."
    end

    def deactivate
      authorize @policy, :update?
      @policy.update!(status: :inactive)
      redirect_to admin_margin_policies_path, notice: "#{@policy.key} deactivated."
    end

    private

    def set_policy_record
      @policy = ProfitMarginPolicy.find(params[:id])
    end

    def policy_params
      params.require(:profit_margin_policy).permit(
        :key, :target_gross_margin_pct, :floor_gross_margin_pct, :status,
      )
    end

    def require_super_admin!
      return if current_user&.admin? && current_user.super_admin?

      redirect_to root_path, alert: 'Access denied.', status: :see_other
    end
  end
end
