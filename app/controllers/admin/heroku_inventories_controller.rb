# frozen_string_literal: true

module Admin
  class HerokuInventoriesController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee, raise: false
    skip_before_action :set_permissions, raise: false
    skip_before_action :redirect_to_onboarding_if_needed, raise: false

    before_action :authenticate_user!
    before_action :require_super_admin!

    SPACE_NAME = 'smart-menu'

    # GET /admin/heroku_inventories
    def index
      authorize :heroku_inventory, :index?

      @snapshots = policy_scope(HerokuAppInventorySnapshot)
        .for_space(SPACE_NAME)
        .latest_per_app
        .order(:environment, :app_name)

      @cost_snapshots = InfraCostSnapshot
        .for_space(SPACE_NAME)
        .order(month: :desc, environment: :asc)
        .limit(20)

      @mock_mode = Heroku::PlatformClient.new.mock_mode?
    end

    # GET /admin/heroku_inventories/coefficients
    def coefficients
      authorize :heroku_inventory, :coefficients?

      @dyno_costs = HerokuDynoSizeCost.ordered
      @addon_costs = HerokuAddonPlanCost.ordered
    end

    # PATCH /admin/heroku_inventories/coefficients
    def update_coefficients
      authorize :heroku_inventory, :update_coefficients?

      errors = []

      Array(params[:dyno_costs]).each do |id, attrs|
        record = HerokuDynoSizeCost.find_by(id: id)
        next unless record

        record.update(cost_cents_per_month: attrs[:cost_cents_per_month].to_i) || (errors << record.errors.full_messages)
      end

      Array(params[:addon_costs]).each do |id, attrs|
        record = HerokuAddonPlanCost.find_by(id: id)
        next unless record

        record.update(cost_cents_per_month: attrs[:cost_cents_per_month].to_i) || (errors << record.errors.full_messages)
      end

      if errors.empty?
        redirect_to coefficients_admin_heroku_inventories_path, notice: 'Coefficients updated.'
      else
        @dyno_costs = HerokuDynoSizeCost.ordered
        @addon_costs = HerokuAddonPlanCost.ordered
        flash.now[:alert] = "Some updates failed: #{errors.flatten.join(', ')}"
        render :coefficients, status: :unprocessable_content
      end
    end

    # POST /admin/heroku_inventories/trigger_snapshot
    def trigger_snapshot
      authorize :heroku_inventory, :trigger_snapshot?

      HerokuInventorySnapshotJob.perform_later(space_name: SPACE_NAME)
      redirect_to admin_heroku_inventories_path, notice: 'Inventory snapshot job enqueued.'
    end

    # POST /admin/heroku_inventories/trigger_rollup
    def trigger_rollup
      authorize :heroku_inventory, :trigger_rollup?

      month = params[:month].present? ? Date.parse(params[:month]) : Date.current
      HerokuMonthlyCostRollupJob.perform_later(
        month: month.beginning_of_month.to_s,
        created_by_user_id: current_user.id,
      )
      redirect_to admin_heroku_inventories_path, notice: "Cost rollup job enqueued for #{month.strftime('%B %Y')}."
    rescue Date::Error
      redirect_to admin_heroku_inventories_path, alert: 'Invalid month parameter.'
    end

    private

    def require_super_admin!
      return if current_user&.admin? && current_user.super_admin?

      redirect_to root_path, alert: 'Access denied. Super admin privileges required.', status: :see_other
    end
  end
end
