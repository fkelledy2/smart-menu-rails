module Admin
  class RestaurantClaimRequestsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :ensure_admin!
    before_action :require_super_admin!

    before_action :set_claim_request, only: %i[show approve reject]

    def index
      scope = RestaurantClaimRequest.includes(:restaurant, :initiated_by_user).order(created_at: :desc)

      status = params[:status].to_s.presence
      if status.present? && RestaurantClaimRequest.statuses.key?(status)
        scope = scope.where(status: RestaurantClaimRequest.statuses[status])
      end

      @status = status
      @claim_requests = scope.limit(200)
    end

    def show; end

    def approve
      @claim_request.approve!(reviewer: current_user)
      redirect_back_or_to(admin_restaurant_claim_requests_path, notice: 'Claim approved — restaurant is now soft-claimed', status: :see_other)
    rescue StandardError => e
      redirect_back_or_to(admin_restaurant_claim_requests_path, alert: "Failed: #{e.message}", status: :see_other)
    end

    def reject
      @claim_request.reject!(reviewer: current_user, notes: params[:review_notes])
      redirect_back_or_to(admin_restaurant_claim_requests_path, notice: 'Claim rejected', status: :see_other)
    end

    private

    def set_claim_request
      @claim_request = RestaurantClaimRequest.find(params[:id])
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
