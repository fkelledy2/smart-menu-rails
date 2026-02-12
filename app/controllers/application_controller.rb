class ApplicationController < ActionController::Base
  impersonates :user
  include Pundit::Authorization
  include AnalyticsTrackable
  include SentryContext

  helper_method :current_user_has_active_subscription?
  helper_method :user_has_active_subscription?

  # include StructuredLogging # Temporarily disabled
  # include MetricsTracking # Temporarily disabled
  around_action :switch_locale

  before_action :debug_request_in_test

  prepend_before_action :enforce_impersonation_expiry
  prepend_before_action :block_high_risk_actions_when_impersonating

  # Authorization monitoring
  rescue_from Pundit::NotAuthorizedError, with: :handle_authorization_failure

  # Redirect to restaurants index after sign in (or back to claim flow if pending)
  def after_sign_in_path_for(resource)
    claim_redirect_or(restaurants_path)
  end

  def after_sign_up_path_for(resource)
    claim_redirect_or(restaurants_path)
  end

  def impersonating_user?
    return false if request.env['impersonating_user_checking']

    request.env['impersonating_user_checking'] = true

    return true if session[:pretender_user_id].present?
    return true if session['pretender_user_id'].present?

    cu = respond_to?(:current_user) ? current_user : nil
    tu = respond_to?(:true_user) ? true_user : nil
    cu.present? && tu.present? && cu != tu
  rescue StandardError
    false
  ensure
    request.env['impersonating_user_checking'] = false
  end

  def switch_locale(&)
    if request.env['switch_locale_running']
      yield
      return
    end

    request.env['switch_locale_running'] = true
    Thread.current[:switch_locale_depth] ||= 0
    Thread.current[:switch_locale_depth] += 1

    # Locale detection with optional URL override
    # Priority: URL parameter > Browser Accept-Language > Default
    # Supports: en (English), it (Italian)

    requested_locale = nil

    normalize = lambda do |raw|
      v = raw.to_s.strip
      return nil if v.empty?

      # Support formats like:
      # - cs
      # - en_GB
      # - en-GB
      if v.match?(/\A[a-z]{2}\z/i)
        v.downcase
      elsif v.match?(/\A[a-z]{2}[-_][a-z]{2}\z/i)
        parts = v.split(/[-_]/)
        "#{parts[0].downcase}_#{parts[1].upcase}"
      else
        v
      end
    end

    # 1. Check for explicit URL parameter (for testing/debugging)
    if params[:locale].present?
      requested_locale = normalize.call(params[:locale])
      # Store in session when explicitly set
      session[:locale] = requested_locale
    else
      # 2. Use session (persisted user choice) if present
      if session[:locale].present?
        requested_locale = normalize.call(session[:locale])
      end

      # 3. Use browser's Accept-Language header (fallback)
      if requested_locale.nil? && request.env['HTTP_ACCEPT_LANGUAGE'].present?
        accept_language = request.env['HTTP_ACCEPT_LANGUAGE']
        # Extract the first two-letter language code
        requested_locale = normalize.call(accept_language.scan(/^[a-z]{2}/).first)
      end
    end

    # Validate locale is supported
    @locale = if requested_locale && I18n.available_locales.map(&:to_s).include?(requested_locale)
                requested_locale.to_sym
              else
                # Fall back to default locale for unsupported or missing locales
                I18n.default_locale
              end

    I18n.with_locale(@locale, &)
  rescue I18n::InvalidLocale => e
    # Safety net: if the requested locale is invalid, fall back to default.
    # IMPORTANT: Do not swallow unrelated exceptions raised inside the request.
    Rails.logger.error "Locale switching error: #{e.message}, falling back to default locale"
    @locale = I18n.default_locale
    I18n.with_locale(@locale, &)
  ensure
    Thread.current[:switch_locale_depth] -= 1 if Thread.current[:switch_locale_depth]
    request.env['switch_locale_running'] = false
  end

  protect_from_forgery with: :exception, prepend: true

  def enforce_impersonation_expiry
    return if request.env['impersonation_expiry_checked']

    request.env['impersonation_expiry_checked'] = true

    return unless impersonating_user?

    expires_at_raw = session[:impersonation_expires_at].to_s
    expires_at = begin
      Time.zone.parse(expires_at_raw)
    rescue StandardError
      nil
    end

    return if expires_at && Time.current <= expires_at

    finalize_impersonation_audit!(ended_reason: 'expired')
    stop_impersonating_user
    redirect_to root_path, alert: 'Impersonation session expired.'
  end

  def block_high_risk_actions_when_impersonating
    return if request.env['impersonation_risk_block_checked']

    request.env['impersonation_risk_block_checked'] = true

    return unless impersonating_user?

    high_risk = false

    # Payments / billing
    if controller_path.start_with?('payments/')
      high_risk = true
    end

    if controller_path == 'userplans'
      high_risk = true
    end

    # Account takeover / profile updates
    if (respond_to?(:devise_controller?) && devise_controller? && controller_name == 'registrations') ||
       controller_path == 'devise/registrations' || (controller_path == 'users/registrations')
      high_risk = true
    end

    return unless high_risk

    if request.format.json?
      render json: { error: 'Action not allowed while impersonating' }, status: :forbidden
      return
    end

    if request.format.html?
      redirect_back_or_to(root_path, alert: 'This action is not allowed while impersonating.', status: :see_other)
      return
    end

    head :forbidden
  end

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
      render plain: "CSRF Error: #{exception.message}\nSession: #{session.id}\nExpected: #{form_authenticity_token}\nReceived: #{request.headers['X-CSRF-Token'] || params[:authenticity_token]}",
             status: :unprocessable_content
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

  def user_has_active_subscription?(user)
    return false unless user
    return true if user.super_admin?

    user.restaurants
      .includes(:restaurant_subscription)
      .any? { |r| r.restaurant_subscription&.active_or_trialing_with_payment_method? }
  rescue StandardError
    false
  end

  def current_user_has_active_subscription?
    return false unless current_user

    @current_user_has_active_subscription ||= user_has_active_subscription?(current_user)
  end

  def current_user_restaurants
    return Restaurant.none unless current_user

    @current_user_restaurants ||= Restaurant.where(user: current_user, archived: false).order(:sequence, :id)
  end

  def set_permissions
    @canAddRestaurant = false
    return unless current_user&.plan

    @restaurants = current_user_restaurants
    if current_user.super_admin? || @restaurants.size < current_user.plan.locations || current_user.plan.locations == -1
      @canAddRestaurant = true
    end
  end

  def set_current_employee
    return if request.env['set_current_employee_running']

    request.env['set_current_employee_running'] = true

    Thread.current[:set_current_employee_depth] ||= 0
    Thread.current[:set_current_employee_depth] += 1

    begin
      if Thread.current[:set_current_employee_depth] > 1
        return
      end

      if current_user
        @current_employee ||= Employee.find_by(user_id: current_user.id)
        @userplan ||= Userplan.find_by(user_id: current_user.id)
        @userplan ||= Userplan.new
      else
        @userplan = Userplan.new
      end
    ensure
      Thread.current[:set_current_employee_depth] -= 1 if Thread.current[:set_current_employee_depth]
      request.env['set_current_employee_running'] = false
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name avatar])
  end

  def finalize_impersonation_audit!(ended_reason:)
    audit_id = session[:impersonation_audit_id]
    return if audit_id.blank?

    audit = ImpersonationAudit.find_by(id: audit_id)
    return unless audit
    return if audit.ended_at.present?

    audit.update!(ended_at: Time.current, ended_reason: ended_reason)
  ensure
    session.delete(:impersonation_audit_id)
    session.delete(:impersonation_expires_at)
  end

  def debug_request_in_test
    # Debug logging removed - was for API routing investigation
  end

  def redirect_to_onboarding_if_needed
    return unless user_signed_in?
    return if performed?
    return if devise_controller?
    return if controller_name == 'onboarding'
    return if request.xhr? # Skip for AJAX requests
    return if request.format.json?

    return if impersonating_user?

    return if current_user&.email.to_s.downcase.end_with?('@mellow.menu')

    return if current_user&.admin? || current_user&.super_admin?

    return if current_user.has_active_employment?

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

  # Authorization monitoring and failure handling
  def handle_authorization_failure(exception)
    # Track the authorization failure
    AuthorizationMonitoringService.track_authorization_failure(
      current_user,
      exception.record,
      exception.query,
      exception,
      {
        controller: controller_name,
        action: action_name,
        request_ip: request.remote_ip,
        user_agent: request.user_agent,
      },
    )

    # Handle the failure based on request format
    respond_to do |format|
      format.html do
        flash[:alert] = 'You are not authorized to perform this action.'
        redirect_to(request.referer || root_path)
      end
      format.json do
        render json: { error: 'Unauthorized' }, status: :forbidden
      end
      format.any do
        head :forbidden
      end
    end
  end

  # Super admins bypass Pundit verification checks
  def verify_authorized
    return if current_user&.super_admin?

    super
  end

  def verify_policy_scoped
    return if current_user&.super_admin?

    super
  end

  # Override authorize to add monitoring and super_admin bypass
  def authorize(record, query = nil)
    query ||= "#{action_name}?"

    if current_user&.super_admin?
      # Super admins bypass all policy checks
      @_pundit_policy_authorized = true

      AuthorizationMonitoringService.track_authorization_check(
        current_user,
        record,
        query.to_s.delete('?'),
        true,
        {
          controller: controller_name,
          action: action_name,
          request_ip: request.remote_ip,
          user_agent: request.user_agent,
          super_admin_bypass: true,
        },
      )

      return record
    end

    # Call Pundit's original authorize method to ensure proper tracking
    result = super

    # Track the authorization check for monitoring
    AuthorizationMonitoringService.track_authorization_check(
      current_user,
      record,
      query.to_s.delete('?'),
      true,
      {
        controller: controller_name,
        action: action_name,
        request_ip: request.remote_ip,
        user_agent: request.user_agent,
      },
    )

    result
  end

  # If the user arrived via a "Claim this restaurant" link, redirect back to the claim form
  def claim_redirect_or(default_path)
    restaurant_id = session.delete(:claim_restaurant_id)
    if restaurant_id.present? && (restaurant = Restaurant.find_by(id: restaurant_id))
      new_restaurant_claim_request_path(restaurant)
    else
      default_path
    end
  end
end
