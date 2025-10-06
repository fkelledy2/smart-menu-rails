class ApplicationController < ActionController::Base
  impersonates :user
  include Pundit::Authorization
  include AnalyticsTrackable

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

  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :set_current_employee
  before_action :set_permissions
  before_action :redirect_to_onboarding_if_needed

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
      flash[:alert] = "Access denied. Admin privileges required."
      redirect_to root_path
    end
  end
end
