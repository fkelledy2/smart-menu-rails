module Admin
  class RestaurantRemovalRequestsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :ensure_admin!
    before_action :require_super_admin!

    before_action :set_request, only: %i[show action_unpublish resolve]

    def index
      scope = RestaurantRemovalRequest.includes(:restaurant, :actioned_by_user).order(created_at: :desc)

      status = params[:status].to_s.presence
      if status.present? && RestaurantRemovalRequest.statuses.key?(status)
        scope = scope.where(status: RestaurantRemovalRequest.statuses[status])
      end

      @status = status
      @removal_requests = scope.limit(200)
    end

    def show; end

    def action_unpublish
      @removal_request.action_unpublish!(user: current_user)
      redirect_back_or_to(admin_restaurant_removal_requests_path, notice: 'Unpublished and actioned', status: :see_other)
    rescue StandardError => e
      redirect_back_or_to(admin_restaurant_removal_requests_path, alert: "Failed: #{e.message}", status: :see_other)
    end

    def resolve
      @removal_request.update!(status: :resolved, actioned_at: Time.current, actioned_by_user: current_user)
      redirect_back_or_to(admin_restaurant_removal_requests_path, notice: 'Resolved', status: :see_other)
    end

    private

    def set_request
      @removal_request = RestaurantRemovalRequest.find(params[:id])
    end

    def ensure_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: 'Access denied. Admin privileges required.'
      end
    end

    def require_super_admin!
      return if current_user&.admin? && current_user.super_admin?

      redirect_to root_path, alert: 'Access denied. Super admin privileges required.'
    end
  end
end
