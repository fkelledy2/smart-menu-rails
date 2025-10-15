class ApplicationController < ActionController::Base
  impersonates :user
  include Pundit::Authorization
  include AnalyticsTrackable
  include SentryContext

  # include StructuredLogging # Temporarily disabled
  # include MetricsTracking # Temporarily disabled
  around_action :switch_locale

  before_action :debug_request_in_test

  def switch_locale(&)
    unless request.env['HTTP_ACCEPT_LANGUAGE'].nil?
      @locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
      I18n.with_locale(@locale, &)
    end
  end

  protect_from_forgery with: :exception, prepend: true
  
  # Add debugging for CSRF issues
  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    Rails.logger.error "CSRF token verification failed: #{exception.message}"
    Rails.logger.error "Session ID: #{session.id}"
    Rails.logger.error "Request method: #{request.method}"
    Rails.logger.error "Request path: #{request.path}"
    Rails.logger.error "Form authenticity token: #{form_authenticity_token}"
    Rails.logger.error "Request authenticity token: #{request.headers['X-CSRF-Token'] || params[:authenticity_token]}"
    
    # For development, show more details
    if Rails.env.development?
      render plain: "CSRF Error: #{exception.message}\nSession: #{session.id}\nExpected: #{form_authenticity_token}\nReceived: #{request.headers['X-CSRF-Token'] || params[:authenticity_token]}", status: :unprocessable_entity
    else
      redirect_to new_user_session_path, alert: 'Security token expired. Please try logging in again.'
    end
  end

  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :set_current_employee
  before_action :set_permissions
  before_action :redirect_to_onboarding_if_needed

  # PWA offline page
  def offline
    render 'application/offline', layout: false
  end

  protected

  def set_permissions
    @canAddRestaurant = false
    return unless current_user&.plan

    @restaurants = Restaurant.where(user: current_user, archived: false)
    if @restaurants.size < current_user.plan.locations || current_user.plan.locations == -1
      @canAddRestaurant = true
    end
  end

  def set_current_employee
    if current_user
      @current_employee = Employee.where(user_id: current_user.id).first
      @restaurants = Restaurant.where(user: current_user)
      @userplan = Userplan.where(user_id: current_user.id).first
      if @userplan.nil?
        @userplan = Userplan.new
      end
    else
      @userplan = Userplan.new
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name avatar])
  end

  def debug_request_in_test
    # Debug logging removed - was for API routing investigation
  end

  def redirect_to_onboarding_if_needed
    return unless user_signed_in?
    return if devise_controller?
    return if controller_name == 'onboarding'
    return if request.xhr? # Skip for AJAX requests

    # Skip for certain controllers that should always be accessible
    skip_controllers = %w[home sessions registrations passwords confirmations unlocks]
    return if skip_controllers.include?(controller_name)

    # Redirect to onboarding if user needs it
    if current_user.needs_onboarding?
      redirect_to onboarding_path
    end
  end

  # Admin authorization helper
  def ensure_admin!
    unless current_user&.admin?
      flash[:alert] = 'Access denied. Admin privileges required.'
      redirect_to root_path
    end
  end

  # Cache warming helpers for controllers

  # Warm cache for user's restaurants and related data
  def warm_user_cache_async
    return unless current_user

    CacheWarmingJob.perform_later(
      user_id: current_user.id,
      warm_type: 'user_restaurants',
    )
  end

  # Warm cache for specific restaurant and its data
  def warm_restaurant_cache_async(restaurant_id)
    CacheWarmingJob.perform_later(
      restaurant_id: restaurant_id,
      warm_type: 'restaurant_full',
    )
  end

  # Warm cache for menu and its items
  def warm_menu_cache_async(menu_id)
    CacheWarmingJob.perform_later(
      menu_id: menu_id,
      warm_type: 'menu_full',
    )
  end

  # Warm cache for active orders (kitchen/management view)
  def warm_active_orders_cache_async(restaurant_id)
    CacheWarmingJob.perform_later(
      restaurant_id: restaurant_id,
      warm_type: 'active_orders',
    )
  end

  # Check if cache warming should be triggered (avoid excessive warming)
  def should_warm_cache?
    # Only warm cache for authenticated users
    return false unless current_user

    # Don't warm cache for AJAX requests
    return false if request.xhr?

    # Don't warm cache too frequently (check session timestamp)
    last_warm = session[:last_cache_warm]
    return false if last_warm && Time.zone.parse(last_warm) > 5.minutes.ago

    # Update session timestamp
    session[:last_cache_warm] = Time.current.iso8601
    true
  rescue StandardError
    # If there's any error with session handling, default to not warming
    false
  end

  # Trigger strategic cache warming based on user activity
  def trigger_strategic_cache_warming
    return unless should_warm_cache?

    # Warm user's restaurant data in background
    warm_user_cache_async

    # If viewing a specific restaurant, warm its data
    if params[:restaurant_id]
      warm_restaurant_cache_async(params[:restaurant_id])
    end

    # If viewing a specific menu, warm its data
    if params[:menu_id]
      warm_menu_cache_async(params[:menu_id])
    end
  end
end
