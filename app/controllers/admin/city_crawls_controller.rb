module Admin
  class CityCrawlsController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :ensure_admin!
    before_action :require_super_admin!

    def new; end

    def create
      city_query = params[:city_query].to_s
      place_types = Array(params[:place_types])

      if city_query.strip.blank?
        redirect_back_or_to(new_admin_city_crawl_path, alert: 'City is required', status: :see_other)
        return
      end

      begin
        job = CityDiscoveryJob.perform_later(city_query: city_query, place_types: place_types)
        Rails.logger.info("[Admin::CityCrawls] Enqueued CityDiscoveryJob job_id=#{job.job_id} city=#{city_query}")
      rescue StandardError => e
        Rails.logger.error("[Admin::CityCrawls] Failed to enqueue CityDiscoveryJob city=#{city_query} error=#{e.class}: #{e.message}")
        redirect_back_or_to(new_admin_city_crawl_path, alert: 'Failed to start discovery', status: :see_other)
        return
      end

      redirect_to(admin_discovered_restaurants_path, notice: 'City discovery started', status: :see_other)
    end

    private

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
