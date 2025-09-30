# frozen_string_literal: true

module AnalyticsTrackable
  extend ActiveSupport::Concern

  included do
    before_action :set_analytics_context
    after_action :track_page_view, if: :should_track_page_view?
  end

  private

  def set_analytics_context
    Thread.current[:analytics_user_agent] = request.user_agent
    Thread.current[:analytics_ip_address] = request.remote_ip
    Thread.current[:analytics_path] = request.fullpath
    Thread.current[:analytics_referrer] = request.referer
    Thread.current[:analytics_restaurant_id] = current_restaurant&.id
  end

  def track_page_view
    page_name = "#{controller_name}.#{action_name}"
    
    if user_signed_in?
      AnalyticsService.track_page_view(current_user, page_name, page_properties)
    else
      anonymous_id = session[:session_id] ||= SecureRandom.uuid
      AnalyticsService.track_page_view(anonymous_id, page_name, page_properties)
    end
  end

  def page_properties
    {
      controller: controller_name,
      action: action_name,
      restaurant_id: current_restaurant&.id,
      locale: I18n.locale
    }
  end

  def should_track_page_view?
    # Don't track API endpoints or certain actions
    !request.xhr? && 
    !api_request? && 
    !skip_page_tracking? &&
    (Rails.env.production? || Rails.env.staging? || ENV['FORCE_ANALYTICS'] == 'true')
  end

  def api_request?
    request.path.start_with?('/api/')
  end

  def skip_page_tracking?
    # Override in controllers to skip specific actions
    false
  end

  def current_restaurant
    @current_restaurant ||= begin
      if params[:restaurant_id].present?
        Restaurant.find_by(id: params[:restaurant_id])
      elsif instance_variable_defined?(:@restaurant)
        @restaurant
      end
    end
  end

  # Helper methods for tracking specific events
  def track_user_event(event, properties = {})
    return unless user_signed_in?
    AnalyticsService.track_user_event(current_user, event, properties)
  end

  def track_anonymous_event(event, properties = {})
    anonymous_id = session[:session_id] ||= SecureRandom.uuid
    AnalyticsService.track_anonymous_event(anonymous_id, event, properties)
  end

  def track_feature_usage(feature_name, feature_data = {})
    return unless user_signed_in?
    AnalyticsService.track_feature_usage(current_user, feature_name, feature_data)
  end
end
