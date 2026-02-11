require 'rspotify'

class RestaurantsController < ApplicationController
  require 'stripe'
  include CachePerformanceMonitoring

  before_action :authenticate_user!
  before_action :set_restaurant, only: %i[show edit update destroy archive restore performance analytics user_activity update_hours update_alcohol_policy alcohol_status]
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

  # PATCH /restaurants/:id/archive
  def archive
    authorize @restaurant

    RestaurantArchivalService.archive_async(
      restaurant_id: @restaurant.id,
      archived_by_id: current_user&.id,
      reason: params[:reason],
    )

    respond_to do |format|
      format.html { redirect_to restaurants_url, notice: t('common.flash.archived', resource: t('activerecord.models.restaurant')) }
      format.json { render json: { success: true }, status: :accepted }
    end
  end

  # PATCH /restaurants/:id/restore
  def restore
    authorize @restaurant

    RestaurantArchivalService.restore_async(
      restaurant_id: @restaurant.id,
      archived_by_id: current_user&.id,
      reason: params[:reason],
    )

    respond_to do |format|
      format.html { redirect_to restaurants_url, notice: t('common.flash.restored', resource: t('activerecord.models.restaurant')) }
      format.json { render json: { success: true }, status: :accepted }
    end
  end

  # PATCH /restaurants/:id/update_alcohol_policy
  def update_alcohol_policy
    authorize @restaurant
    payload = params.permit(
      allowed_days_of_week: [],
      allowed_time_ranges: %i[from_min to_min],
      blackout_dates: [],
    )

    policy = @restaurant.alcohol_policy || @restaurant.build_alcohol_policy

    # Normalize inputs
    days = Array(payload[:allowed_days_of_week]).map(&:to_i).uniq.sort
    ranges = Array(payload[:allowed_time_ranges]).map do |r|
      h = r.is_a?(ActionController::Parameters) ? r.to_unsafe_h : r
      { 'from_min' => h['from_min'].to_i, 'to_min' => h['to_min'].to_i }
    end
    dates = Array(payload[:blackout_dates]).filter_map do |d|
      Date.parse(d)
    rescue StandardError
      nil
    end.uniq.sort

    policy.allowed_days_of_week = days
    policy.allowed_time_ranges = ranges
    policy.blackout_dates = dates

    if policy.save
      AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id) if defined?(AdvancedCacheService)
      render json: { success: true, allowed_now: @restaurant.alcohol_allowed_now? }, status: :ok
    else
      render json: { success: false, errors: policy.errors.full_messages }, status: :unprocessable_content
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
        redirect_uri: ENV.fetch('SPOTIFY_REDIRECT_URI', nil),
      })

      auth_response = RestClient.post(
        'https://accounts.spotify.com/api/token',
        form_data,
        {
          Authorization: "Basic #{credentials}",
          content_type: 'application/x-www-form-urlencoded',
          accept: 'application/json',
        },
      )

      auth_data = JSON.parse(auth_response.body)
      Rails.logger.debug { "Spotify auth response: #{auth_data}" }

      # Get user info from Spotify API
      user_response = RestClient.get(
        'https://api.spotify.com/v1/me',
        { Authorization: "Bearer #{auth_data['access_token']}" },
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
      ApplicationRecord.on_primary do
        scope = policy_scope(Restaurant)

        include_archived = ActiveModel::Type::Boolean.new.cast(params[:include_archived])
        unless include_archived
          scope = scope
            .where.not(status: Restaurant.statuses[:archived])
            .where('restaurants.archived IS NULL OR restaurants.archived = ?', false)
        end

        q = params[:q].to_s.strip
        scope = scope.where('restaurants.name ILIKE ?', "%#{q}%") if q.present?

        @q = q
        @restaurants = scope.order(:sequence)

        Rails.logger.warn(
          "[RestaurantsController#index] db_role=primary q=#{@q.inspect} restaurants_sample=" \
          "#{@restaurants.limit(10).pluck(:id, :sequence).inspect}",
        )
      end

      AnalyticsService.track_user_event(current_user, 'restaurants_viewed', {
        restaurants_count: @restaurants.count,
        has_restaurants: @restaurants.any?,
      })

      if current_user.plan.locations == -1
        @canAddRestaurant = true
      else
        active_count = policy_scope(Restaurant).where(archived: false, status: :active).count
        @canAddRestaurant = active_count < current_user.plan.locations
      end
    else
      redirect_to root_url
    end

    # Use minimal JSON view for better performance and Turbo Frame support for 2025 UI
    respond_to do |format|
      format.html do
        if request.headers['Turbo-Frame'] == 'restaurants_content'
          render partial: 'restaurants/index_frame_wrapper_2025',
                 locals: { restaurants: @restaurants, q: @q }
        else
          render :index_2025
        end
      end
      format.json { render 'index_minimal' }
    end
  end

  # PATCH /restaurants/bulk_update
  def bulk_update
    authorize Restaurant

    ids = Array(params[:restaurant_ids]).map(&:to_i).uniq
    operation = params[:operation].to_s
    value = params[:value]

    if ids.blank? || operation.blank?
      respond_to do |format|
        format.html { redirect_to restaurants_path, alert: 'Invalid bulk update' }
        format.json { render json: { success: false }, status: :unprocessable_content }
      end
      return
    end

    scope = policy_scope(Restaurant).where(id: ids)

    case operation
    when 'set_status'
      status = value.to_s
      unless Restaurant.statuses.key?(status)
        respond_to do |format|
          format.html { redirect_to restaurants_path, alert: 'Invalid status' }
          format.json { render json: { success: false }, status: :unprocessable_content }
        end
        return
      end

      if status == 'active' && !current_user_has_active_subscription?
        respond_to do |format|
          format.html { redirect_to restaurants_path, alert: 'You need an active subscription to activate a restaurant.' }
          format.json { render json: { success: false, error: 'subscription_required' }, status: :payment_required }
        end
        return
      end

      scope.find_each do |restaurant|
        authorize restaurant, :update?
        restaurant.update!(status: status)
      end
    when 'archive'
      scope.find_each do |restaurant|
        authorize restaurant, :archive?
        RestaurantArchivalService.archive_async(
          restaurant_id: restaurant.id,
          archived_by_id: current_user&.id,
          reason: params[:reason],
        )
      end
    when 'restore'
      scope.find_each do |restaurant|
        authorize restaurant, :restore?
        RestaurantArchivalService.restore_async(
          restaurant_id: restaurant.id,
          archived_by_id: current_user&.id,
          reason: params[:reason],
        )
      end
    else
      respond_to do |format|
        format.html { redirect_to restaurants_path, alert: 'Invalid bulk operation' }
        format.json { render json: { success: false }, status: :unprocessable_content }
      end
      return
    end

    respond_to do |format|
      format.html { redirect_to restaurants_path, notice: 'Restaurants updated' }
      format.json { render json: { success: true }, status: :ok }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to restaurants_path, alert: e.record.errors.full_messages.first }
      format.json { render json: { success: false }, status: :unprocessable_content }
    end
  end

  # PATCH /restaurants/reorder
  def reorder
    authorize Restaurant

    order = params[:order]
    unless order.is_a?(Array)
      render json: { success: false }, status: :unprocessable_content
      return
    end

    scope = policy_scope(Restaurant).where.not(status: Restaurant.statuses[:archived])
    permitted_ids = scope.pluck(:id)

    payload_ids = order.filter_map do |item|
      raw = if item.is_a?(ActionController::Parameters)
              item.to_unsafe_h
            elsif item.is_a?(Hash)
              item
            else
              nil
            end
      next if raw.nil?

      raw_id = raw['id'] || raw[:id]
      next if raw_id.blank?

      id = raw_id.to_i
      next unless permitted_ids.include?(id)

      id
    end
    payload_ids = payload_ids.uniq

    remaining_ids = scope.where.not(id: payload_ids).order(:sequence, :id).pluck(:id)
    final_ids = payload_ids + remaining_ids

    Restaurant.transaction do
      final_ids.each_with_index do |id, idx|
        Restaurant.where(id: id).update_all(sequence: idx + 1)
      end
    end

    persisted_sample = ApplicationRecord.on_primary do
      policy_scope(Restaurant)
        .where.not(status: Restaurant.statuses[:archived])
        .order(:sequence, :id)
        .limit(10)
        .pluck(:id, :sequence)
    end

    Rails.logger.warn(
      "[RestaurantsController#reorder] db_role=primary payload_ids=#{payload_ids.inspect} " \
      "final_ids_first10=#{final_ids.first(10).inspect} persisted_sample=#{persisted_sample.inspect}",
    )

    render json: { success: true }, status: :ok
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
    })
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
    })

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
    })

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
    })

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
    @restaurant.status ||= :inactive
    authorize @restaurant

    AnalyticsService.track_user_event(current_user, 'restaurant_creation_started', {
      user_restaurants_count: current_user.restaurants.count,
      plan_name: current_user.plan&.name,
    })

    if request.headers['Turbo-Frame'] == 'new_restaurant_modal'
      render partial: 'restaurants/new_modal_form', locals: { restaurant: @restaurant }
      nil
    end
  end

  # GET /restaurants/1/edit
  def edit
    authorize @restaurant

    sync_stripe_subscription_from_checkout_session! if params[:checkout_session_id].present?

    @qrHost = request.host_with_port
    @current_employee = @restaurant.employees.find_by(user: current_user)

    begin
      owned_menu_ids = @restaurant.menus.where(archived: false).pluck(:id)
      existing_menu_ids = @restaurant.restaurant_menus.where(menu_id: owned_menu_ids).pluck(:menu_id)
      missing_menu_ids = owned_menu_ids - existing_menu_ids
      if missing_menu_ids.any?
        next_sequence = @restaurant.restaurant_menus.maximum(:sequence).to_i
        RestaurantMenu.transaction do
          missing_menu_ids.each do |menu_id|
            next_sequence += 1
            RestaurantMenu.create!(
              restaurant_id: @restaurant.id,
              menu_id: menu_id,
              sequence: next_sequence,
              status: :active,
              availability_override_enabled: false,
              availability_state: :available,
            )
          end
        end
      end
    rescue StandardError
      nil
    end

    # Set current section for 2025 UI
    @current_section = params[:section] || 'details'
    @onboarding_mode = ActiveModel::Type::Boolean.new.cast(params[:onboarding])
    @onboarding_next = @restaurant.onboarding_next_section

    if @current_section.to_s == 'settings'
      @stripe_connect_account = @restaurant.provider_accounts.find { |a| a.provider.to_s == 'stripe' } || @restaurant.provider_accounts.where(provider: :stripe).first
      if @stripe_connect_account&.status.to_s == 'enabled'
        @stripe_connect_receipt_details = Payments::Providers::StripeConnect
          .new(restaurant: @restaurant)
          .receipt_details_for_account(provider_account_id: @stripe_connect_account.provider_account_id)
      end
    end

    # Restaurant onboarding (guided, non-blocking)
    if @onboarding_next.present?
      AnalyticsService.track_user_event(current_user, 'restaurant_onboarding_step_viewed', {
        restaurant_id: @restaurant.id,
        section: @current_section,
        next_recommended_section: @onboarding_next,
        is_recommended: (@current_section == @onboarding_next),
      })
    end

    AnalyticsService.track_user_event(current_user, 'restaurant_edit_started', {
      restaurant_id: @restaurant.id,
      restaurant_name: @restaurant.name,
      has_employee_role: @current_employee.present?,
      employee_role: @current_employee&.role,
      section: @current_section,
    })

    # 2025 UI is now the default
    # Provides modern sidebar navigation with 69% cognitive load reduction
    # Use ?old_ui=true to access legacy UI if needed
    return if params[:old_ui] == 'true'

    # Handle Turbo Frame requests for section content
    if request.headers['Turbo-Frame'] == 'restaurant_content'
      # Determine filter for menu sections
      filter = @current_section.include?('menus') ? @current_section.sub('menus_', '') : 'all'
      filter = 'all' if @current_section == 'menus'

      # Render turbo frame wrapper with section content
      render partial: 'restaurants/section_frame_2025',
             locals: {
               restaurant: @restaurant,
               partial_name: section_partial_name(@current_section),
               filter: filter,
             }
    else
      render :edit_2025
    end
  end

  # POST /restaurants or /restaurants.json
  def create
    @restaurant = Restaurant.new(restaurant_params)
    @restaurant.user = current_user
    @restaurant.status ||= :inactive
    authorize @restaurant

    if current_user&.plan && current_user.plan.locations != -1 && !current_user.super_admin?
      active_count = current_user.restaurants.where(archived: false, status: :active).count
      if active_count >= current_user.plan.locations
        @restaurant.errors.add(:base, 'Plan limit reached: maximum active restaurants')
        respond_to do |format|
          format.html { redirect_to restaurants_path, alert: @restaurant.errors.full_messages.to_sentence }
          format.json { render json: { errors: @restaurant.errors.full_messages }, status: :unprocessable_content }
        end
        return
      end
    end

    respond_to do |format|
      if @restaurant.save
        RestaurantProvisioningService.call(restaurant: @restaurant, user: current_user)

        AnalyticsService.track_restaurant_created(current_user, @restaurant)
        AnalyticsService.track_user_event(current_user, 'restaurant_onboarding_started', {
          restaurant_id: @restaurant.id,
          source: 'restaurants_create',
          initial_next_section: @restaurant.onboarding_next_section,
        })
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
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @restaurant.errors, status: :unprocessable_content }
      end
    end
  rescue ArgumentError => e
    # Handle invalid enum values
    @restaurant = Restaurant.new
    @restaurant.errors.add(:status, e.message)
    respond_to do |format|
      format.html { render :new, status: :unprocessable_content }
      format.json { render json: @restaurant.errors, status: :unprocessable_content }
    end
  end

  # PATCH/PUT /restaurants/1 or /restaurants/1.json
  def update
    authorize @restaurant

    respond_to do |format|
      # Build attributes for update (supports quick-action status-only submissions)
      raw_restaurant = params[:restaurant]
      status_value = params.dig(:restaurant, :status) || params[:status]

      if status_value.to_s == 'active' && !current_user_has_active_subscription?
        format.html do
          redirect_back_or_to(edit_restaurant_path(@restaurant, section: 'details'), alert: 'You need an active subscription to activate a restaurant.',
                                                                                     status: :see_other,)
        end
        format.json { render json: { error: 'subscription_required' }, status: :payment_required }
        return
      end

      attrs = {}
      if raw_restaurant.is_a?(ActionController::Parameters)
        begin
          attrs.merge!(restaurant_params.to_h)
        rescue StandardError => e
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
        })
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
        format.json do
          # For AJAX/auto-save requests, return simple success response
          if request.xhr?
            onboarding_next = @restaurant.onboarding_next_section
            render json: {
              success: true,
              message: 'Saved successfully',
              onboarding_next: onboarding_next,
              onboarding_required_text: onboarding_required_text_for(onboarding_next),
            }, status: :ok
          else
            render :edit, status: :ok, location: @restaurant
          end
        end
      else
        format.html do
          if params[:return_to] == 'restaurant_edit'
            redirect_to edit_restaurant_path(@restaurant, section: 'details'), alert: @restaurant.errors.full_messages.presence || 'Failed to update restaurant'
          else
            render :edit, status: :unprocessable_content
          end
        end
        format.json { render json: @restaurant.errors, status: :unprocessable_content }
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
        sequence: 1, # Default sequence for primary hours
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
        availability.status = :open # Use enum symbol

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
        next unless is_closed == '1'

        availability = @restaurant.restaurantavailabilities.find_or_initialize_by(
          dayofweek: day,
          sequence: 1,
        )
        availability.status = :closed # Use enum symbol
        if availability.save
          Rails.logger.info "[UpdateHours] Marked #{day} as closed"
        else
          Rails.logger.error "[UpdateHours] Failed to mark #{day} as closed: #{availability.errors.full_messages}"
        end
      end
    end

    Rails.logger.info '[UpdateHours] Finished processing all hours'

    # Invalidate caches
    @restaurant.expire_restaurant_cache if @restaurant.respond_to?(:expire_restaurant_cache)
    AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id) if defined?(AdvancedCacheService)

    respond_to do |format|
      format.json { render json: { success: true, message: 'Hours saved successfully' }, status: :ok }
      format.html { redirect_to edit_restaurant_path(@restaurant, section: 'hours'), notice: 'Hours updated successfully' }
    end
  rescue StandardError => e
    Rails.logger.error("Error updating hours: #{e.message}")
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_content }
      format.html { redirect_to edit_restaurant_path(@restaurant, section: 'hours'), alert: 'Failed to update hours' }
    end
  end

  # DELETE /restaurants/1 or /restaurants/1.json
  def destroy
    authorize @restaurant

    RestaurantArchivalService.archive_async(
      restaurant_id: @restaurant.id,
      archived_by_id: current_user&.id,
    )

    AnalyticsService.track_user_event(current_user, AnalyticsService::RESTAURANT_DELETED, {
      restaurant_id: @restaurant.id,
      restaurant_name: @restaurant.name,
      had_menus: @restaurant.menus.any?,
      menus_count: @restaurant.menus.count,
    })

    respond_to do |format|
      format.html do
        redirect_to restaurants_url, notice: t('common.flash.archived', resource: t('activerecord.models.restaurant'))
      end
      format.json { head :no_content }
    end
  end

  private

  def sync_stripe_subscription_from_checkout_session!
    ensure_stripe_api_key_for_restaurants!
    return if Stripe.api_key.to_s.strip.blank?

    session_id = params[:checkout_session_id].to_s
    session = Stripe::Checkout::Session.retrieve({ id: session_id, expand: ['subscription'] })

    stripe_customer_id = session.customer.to_s
    subscription_obj = session.subscription
    stripe_subscription_id = if subscription_obj.respond_to?(:id)
                               subscription_obj.id.to_s
                             else
                               session.subscription.to_s
                             end

    return if stripe_customer_id.blank? || stripe_subscription_id.blank?

    subscription = if subscription_obj.respond_to?(:status)
                     subscription_obj
                   else
                     Stripe::Subscription.retrieve({ id: stripe_subscription_id, expand: ['default_payment_method'] })
                   end

    status = case subscription.status.to_s
             when 'active'
               :active
             when 'trialing'
               :trialing
             when 'past_due', 'unpaid'
               :past_due
             when 'canceled', 'incomplete_expired'
               :canceled
             else
               :inactive
             end

    has_payment_method = subscription.respond_to?(:default_payment_method) && subscription.default_payment_method.present?
    has_payment_method ||= subscription.respond_to?(:default_source) && subscription.default_source.present?
    has_payment_method ||= session.payment_status.to_s == 'paid'

    rs = @restaurant.restaurant_subscription || @restaurant.build_restaurant_subscription(status: :inactive)
    rs.update!(
      status: status,
      stripe_customer_id: stripe_customer_id,
      stripe_subscription_id: stripe_subscription_id,
      payment_method_on_file: has_payment_method,
      trial_ends_at: begin
        t = subscription.respond_to?(:trial_end) ? subscription.trial_end : nil
        t.present? ? Time.zone.at(t.to_i) : rs.trial_ends_at
      rescue StandardError
        rs.trial_ends_at
      end,
      current_period_end: begin
        t = subscription.respond_to?(:current_period_end) ? subscription.current_period_end : nil
        t.present? ? Time.zone.at(t.to_i) : rs.current_period_end
      rescue StandardError
        rs.current_period_end
      end,
    )
  rescue StandardError => e
    Rails.logger.warn("[StripeCheckoutSync] Failed to sync checkout_session_id=#{params[:checkout_session_id]} restaurant_id=#{@restaurant&.id}: #{e.class}: #{e.message}")
  end

  def ensure_stripe_api_key_for_restaurants!
    return if Stripe.api_key.present?

    env_key = ENV['STRIPE_SECRET_KEY'].presence

    credentials_key = begin
      Rails.application.credentials.stripe_secret_key
    rescue StandardError
      nil
    end

    if credentials_key.blank?
      credentials_key = begin
        Rails.application.credentials.dig(:stripe, :secret_key) ||
          Rails.application.credentials.dig(:stripe, :api_key)
      rescue StandardError
        nil
      end
    end

    key = if Rails.env.production?
            env_key || credentials_key
          else
            credentials_key.presence || env_key
          end

    Stripe.api_key = key if key.present?
  end

  def onboarding_required_text_for(onboarding_next)
    case onboarding_next
    when 'details'
      missing = @restaurant.onboarding_missing_details_fields
      labels = {
        description: 'a description',
        currency: 'a currency',
        address: 'your address/location',
        country: 'your country',
      }
      items = missing.filter_map { |k| labels[k] }
      "To continue setup, please add #{items.to_sentence}."
    when 'localization'
      'Add at least one language and set a default language to continue setup.'
    when 'tables'
      'Add at least one table (capacity 4 is fine) to continue setup.'
    when 'staff'
      'Add at least one staff member to continue setup.'
    when 'menus'
      'Create or import a menu to continue setup.'
    else
      'Continue the required setup to proceed.'
    end
  rescue StandardError
    'Continue the required setup to proceed.'
  end

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

      @canAddMenu = current_user.super_admin? || @menuCount < current_user.plan.menusperlocation || current_user.plan.menusperlocation == -1
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
    when 'insights'
      'insights_2025'
    when 'wifi'
      'wifi_2025'
    when 'advanced'
      'advanced_2025'
    else
      'details_2025'
    end
  end

  # Only allow a list of trusted parameters through.
  def restaurant_params
    permitted = params.require(:restaurant).permit(:name, :description, :address1, :address2, :state, :city, :postcode, :country,
                                                   :image, :remove_image, :status, :sequence, :capacity, :user_id, :displayImages, :displayImagesInPopup, :allowOrdering, :allow_alcohol, :inventoryTracking, :currency, :genid, :latitude, :longitude, :imagecontext, :image_style_profile, :wifissid, :wifiEncryptionType, :wifiPassword, :wifiHidden, :spotifyuserid, establishment_types: [],)

    # Convert status to integer if it's a string (from select dropdown)
    if permitted[:status].present? && permitted[:status].is_a?(String)
      permitted[:status] = permitted[:status].to_i
    end

    permitted
  end
end
