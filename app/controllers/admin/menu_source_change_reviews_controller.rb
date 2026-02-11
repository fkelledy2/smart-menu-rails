module Admin
  class MenuSourceChangeReviewsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :ensure_admin!
    before_action :require_super_admin!

    before_action :set_review, only: %i[show resolve ignore]

    def index
      scope = MenuSourceChangeReview.includes(menu_source: %i[restaurant discovered_restaurant]).order(detected_at: :desc, id: :desc)

      status = params[:status].to_s.presence
      if status.present? && MenuSourceChangeReview.statuses.key?(status)
        scope = scope.where(status: MenuSourceChangeReview.statuses[status])
      end

      @status = status
      @reviews = scope.limit(500)
    end

    def show
    end

    def resolve
      @review.update!(status: :resolved)
      redirect_back_or_to(admin_menu_source_change_reviews_path, notice: 'Resolved', status: :see_other)
    end

    def ignore
      @review.update!(status: :ignored)
      redirect_back_or_to(admin_menu_source_change_reviews_path, notice: 'Ignored', status: :see_other)
    end

    private

    def set_review
      @review = MenuSourceChangeReview.find(params[:id])
    end

    def ensure_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: 'Access denied. Admin privileges required.'
      end
    end

    def require_super_admin!
      return if current_user&.admin? && current_user&.super_admin?

      redirect_to root_path, alert: 'Access denied. Super admin privileges required.'
    end
  end
end
