# frozen_string_literal: true

module Admin
  class StaffCostsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee, raise: false
    skip_before_action :set_permissions, raise: false
    skip_before_action :redirect_to_onboarding_if_needed, raise: false

    before_action :authenticate_user!
    before_action :require_super_admin!
    before_action :set_snapshot, only: %i[edit update destroy]

    def index
      authorize StaffCostSnapshot, :index?

      @snapshots = policy_scope(StaffCostSnapshot).recent.limit(24)
    end

    def new
      authorize StaffCostSnapshot, :create?
      @snapshot = StaffCostSnapshot.new(
        month: Date.current.beginning_of_month,
        currency: 'EUR',
      )
    end

    def edit
      authorize @snapshot, :update?
    end

    def create
      authorize StaffCostSnapshot, :create?

      @snapshot = StaffCostSnapshot.new(snapshot_params)
      @snapshot.created_by_user_id = current_user.id

      if @snapshot.save
        redirect_to admin_staff_costs_path, notice: 'Staff cost snapshot saved.'
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      authorize @snapshot, :update?

      if @snapshot.update(snapshot_params)
        redirect_to admin_staff_costs_path, notice: 'Staff cost snapshot updated.'
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @snapshot, :destroy?
      @snapshot.destroy!
      redirect_to admin_staff_costs_path, notice: 'Staff cost snapshot deleted.'
    end

    private

    def set_snapshot
      @snapshot = StaffCostSnapshot.find(params[:id])
    end

    def snapshot_params
      params.require(:staff_cost_snapshot).permit(
        :month, :currency, :support_cost_cents, :staff_cost_cents,
        :other_ops_cost_cents, :notes,
      )
    end

    def require_super_admin!
      return if current_user&.admin? && current_user.super_admin?

      redirect_to root_path, alert: 'Access denied.', status: :see_other
    end
  end
end
