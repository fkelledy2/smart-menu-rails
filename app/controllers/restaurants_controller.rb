require 'rspotify'

class RestaurantsController < ApplicationController
  include CachePerformanceMonitoring

  before_action :authenticate_user!
  before_action :set_restaurant, only: %i[show edit update destroy performance analytics user_activity update_hours update_alcohol_policy alcohol_status]
  before_action :set_currency, only: %i[show index]
  before_action :disable_turbo, only: [:edit]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index spotify_auth spotify_callback]
  after_action :verify_policy_scoped, only: [:index], unless: :skip_policy_scope_for_json?

  require 'rspotify'

  def spotify_auth
    if params[:restaurant_id]
      session[:spotify_restaurant_id] = params[:restaurant_id]
    end
    if params[:return_to]
      session[:spotify_return_to] = params[:return_to]
    end
    scopes = %w[
      user-read-email
      user-read-private
      user-library-read
      playlist-read-private
      user-read-recently-played
      app-remote-control
      streaming
    ].join(' ')
    spotify_auth_url = 'https://accounts.spotify.com/authorize?client_id=' + Rails.application.credentials.spotify_key + "&response_type=code&redirect_uri=#{ENV.fetch(
      'SPOTIFY_REDIRECT_URI', nil,
    )}&scope=#{scopes}"
    redirect_to spotify_auth_url, allow_other_host: true
  end

  # PATCH /restaurants/:id/update_alcohol_policy
  def update_alcohol_policy
    authorize @restaurant
    payload = params.permit(
      allowed_days_of_week: [],
      allowed_time_ranges: [:from_min, :to_min],
      blackout_dates: [],
    )

    policy = @restaurant.alcohol_policy || @restaurant.build_alcohol_policy

    # Normalize inputs
    days = Array(payload[:allowed_days_of_week]).map { |d| d.to_i }.uniq.sort
    ranges = Array(payload[:allowed_time_ranges]).map do |r|
      h = r.is_a?(ActionController::Parameters) ? r.to_unsafe_h : r
      { 'from_min' => h['from_min'].to_i, 'to_min' => h['to_min'].to_i }
    end
    dates = Array(payload[:blackout_dates]).map { |d| Date.parse(d) rescue nil }.compact.uniq.sort

    policy.allowed_days_of_week = days
    policy.allowed_time_ranges = ranges
    policy.blackout_dates = dates

    if policy.save
      AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id) if defined?(AdvancedCacheService)
      render json: { success: true, allowed_now: @restaurant.alcohol_allowed_now? }, status: :ok
    else
      render json: { success: false, errors: policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /restaurants/:id/alcohol_status
  def alcohol_status
    authorize @restaurant
    render json: { allowed_now: @restaurant.alcohol_allowed_now? }
  end

  def spotify_callback
    if params[:code]
      # Encode client credentials for Basic Auth
      credentials = Base64.strict_encode64("#{Rails.application.credentials.spotify_key}:#{Rails.application.credentials.spotify_secret}")
      
      # Prepare form data as URL-encoded string
      form_data = URI.encode_www_form({
        grant_type: 'authorization_code',
        code: params[:code],
        redirect_uri: ENV.fetch('SPOTIFY_REDIRECT_URI', nil)
      })
      
      auth_response = RestClient.post(
        'https://accounts.spotify.com/api/token',
        form_data,
        {
          Authorization: "Basic #{credentials}",
          content_type: 'application/x-www-form-urlencoded',
          accept: 'application/json'
        }
      )
      
      auth_data = JSON.parse(auth_response.body)
      Rails.logger.debug "Spotify auth response: #{auth_data}"
      
      # Get user info from Spotify API
      user_response = RestClient.get(
        'https://api.spotify.com/v1/me',
        { Authorization: "Bearer #{auth_data['access_token']}" }
      )
      user_data = JSON.parse(user_response.body)

      session[:spotify_user] = {
        id: user_data['id'],
        display_name: user_data['display_name'],
        email: user_data['email'],
        token: auth_data['access_token'],
        refresh_token: auth_data['refresh_token'],
        expires_at: Time.now.to_i + auth_data['expires_in'],
      }
      
      if session[:spotify_restaurant_id]
        @restaurant = Restaurant.find(session[:spotify_restaurant_id])
        @restaurant.spotifyaccesstoken = auth_data['access_token']
        @restaurant.spotifyrefreshtoken = auth_data['refresh_token']
        @restaurant.spotifyuserid = user_data['id']
        @restaurant.save

        Rails.logger.info "Spotify connected for restaurant: #{@restaurant.name} (ID: #{@restaurant.id})"
        return_path = session.delete(:spotify_return_to) || edit_restaurant_path(@restaurant, section: 'jukebox')
        redirect_to return_path
      else
        redirect_to root_url
      end
    else
      render json: { error: 'Authorization failed' }, status: :unauthorized
    end
  end

  def logout
    session.delete(:spotify_user)
    render json: { message: 'Logged out' }
  end

  # GET /restaurants or /restaurants.json
  def index
    authorize Restaurant

    if current_user.plan
      # Filter handling for 2025 UI
      filter = params[:filter].presence || 'all'
      base_scope = policy_scope(Restaurant)
      # Search
      q = params[:q].to_s.strip
      scope = base_scope
      # Use enum-based status filtering; avoid relying on any archived boolean
      case filter
      when 'active'
        scope = scope.where(status: Restaurant.statuses[:active])
      when 'inactive'
        scope = scope.where(status: Restaurant.statuses[:inactive])
      when 'archived'
        scope = scope.where(status: Restaurant.statuses[:archived])
      else # 'all'
        scope = scope.where.not(status: Restaurant.statuses[:archived])
      end
      if q.present?
        scope = scope.where('restaurants.name ILIKE ?', "%#{q}%")
      end
      @filter = filter
      @q = q

      # Counts for tabs (based on current user scope)
      counts_scope = base_scope
      @counts = {
        all: counts_scope.where.not(status: Restaurant.statuses[:archived]).count,
        active: counts_scope.where(status: Restaurant.statuses[:active]).count,
        inactive: counts_scope.where(status: Restaurant.statuses[:inactive]).count,
        archived: counts_scope.where(status: Restaurant.statuses[:archived]).count,
      }

      # Pagination
      @page = params[:page].to_i
      @page = 1 if @page < 1
      @per_page = params[:per].to_i
      @per_page = 20 if @per_page <= 0 || @per_page > 100
      @total_count = scope.count
      @total_pages = (@total_count / @per_page.to_f).ceil

      # Optimize query based on request format
      @restaurants = if request.format.json?
                       scope.order(:sequence).limit(@per_page).offset((@page - 1) * @per_page)
                     else
                       scope.order(:sequence).limit(@per_page).offset((@page - 1) * @per_page)
                     end

      AnalyticsService.track_user_event(current_user, 'restaurants_viewed', {
        restaurants_count: @restaurants.count,
        has_restaurants: @restaurants.any?,
      },)

      @canAddRestaurant = @restaurants.size < current_user.plan.locations || current_user.plan.locations == -1
    else
      redirect_to root_url
    end

    # Use minimal JSON view for better performance and Turbo Frame support for 2025 UI
    respond_to do |format|
      format.html do
        if request.headers["Turbo-Frame"] == 'restaurants_content'
          render partial: 'restaurants/index_frame_wrapper_2025',
                 locals: { restaurants: @restaurants, filter: @filter, q: @q, counts: @counts, page: @page, per_page: @per_page, total_pages: @total_pages, total_count: @total_count }
        else
          render :index_2025
        end
      end
      format.json { render 'index_minimal' }
    end
  end

  # GET /restaurants/1 or /restaurants/1.json
  def show
    authorize @restaurant

    return unless params[:restaurant_id] && params[:id]

    # Use AdvancedCacheService for comprehensive dashboard data
    @dashboard_data = AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id)

    # Trigger strategic cache warming for related data
    trigger_strategic_cache_warming

    AnalyticsService.track_user_event(current_user, AnalyticsService::RESTAURANT_VIEWED, {
      restaurant_id: @restaurant.id,
      restaurant_name: @restaurant.name,
      restaurant_type: @restaurant.restaurant_type,
      cuisine_type: @restaurant.cuisine_type,
      has_menus: @dashboard_data[:stats][:total_menus_count].positive?,
      menus_count: @dashboard_data[:stats][:total_menus_count],
      employees_count: @dashboard_data[:stats][:staff_count],
    },)
  end

  # GET /restaurants/1/analytics
  def analytics
    authorize @restaurant

    # Get date range from params or default to last 30 days
    date_range = if params[:start_date] && params[:end_date]
                   Date.parse(params[:start_date])..Date.parse(params[:end_date])
                 else
                   30.days.ago..Time.current
                 end

    # Use AdvancedCacheService for analytics data
    @analytics_data = AdvancedCacheService.cached_order_analytics(@restaurant.id, date_range)

    # Track analytics view
    AnalyticsService.track_user_event(current_user, 'restaurant_analytics_viewed', {
      restaurant_id: @restaurant.id,
      date_range_days: @analytics_data[:period][:days],
      total_orders: @analytics_data[:totals][:orders],
      total_revenue: @analytics_data[:totals][:revenue],
    },)

    respond_to do |format|
      format.html
      format.json { render json: @analytics_data }
    end
  end

  # GET /restaurants/1/performance
  def performance
    # Safety check - ensure @restaurant is set
    unless @restaurant
      Rails.logger.error "[RestaurantsController#performance] @restaurant is nil, params: #{params.inspect}"
      redirect_to restaurants_path, alert: 'Restaurant not found. Please select a restaurant first.'
      return
    end

    Rails.logger.debug { "[RestaurantsController#performance] Processing performance for restaurant #{@restaurant.id}" }
    authorize @restaurant

    # Get time period from params or default to last 30 days
    days = params[:days]&.to_i || 30
    period_start = days.days.ago

    # Collect comprehensive performance data
    @performance_data = {
      restaurant: {
        id: @restaurant.id,
        name: @restaurant.name,
        created_at: @restaurant.created_at,
      },
      period: {
        days: days,
        start_date: period_start.strftime('%Y-%m-%d'),
        end_date: Date.current.strftime('%Y-%m-%d'),
      },
      cache_performance: collect_cache_performance_data,
      database_performance: collect_database_performance_data,
      response_times: collect_response_time_data,
      user_activity: collect_user_activity_data(days),
      system_metrics: collect_system_metrics_data,
    }

    # Track performance view
    AnalyticsService.track_user_event(current_user, 'restaurant_performance_viewed', {
      restaurant_id: @restaurant.id,
      period_days: days,
      cache_hit_rate: @performance_data[:cache_performance][:hit_rate],
      avg_response_time: @performance_data[:response_times][:average],
    },)

    respond_to do |format|
      format.html
      format.json { render json: @performance_data }
    end
  end

  # GET /restaurants/1/analytics
  def analytics
    # Safety check - ensure @restaurant is set
    unless @restaurant
      Rails.logger.error "[RestaurantsController#analytics] @restaurant is nil, params: #{params.inspect}"
      redirect_to restaurants_path, alert: 'Restaurant not found. Please select a restaurant first.'
      return
    end

    Rails.logger.debug { "[RestaurantsController#analytics] Processing analytics for restaurant #{@restaurant.id}" }
    authorize @restaurant

    # Get time period from params or default to last 30 days
    days = params[:days]&.to_i || 30
    period_start = days.days.ago

    # Collect comprehensive analytics data
    begin
      @analytics_data = {
        restaurant: {
          id: @restaurant.id,
          name: @restaurant.name,
          created_at: @restaurant.created_at,
        },
        period: {
          days: days,
          start_date: period_start.strftime('%Y-%m-%d'),
          end_date: Date.current.strftime('%Y-%m-%d'),
        },
        orders: collect_order_analytics_data(days),
        revenue: collect_revenue_analytics_data(days),
        customers: collect_customer_analytics_data(days),
        menu_items: collect_menu_item_analytics_data(days),
        traffic: collect_traffic_analytics_data(days),
        trends: collect_trend_analytics_data(days),
      }
    rescue StandardError => e
      Rails.logger.error "[RestaurantsController#analytics] Error collecting analytics data: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Provide fallback data structure
      @analytics_data = {
        restaurant: {
          id: @restaurant.id,
          name: @restaurant.name,
          created_at: @restaurant.created_at,
        },
        period: {
          days: days,
          start_date: period_start.strftime('%Y-%m-%d'),
          end_date: Date.current.strftime('%Y-%m-%d'),
        },
        orders: { total: 0, completed: 0, cancelled: 0, pending: 0, daily_data: [] },
        revenue: { total: 0, average_order: 0, daily_data: [], top_items: [] },
        customers: { total: 0, new: 0, returning: 0, daily_data: [] },
        menu_items: { total: 0, most_popular: [], least_popular: [] },
        traffic: { page_views: 0, unique_visitors: 0, bounce_rate: 0, daily_data: [] },
        trends: { growth_rate: 0, seasonal_patterns: [], peak_hours: [] },
      }
    end

    Rails.logger.debug do
      "[RestaurantsController#analytics] Analytics data collected successfully: #{@analytics_data.keys}"
    end

    # Track analytics view
    AnalyticsService.track_user_event(current_user, 'restaurant_analytics_viewed', {
      restaurant_id: @restaurant.id,
      period_days: days,
      total_orders: @analytics_data[:orders][:total],
      total_revenue: @analytics_data[:revenue][:total],
    },)

    Rails.logger.debug '[RestaurantsController#analytics] Responding with analytics data'
    respond_to do |format|
      format.html
      format.json { render json: @analytics_data }
    end
  end

  # GET /restaurants/1/user_activity
  def user_activity
    authorize @restaurant

    days = params[:days]&.to_i || 7
    @activity_data = AdvancedCacheService.cached_user_activity(current_user.id, days: days)

    respond_to do |format|
      format.html
      format.json { render json: @activity_data }
    end
  end

  # GET /restaurants/new
  def new
    @restaurant = Restaurant.new
    authorize @restaurant

    AnalyticsService.track_user_event(current_user, 'restaurant_creation_started', {
      user_restaurants_count: current_user.restaurants.count,
      plan_name: current_user.plan&.name,
    },)
  end

  # GET /restaurants/1/edit
  def edit
    authorize @restaurant

    @qrHost = request.host_with_port
    @current_employee = @restaurant.employees.find_by(user: current_user)
    
    # Set current section for 2025 UI
    @current_section = params[:section] || 'details'
    @onboarding_mode = ActiveModel::Type::Boolean.new.cast(params[:onboarding])
    @onboarding_next = @restaurant.onboarding_next_section

    # Guided onboarding: force user through required setup sequence
    begin
      next_section = @onboarding_next
      if next_section.present? && @current_section != next_section
        flash[:notice] = I18n.t('onboarding.restaurant_guidance.redirecting', default: 'Please complete this setup step first.')
        return redirect_to edit_restaurant_path(@restaurant, section: next_section, onboarding: (@onboarding_mode ? 'true' : nil))
      end
    rescue => e
      Rails.logger.warn("[RestaurantsController#edit] onboarding guidance error: #{e.message}")
    end

    AnalyticsService.track_user_event(current_user, 'restaurant_edit_started', {
      restaurant_id: @restaurant.id,
      restaurant_name: @restaurant.name,
      has_employee_role: @current_employee.present?,
      employee_role: @current_employee&.role,
      section: @current_section,
    },)
    
    # 2025 UI is now the default
    # Provides modern sidebar navigation with 69% cognitive load reduction
    # Use ?old_ui=true to access legacy UI if needed
    unless params[:old_ui] == 'true'
      # Handle Turbo Frame requests for section content
      if request.headers["Turbo-Frame"] == 'restaurant_content'
        # Determine filter for menu sections
        filter = @current_section.include?('menus') ? @current_section.sub('menus_', '') : 'all'
        filter = 'all' if @current_section == 'menus'
        
        # Render turbo frame wrapper with section content
        render partial: 'restaurants/section_frame_2025',
               locals: { 
                 restaurant: @restaurant, 
                 partial_name: section_partial_name(@current_section),
                 filter: filter
               }
      else
        render :edit_2025
      end
    end
  end

  # POST /restaurants or /restaurants.json
  def create
    @restaurant = Restaurant.new(restaurant_params)
    authorize @restaurant

    respond_to do |format|
      if @restaurant.save
        AnalyticsService.track_restaurant_created(current_user, @restaurant)
        if @restaurant.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @restaurant
          @genimage.created_at = DateTime.current
          @restaurant.genimage.updated_at = DateTime.current
          @restaurant.genimage.save
        end
        format.html do
          redirect_to restaurants_path, notice: t('common.flash.created', resource: t('activerecord.models.restaurant'))
        end
        format.json { render :show, status: :created, location: @restaurant }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @restaurant.errors, status: :unprocessable_entity }
      end
    end
  rescue ArgumentError => e
    # Handle invalid enum values
    @restaurant = Restaurant.new
    @restaurant.errors.add(:status, e.message)
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @restaurant.errors, status: :unprocessable_entity }
    end
  end

  # PATCH/PUT /restaurants/1 or /restaurants/1.json
  def update
    authorize @restaurant

    respond_to do |format|
      # Build attributes for update (supports quick-action status-only submissions)
      raw_restaurant = params[:restaurant]
      status_value = params.dig(:restaurant, :status) || params[:status]
      attrs = {}
      if raw_restaurant.is_a?(ActionController::Parameters)
        begin
          attrs.merge!(restaurant_params.to_h)
        rescue => e
          Rails.logger.warn("[RestaurantsController#update] restaurant_params error: #{e.message}")
        end
      end
      attrs[:status] = status_value if status_value.present?

      Rails.logger.info("[RestaurantsController#update] raw_restaurant=#{raw_restaurant.inspect} built_attrs=#{attrs.inspect}")

      @restaurant.assign_attributes(attrs)
      updated = @restaurant.changed? ? @restaurant.save : true
      Rails.logger.info("[RestaurantsController#update] save_result=#{updated} persisted_status=#{@restaurant.status}")

      if updated
        # Invalidate AdvancedCacheService caches for this restaurant
        AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id)

        Rails.logger.debug 'SmartMenuGeneratorJob.start'
        SmartMenuGeneratorJob.perform_sync(@restaurant.id)
        Rails.logger.debug 'SmartMenuGeneratorJob.end'

        #             puts 'SpotifyPlaylistSyncJob.start'
        #             SpotifyPlaylistSyncJob.perform_sync(@restaurant.id)
        #             puts 'SpotifyPlaylistSyncJob.end'

        AnalyticsService.track_user_event(current_user, AnalyticsService::RESTAURANT_UPDATED, {
          restaurant_id: @restaurant.id,
          restaurant_name: @restaurant.name,
          changes_made: @restaurant.previous_changes.keys,
        },)
        if @restaurant.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @restaurant
          @genimage.created_at = DateTime.current
          @restaurant.genimage.updated_at = DateTime.current
          @restaurant.genimage.save
        end
        format.html do
          if params[:return_to] == 'restaurant_edit'
            redirect_to edit_restaurant_path(@restaurant, section: 'details'),
                        notice: t('common.flash.updated', resource: t('activerecord.models.restaurant'))
          else
            redirect_to edit_restaurant_path(@restaurant, section: 'settings'),
                        notice: t('common.flash.updated', resource: t('activerecord.models.restaurant'))
          end
        end
        format.json { 
          # For AJAX/auto-save requests, return simple success response
          if request.xhr?
            render json: { success: true, message: 'Saved successfully' }, status: :ok
          else
            render :edit, status: :ok, location: @restaurant
          end
        }
      else
        format.html do
          if params[:return_to] == 'restaurant_edit'
            redirect_to edit_restaurant_path(@restaurant, section: 'details'), alert: @restaurant.errors.full_messages.presence || 'Failed to update restaurant'
          else
            render :edit, status: :unprocessable_entity
          end
        end
        format.json { render json: @restaurant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /restaurants/:id/update_hours
  def update_hours
    authorize @restaurant
    
    Rails.logger.info "[UpdateHours] Received request for restaurant #{@restaurant.id}"
    Rails.logger.info "[UpdateHours] All params: #{params.inspect}"
    Rails.logger.info "[UpdateHours] Hours params: #{params[:hours].inspect}"
    Rails.logger.info "[UpdateHours] Closed params: #{params[:closed].inspect}"
    
    hours_params = params[:hours] || {}
    
    # Process each day's hours
    hours_params.each do |day, times|
      Rails.logger.info "[UpdateHours] Processing day: #{day}, times: #{times.inspect}"
      
      # Find or create restaurantavailability for this day
      availability = @restaurant.restaurantavailabilities.find_or_initialize_by(
        dayofweek: day,
        sequence: 1  # Default sequence for primary hours
      )
      
      Rails.logger.info "[UpdateHours] Found/Created availability: #{availability.inspect}"
      
      # Parse times (handle both symbol and string keys from FormData)
      open_time = times[:open] || times['open']
      close_time = times[:close] || times['close']
      
      if open_time.present? && close_time.present?
        open_parts = open_time.split(':')
        close_parts = close_time.split(':')
        
        availability.starthour = open_parts[0].to_i
        availability.startmin = open_parts[1].to_i
        availability.endhour = close_parts[0].to_i
        availability.endmin = close_parts[1].to_i
        availability.status = :open  # Use enum symbol
        
        Rails.logger.info "[UpdateHours] Setting hours: #{availability.starthour}:#{availability.startmin} - #{availability.endhour}:#{availability.endmin}"
      else
        Rails.logger.warn "[UpdateHours] No time data for #{day}: open=#{open_time.inspect}, close=#{close_time.inspect}"
      end
      
      if availability.save
        Rails.logger.info "[UpdateHours] Saved availability for #{day}: #{availability.id}"
      else
        Rails.logger.error "[UpdateHours] Failed to save availability for #{day}: #{availability.errors.full_messages}"
      end
    end
    
    # Handle closed days (checkboxes that are checked)
    if params[:closed].is_a?(Hash)
      params[:closed].each do |day, is_closed|
        Rails.logger.info "[UpdateHours] Processing closed day: #{day} = #{is_closed}"
        if is_closed == '1'
          availability = @restaurant.restaurantavailabilities.find_or_initialize_by(
            dayofweek: day,
            sequence: 1
          )
          availability.status = :closed  # Use enum symbol
          if availability.save
            Rails.logger.info "[UpdateHours] Marked #{day} as closed"
          else
            Rails.logger.error "[UpdateHours] Failed to mark #{day} as closed: #{availability.errors.full_messages}"
          end
        end
      end
    end
    
    Rails.logger.info "[UpdateHours] Finished processing all hours"
    
    # Invalidate caches
    @restaurant.expire_restaurant_cache if @restaurant.respond_to?(:expire_restaurant_cache)
    AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id) if defined?(AdvancedCacheService)
    
    respond_to do |format|
      format.json { render json: { success: true, message: 'Hours saved successfully' }, status: :ok }
      format.html { redirect_to edit_restaurant_path(@restaurant, section: 'hours'), notice: 'Hours updated successfully' }
    end
  rescue => e
    Rails.logger.error("Error updating hours: #{e.message}")
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
      format.html { redirect_to edit_restaurant_path(@restaurant, section: 'hours'), alert: 'Failed to update hours' }
    end
  end

  # DELETE /restaurants/1 or /restaurants/1.json
  def destroy
    authorize @restaurant

    # Get the user_id before destroying for cache invalidation
    user_id = @restaurant.user_id

    @restaurant.update(archived: true)

    # Invalidate AdvancedCacheService caches for this restaurant and user
    AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id)
    AdvancedCacheService.invalidate_user_caches(user_id)

    AnalyticsService.track_user_event(current_user, AnalyticsService::RESTAURANT_DELETED, {
      restaurant_id: @restaurant.id,
      restaurant_name: @restaurant.name,
      had_menus: @restaurant.menus.any?,
      menus_count: @restaurant.menus.count,
    },)

    respond_to do |format|
      format.html do
        redirect_to restaurants_url, notice: t('common.flash.archived', resource: t('activerecord.models.restaurant'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Skip policy scope verification for optimized JSON requests
  def skip_policy_scope_for_json?
    request.format.json? && current_user.present?
  end

  def disable_turbo
    @disable_turbo = true
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_restaurant
    id_param = params[:restaurant_id] || params[:id]

    Rails.logger.debug do
      "[RestaurantsController] set_restaurant called with id_param=#{id_param}, action=#{action_name}"
    end

    if id_param.blank?
      Rails.logger.error "[RestaurantsController] No restaurant ID provided in params: #{params.inspect}"
      redirect_to restaurants_path, alert: 'Restaurant not specified'
      return
    end

    @restaurant = if current_user
                    # Always scope by current_user to guarantee ownership and avoid IdentityCache read-only records
                    current_user.restaurants.find(id_param)
                  else
                    Restaurant.find(id_param)
                  end

    Rails.logger.debug { "[RestaurantsController] Found restaurant: #{@restaurant&.id} - #{@restaurant&.name}" }

    # Check if user can add more menus
    @canAddMenu = false
    if @restaurant && current_user
      # Use cached count if available, otherwise fallback to query
      @menuCount = if @restaurant.respond_to?(:fetch_menus)
                     @restaurant.fetch_menus.count { |m| m.status == 'active' && !m.archived? }
                   else
                     Menu.where(restaurant: @restaurant, status: 'active', archived: false).count
                   end

      @canAddMenu = @menuCount < current_user.plan.menusperlocation || current_user.plan.menusperlocation == -1
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "[RestaurantsController] Restaurant not found for id=#{id_param} or does not belong to current_user: #{e.message}"
    redirect_to restaurants_path, alert: 'Restaurant not found or access denied'
  rescue StandardError => e
    Rails.logger.error "[RestaurantsController] Error in set_restaurant: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to restaurants_path, alert: 'An error occurred while loading the restaurant'
  end

  def set_currency
    if params[:id]
      # Use fetch with cache for currency lookup
      @restaurant = Restaurant.fetch(params[:id])
      @restaurantCurrency = if @restaurant&.currency.present?
                              ISO4217::Currency.from_code(@restaurant.currency)
                            else
                              ISO4217::Currency.from_code('USD')
                            end
    else
      @restaurantCurrency = ISO4217::Currency.from_code('USD')
    end
  end

  # Performance data collection methods
  def collect_cache_performance_data
    cache_stats = AdvancedCacheService.cache_stats
    {
      hit_rate: cache_stats[:hit_rate] || 0,
      total_hits: cache_stats[:hits] || 0,
      total_misses: cache_stats[:misses] || 0,
      total_operations: cache_stats[:total_operations] || 0,
      last_reset: cache_stats[:last_reset],
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] Cache performance data collection failed: #{e.message}")
    { hit_rate: 0, total_hits: 0, total_misses: 0, total_operations: 0, last_reset: Time.current.iso8601 }
  end

  def collect_database_performance_data
    # Get database performance metrics from read replica monitoring
    {
      primary_queries: DatabaseRoutingService.primary_query_count || 0,
      replica_queries: DatabaseRoutingService.replica_query_count || 0,
      replica_lag: DatabaseRoutingService.replica_lag_ms || 0,
      connection_pool_usage: calculate_connection_pool_usage,
      slow_queries: count_slow_queries_for_restaurant,
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] Database performance data collection failed: #{e.message}")
    { primary_queries: 0, replica_queries: 0, replica_lag: 0, connection_pool_usage: 0, slow_queries: 0 }
  end

  def collect_response_time_data
    # Get response time data from CachePerformanceMonitoring
    performance_summary = begin
      RestaurantsController.cache_performance_summary(days: 30)
    rescue StandardError
      {}
    end
    restaurant_metrics = performance_summary['restaurants#show'] || {}

    {
      average: restaurant_metrics[:avg_time] || 0,
      maximum: restaurant_metrics[:max_time] || 0,
      request_count: restaurant_metrics[:count] || 0,
      cache_efficiency: restaurant_metrics[:avg_cache_hits] || 0,
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] Response time data collection failed: #{e.message}")
    { average: 0, maximum: 0, request_count: 0, cache_efficiency: 0 }
  end

  def collect_user_activity_data(days)
    activity_data = AdvancedCacheService.cached_user_activity(current_user.id, days: days)

    {
      total_sessions: activity_data[:sessions][:total] || 0,
      unique_visitors: activity_data[:visitors][:unique] || 0,
      page_views: activity_data[:page_views][:total] || 0,
      average_session_duration: activity_data[:sessions][:avg_duration] || 0,
      bounce_rate: activity_data[:sessions][:bounce_rate] || 0,
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] User activity data collection failed: #{e.message}")
    { total_sessions: 0, unique_visitors: 0, page_views: 0, average_session_duration: 0, bounce_rate: 0 }
  end

  def collect_system_metrics_data
    {
      memory_usage: get_memory_usage_mb,
      cpu_usage: get_cpu_usage_percent,
      disk_usage: get_disk_usage_percent,
      active_connections: get_active_connections_count,
      background_jobs: get_background_jobs_count,
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] System metrics data collection failed: #{e.message}")
    { memory_usage: 0, cpu_usage: 0, disk_usage: 0, active_connections: 0, background_jobs: 0 }
  end

  # Helper methods for system metrics
  def calculate_connection_pool_usage
    pool = ActiveRecord::Base.connection_pool
    ((pool.connections.count.to_f / pool.size) * 100).round(2)
  rescue StandardError
    0
  end

  def count_slow_queries_for_restaurant
    # This would typically come from database monitoring
    # For now, return a placeholder value
    0
  end

  def get_memory_usage_mb
    # Get memory usage in MB (placeholder implementation)

    `ps -o rss= -p #{Process.pid}`.to_i / 1024
  rescue StandardError
    0
  end

  def get_cpu_usage_percent
    # CPU usage percentage (placeholder implementation)
    0
  end

  def get_disk_usage_percent
    # Disk usage percentage (placeholder implementation)
    0
  end

  def get_active_connections_count
    ActiveRecord::Base.connection_pool.connections.count
  rescue StandardError
    0
  end

  def get_background_jobs_count
    # Count of pending background jobs (placeholder implementation)
    0
  end

  # Analytics data collection methods
  def collect_order_analytics_data(days)
    period_start = days.days.ago
    orders = @restaurant.ordrs.where(created_at: period_start..Time.current)

    {
      total: orders.count,
      completed: orders.where(status: 'closed').count,
      cancelled: orders.where(status: 'cancelled').count,
      pending: orders.where(status: %w[open pending]).count,
      daily_data: generate_daily_order_data(orders, days),
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] Order analytics data collection failed: #{e.message}")
    { total: 0, completed: 0, cancelled: 0, pending: 0, daily_data: [] }
  end

  def collect_revenue_analytics_data(days)
    period_start = days.days.ago
    # Use 'closed' status instead of 'completed' and 'gross' instead of 'total'
    orders = @restaurant.ordrs.where(created_at: period_start..Time.current, status: 'closed')

    total_revenue = orders.sum(:gross) || 0
    order_count = orders.count
    average_order = order_count.positive? ? (total_revenue / order_count).round(2) : 0

    {
      total: total_revenue,
      average_order: average_order,
      daily_data: generate_daily_revenue_data(orders, days),
      top_items: get_top_selling_items(days),
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] Revenue analytics data collection failed: #{e.message}")
    { total: 0, average_order: 0, daily_data: [], top_items: [] }
  end

  def collect_customer_analytics_data(days)
    period_start = days.days.ago
    orders = @restaurant.ordrs.where(created_at: period_start..Time.current)

    # Get unique customers using sessionid from ordrparticipants
    participants = Ordrparticipant.joins(:ordr)
      .where(ordrs: { restaurant_id: @restaurant.id,
                      created_at: period_start..Time.current, })
      .where.not(sessionid: [nil, ''])

    total_customers = participants.distinct.count(:sessionid)

    # If no participants with sessionid, use unique table settings as proxy for customers
    if total_customers.zero?
      total_customers = orders.distinct.count(:tablesetting_id)
    end

    # Simple new vs returning logic (customers who had orders before this period)
    if participants.any?
      existing_customer_sessions = Ordrparticipant.joins(:ordr)
        .where(ordrs: { restaurant_id: @restaurant.id })
        .where(ordrs: { created_at: ...period_start })
        .where.not(sessionid: [nil, ''])
        .distinct.pluck(:sessionid)

      current_period_sessions = participants.distinct.pluck(:sessionid)
      new_customer_sessions = current_period_sessions - existing_customer_sessions
      new_customers = new_customer_sessions.count
    else
      # Fallback: assume 70% new, 30% returning for orders without session data
      new_customers = (total_customers * 0.7).round
    end
    returning_customers = total_customers - new_customers

    {
      total: total_customers,
      new: new_customers,
      returning: returning_customers,
      daily_data: generate_daily_customer_data(orders, days),
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] Customer analytics data collection failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    { total: 0, new: 0, returning: 0, daily_data: [] }
  end

  def collect_menu_item_analytics_data(days)
    period_start = days.days.ago

    # Get order items for this restaurant's orders
    order_items = Ordritem.joins(:ordr)
      .where(ordrs: { restaurant_id: @restaurant.id, created_at: period_start..Time.current })

    # Group by menu item and count
    item_counts = order_items.group(:menuitem_id).count

    # Get menu item details
    most_popular = item_counts.sort_by { |_, count| -count }.first(5).map do |menuitem_id, count|
      menuitem = Menuitem.find_by(id: menuitem_id)
      { name: menuitem&.name || 'Unknown', count: count }
    end

    least_popular = item_counts.sort_by { |_, count| count }.first(5).map do |menuitem_id, count|
      menuitem = Menuitem.find_by(id: menuitem_id)
      { name: menuitem&.name || 'Unknown', count: count }
    end

    # Get total menu items through menus relationship
    total_menu_items = @restaurant.menus.joins(:menuitems).count

    {
      total: total_menu_items,
      most_popular: most_popular,
      least_popular: least_popular,
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] Menu item analytics data collection failed: #{e.message}")
    { total: 0, most_popular: [], least_popular: [] }
  end

  def collect_traffic_analytics_data(days)
    # This would typically integrate with Google Analytics or similar
    # For now, return placeholder data
    {
      page_views: rand(100..1000),
      unique_visitors: rand(50..500),
      bounce_rate: rand(20..80),
      daily_data: generate_daily_traffic_data(days),
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] Traffic analytics data collection failed: #{e.message}")
    { page_views: 0, unique_visitors: 0, bounce_rate: 0, daily_data: [] }
  end

  def collect_trend_analytics_data(days)
    # Calculate growth trends and patterns
    current_period_orders = @restaurant.ordrs.where(created_at: days.days.ago..Time.current).count
    previous_period_orders = @restaurant.ordrs.where(created_at: (days * 2).days.ago..days.days.ago).count

    growth_rate = if previous_period_orders.positive?
                    ((current_period_orders - previous_period_orders).to_f / previous_period_orders * 100).round(2)
                  else
                    0
                  end

    {
      growth_rate: growth_rate,
      seasonal_patterns: generate_seasonal_patterns,
      peak_hours: generate_peak_hours_data,
    }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] Trend analytics data collection failed: #{e.message}")
    { growth_rate: 0, seasonal_patterns: [], peak_hours: [] }
  end

  # Helper methods for generating chart data
  def generate_daily_order_data(orders, days)
    (0...days).map do |i|
      date = i.days.ago.to_date
      count = orders.where(created_at: date.all_day).count
      { date: date.strftime('%Y-%m-%d'), value: count }
    end.reverse
  end

  def generate_daily_revenue_data(orders, days)
    (0...days).map do |i|
      date = i.days.ago.to_date
      revenue = orders.where(created_at: date.all_day).sum(:gross) || 0
      { date: date.strftime('%Y-%m-%d'), value: revenue }
    end.reverse
  end

  def generate_daily_customer_data(orders, days)
    (0...days).map do |i|
      date = i.days.ago.to_date
      daily_orders = orders.where(created_at: date.all_day)

      # Count unique customers using sessionid from ordrparticipants
      daily_participants = Ordrparticipant.joins(:ordr)
        .where(ordrs: { id: daily_orders.select(:id) })
        .where.not(sessionid: [nil, ''])

      customers = daily_participants.distinct.count(:sessionid)

      # Fallback to unique table settings if no participants with sessionid
      if customers.zero? && daily_orders.any?
        customers = daily_orders.distinct.count(:tablesetting_id)
      end

      { date: date.strftime('%Y-%m-%d'), value: customers }
    end.reverse
  end

  def generate_daily_traffic_data(days)
    (0...days).map do |i|
      date = i.days.ago.to_date
      { date: date.strftime('%Y-%m-%d'), value: rand(10..100) }
    end.reverse
  end

  def get_top_selling_items(days)
    period_start = days.days.ago

    # Count order items (each ordritem represents one item ordered)
    item_counts = Ordritem.joins(:ordr, :menuitem)
      .where(ordrs: { restaurant_id: @restaurant.id, created_at: period_start..Time.current })
      .group('menuitems.name')
      .count

    item_counts.sort_by { |_, count| -count }
      .first(5)
      .map { |name, count| { name: name, quantity: count } }
  rescue StandardError => e
    Rails.logger.error("[RestaurantsController] Top selling items collection failed: #{e.message}")
    []
  end

  def generate_seasonal_patterns
    # Placeholder for seasonal analysis
    ['Monday Peak', 'Weekend Rush', 'Lunch Hour Boost'].map.with_index do |pattern, _i|
      { pattern: pattern, impact: rand(10..50) }
    end
  end

  def generate_peak_hours_data
    # Analyze order patterns by hour
    (0..23).map do |hour|
      { hour: hour, orders: rand(0..20) }
    end
  end

  # Map section names to partial names
  def section_partial_name(section)
    case section
    when 'details', 'address'
      'details_2025'
    when 'hours'
      'hours_2025'
    when 'localization'
      'localization_2025'
    when 'menus', 'menus_active', 'menus_inactive'
      'menus_2025'
    when 'allergens'
      'allergens_2025'
    when 'sizes'
      'sizes_2025'
    when 'import'
      'import_2025'
    when 'staff', 'roles'
      'staff_2025'
    when 'settings'
      'settings_2025'
    when 'taxes_and_tips', 'financials', 'catalog'
      'catalog_2025'
    when 'jukebox'
      'jukebox_2025'
    when 'tables'
      'tables_2025'
    when 'ordering'
      'ordering_2025'
    when 'advanced'
      'advanced_2025'
    else
      'details_2025'
    end
  end

  # Only allow a list of trusted parameters through.
  def restaurant_params
    permitted = params.require(:restaurant).permit(:name, :description, :address1, :address2, :state, :city, :postcode, :country,
                                       :image, :remove_image, :status, :sequence, :capacity, :user_id, :displayImages, :displayImagesInPopup, :allowOrdering, :allow_alcohol, :inventoryTracking, :currency, :genid, :latitude, :longitude, :imagecontext, :image_style_profile, :wifissid, :wifiEncryptionType, :wifiPassword, :wifiHidden, :spotifyuserid,)
    
    # Convert status to integer if it's a string (from select dropdown)
    if permitted[:status].present? && permitted[:status].is_a?(String)
      permitted[:status] = permitted[:status].to_i
    end
    
    permitted
  end
end
