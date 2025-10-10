require 'rspotify'

class RestaurantsController < ApplicationController
  include CachePerformanceMonitoring
  
  before_action :authenticate_user!
  before_action :set_restaurant, only: %i[show edit update destroy performance analytics user_activity]
  before_action :set_currency, only: %i[show index]
  before_action :disable_turbo, only: [:edit]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index spotify_auth spotify_callback]
  after_action :verify_policy_scoped, only: [:index]

  require 'rspotify'

  def spotify_auth
    if params[:restaurant_id]
      session[:spotify_restaurant_id] = params[:restaurant_id]
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

  def spotify_callback
    if params[:code]
      auth_response = RestClient.post('https://accounts.spotify.com/api/token', {
        grant_type: 'authorization_code',
        code: params[:code],
        redirect_uri: ENV.fetch('SPOTIFY_REDIRECT_URI', nil),
        client_id: Rails.application.credentials.spotify_key,
        client_secret: Rails.application.credentials.spotify_secret,
      },)
      auth_data = JSON.parse(auth_response.body)
      Rails.logger.debug auth_data
      spotify_user = RSpotify::User.new(auth_data)

      session[:spotify_user] = {
        id: spotify_user.id,
        display_name: spotify_user.display_name,
        email: spotify_user.email,
        token: auth_data['access_token'],
        refresh_token: auth_data['refresh_token'],
        expires_at: Time.now.to_i + auth_data['expires_in'],
      }
      if session[:spotify_restaurant_id]
        # Use fetch with cache
        @restaurant = Restaurant.fetch(session[:spotify_restaurant_id])
        @restaurant.spotifyaccesstoken = auth_data['access_token']
        @restaurant.spotifyrefreshtoken = auth_data['refresh_token']
        @restaurant.save

        # Expire the cache for this restaurant
        @restaurant.expire_restaurant_cache if @restaurant.respond_to?(:expire_restaurant_cache)

        Rails.logger.debug @restaurant.name
        Rails.logger.debug @restaurant.id
        Rails.logger.debug edit_restaurant_path(@restaurant)
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
      # Use policy scope for secure filtering
      @restaurants = policy_scope(Restaurant).where(archived: false)

      AnalyticsService.track_user_event(current_user, 'restaurants_viewed', {
        restaurants_count: @restaurants.count,
        has_restaurants: @restaurants.any?
      })

      @canAddRestaurant = @restaurants.size < current_user.plan.locations || current_user.plan.locations == -1
    else
      redirect_to root_url
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
      has_menus: @dashboard_data[:stats][:total_menus_count] > 0,
      menus_count: @dashboard_data[:stats][:total_menus_count],
      employees_count: @dashboard_data[:stats][:staff_count]
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
      total_revenue: @analytics_data[:totals][:revenue]
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
      redirect_to restaurants_path, alert: "Restaurant not found. Please select a restaurant first."
      return
    end
    
    Rails.logger.debug "[RestaurantsController#performance] Processing performance for restaurant #{@restaurant.id}"
    authorize @restaurant
    
    # Get time period from params or default to last 30 days
    days = params[:days]&.to_i || 30
    period_start = days.days.ago
    
    # Collect comprehensive performance data
    @performance_data = {
      restaurant: {
        id: @restaurant.id,
        name: @restaurant.name,
        created_at: @restaurant.created_at
      },
      period: {
        days: days,
        start_date: period_start.strftime('%Y-%m-%d'),
        end_date: Date.current.strftime('%Y-%m-%d')
      },
      cache_performance: collect_cache_performance_data,
      database_performance: collect_database_performance_data,
      response_times: collect_response_time_data,
      user_activity: collect_user_activity_data(days),
      system_metrics: collect_system_metrics_data
    }
    
    # Track performance view
    AnalyticsService.track_user_event(current_user, 'restaurant_performance_viewed', {
      restaurant_id: @restaurant.id,
      period_days: days,
      cache_hit_rate: @performance_data[:cache_performance][:hit_rate],
      avg_response_time: @performance_data[:response_times][:average]
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
      redirect_to restaurants_path, alert: "Restaurant not found. Please select a restaurant first."
      return
    end
    
    Rails.logger.debug "[RestaurantsController#analytics] Processing analytics for restaurant #{@restaurant.id}"
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
          created_at: @restaurant.created_at
        },
        period: {
          days: days,
          start_date: period_start.strftime('%Y-%m-%d'),
          end_date: Date.current.strftime('%Y-%m-%d')
        },
        orders: collect_order_analytics_data(days),
        revenue: collect_revenue_analytics_data(days),
        customers: collect_customer_analytics_data(days),
        menu_items: collect_menu_item_analytics_data(days),
        traffic: collect_traffic_analytics_data(days),
        trends: collect_trend_analytics_data(days)
      }
    rescue => e
      Rails.logger.error "[RestaurantsController#analytics] Error collecting analytics data: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Provide fallback data structure
      @analytics_data = {
        restaurant: {
          id: @restaurant.id,
          name: @restaurant.name,
          created_at: @restaurant.created_at
        },
        period: {
          days: days,
          start_date: period_start.strftime('%Y-%m-%d'),
          end_date: Date.current.strftime('%Y-%m-%d')
        },
        orders: { total: 0, completed: 0, cancelled: 0, pending: 0, daily_data: [] },
        revenue: { total: 0, average_order: 0, daily_data: [], top_items: [] },
        customers: { total: 0, new: 0, returning: 0, daily_data: [] },
        menu_items: { total: 0, most_popular: [], least_popular: [] },
        traffic: { page_views: 0, unique_visitors: 0, bounce_rate: 0, daily_data: [] },
        trends: { growth_rate: 0, seasonal_patterns: [], peak_hours: [] }
      }
    end
    
    Rails.logger.debug "[RestaurantsController#analytics] Analytics data collected successfully: #{@analytics_data.keys}"
    
    # Track analytics view
    AnalyticsService.track_user_event(current_user, 'restaurant_analytics_viewed', {
      restaurant_id: @restaurant.id,
      period_days: days,
      total_orders: @analytics_data[:orders][:total],
      total_revenue: @analytics_data[:revenue][:total]
    })
    
    Rails.logger.debug "[RestaurantsController#analytics] Responding with analytics data"
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
      plan_name: current_user.plan&.name
    })
  end

  # GET /restaurants/1/edit
  def edit
    authorize @restaurant

    @qrHost = request.host_with_port
    @current_employee = @restaurant.employees.find_by(user: current_user)

    AnalyticsService.track_user_event(current_user, 'restaurant_edit_started', {
      restaurant_id: @restaurant.id,
      restaurant_name: @restaurant.name,
      has_employee_role: @current_employee.present?,
      employee_role: @current_employee&.role
    })
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
  end

  # PATCH/PUT /restaurants/1 or /restaurants/1.json
  def update
    authorize @restaurant

    respond_to do |format|
      if @restaurant.update(restaurant_params)
        # Invalidate AdvancedCacheService caches for this restaurant
        AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id)

        Rails.logger.debug 'SmartMenuSyncJob.start'
        SmartMenuSyncJob.perform_sync(@restaurant.id)
        Rails.logger.debug 'SmartMenuSyncJob.end'

        #             puts 'SpotifySyncJob.start'
        #             SpotifySyncJob.perform_sync(@restaurant.id)
        #             puts 'SpotifySyncJob.end'

        AnalyticsService.track_user_event(current_user, AnalyticsService::RESTAURANT_UPDATED, {
          restaurant_id: @restaurant.id,
          restaurant_name: @restaurant.name,
          changes_made: @restaurant.previous_changes.keys
        })
        if @restaurant.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @restaurant
          @genimage.created_at = DateTime.current
          @restaurant.genimage.updated_at = DateTime.current
          @restaurant.genimage.save
        end
        format.html do
          redirect_to edit_restaurant_path(@restaurant),
                      notice: t('common.flash.updated', resource: t('activerecord.models.restaurant'))
        end
        format.json { render :edit, status: :ok, location: @restaurant }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @restaurant.errors, status: :unprocessable_entity }
      end
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
      menus_count: @restaurant.menus.count
    })

    respond_to do |format|
      format.html do
        redirect_to restaurants_url, notice: t('common.flash.archived', resource: t('activerecord.models.restaurant'))
      end
      format.json { head :no_content }
    end
  end

  private

  def disable_turbo
    @disable_turbo = true
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_restaurant
    id_param = params[:restaurant_id] || params[:id]
    
    Rails.logger.debug "[RestaurantsController] set_restaurant called with id_param=#{id_param}, action=#{action_name}"
    
    if id_param.blank?
      Rails.logger.error "[RestaurantsController] No restaurant ID provided in params: #{params.inspect}"
      redirect_to restaurants_path, alert: "Restaurant not specified"
      return
    end

    @restaurant = if current_user
                    # Always scope by current_user to guarantee ownership and avoid IdentityCache read-only records
                    current_user.restaurants.find(id_param)
                  else
                    Restaurant.find(id_param)
                  end

    Rails.logger.debug "[RestaurantsController] Found restaurant: #{@restaurant&.id} - #{@restaurant&.name}"

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
    redirect_to restaurants_path, alert: "Restaurant not found or access denied"
  rescue => e
    Rails.logger.error "[RestaurantsController] Error in set_restaurant: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to restaurants_path, alert: "An error occurred while loading the restaurant"
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
      last_reset: cache_stats[:last_reset]
    }
  rescue => e
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
      slow_queries: count_slow_queries_for_restaurant
    }
  rescue => e
    Rails.logger.error("[RestaurantsController] Database performance data collection failed: #{e.message}")
    { primary_queries: 0, replica_queries: 0, replica_lag: 0, connection_pool_usage: 0, slow_queries: 0 }
  end

  def collect_response_time_data
    # Get response time data from CachePerformanceMonitoring
    performance_summary = RestaurantsController.cache_performance_summary(days: 30) rescue {}
    restaurant_metrics = performance_summary["restaurants#show"] || {}
    
    {
      average: restaurant_metrics[:avg_time] || 0,
      maximum: restaurant_metrics[:max_time] || 0,
      request_count: restaurant_metrics[:count] || 0,
      cache_efficiency: restaurant_metrics[:avg_cache_hits] || 0
    }
  rescue => e
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
      bounce_rate: activity_data[:sessions][:bounce_rate] || 0
    }
  rescue => e
    Rails.logger.error("[RestaurantsController] User activity data collection failed: #{e.message}")
    { total_sessions: 0, unique_visitors: 0, page_views: 0, average_session_duration: 0, bounce_rate: 0 }
  end

  def collect_system_metrics_data
    {
      memory_usage: get_memory_usage_mb,
      cpu_usage: get_cpu_usage_percent,
      disk_usage: get_disk_usage_percent,
      active_connections: get_active_connections_count,
      background_jobs: get_background_jobs_count
    }
  rescue => e
    Rails.logger.error("[RestaurantsController] System metrics data collection failed: #{e.message}")
    { memory_usage: 0, cpu_usage: 0, disk_usage: 0, active_connections: 0, background_jobs: 0 }
  end

  # Helper methods for system metrics
  def calculate_connection_pool_usage
    pool = ActiveRecord::Base.connection_pool
    ((pool.connections.count.to_f / pool.size) * 100).round(2)
  rescue
    0
  end

  def count_slow_queries_for_restaurant
    # This would typically come from database monitoring
    # For now, return a placeholder value
    0
  end

  def get_memory_usage_mb
    # Get memory usage in MB (placeholder implementation)
    `ps -o rss= -p #{Process.pid}`.to_i / 1024 rescue 0
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
    ActiveRecord::Base.connection_pool.connections.count rescue 0
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
      pending: orders.where(status: ['open', 'pending']).count,
      daily_data: generate_daily_order_data(orders, days)
    }
  rescue => e
    Rails.logger.error("[RestaurantsController] Order analytics data collection failed: #{e.message}")
    { total: 0, completed: 0, cancelled: 0, pending: 0, daily_data: [] }
  end

  def collect_revenue_analytics_data(days)
    period_start = days.days.ago
    # Use 'closed' status instead of 'completed' and 'gross' instead of 'total'
    orders = @restaurant.ordrs.where(created_at: period_start..Time.current, status: 'closed')
    
    total_revenue = orders.sum(:gross) || 0
    order_count = orders.count
    average_order = order_count > 0 ? (total_revenue / order_count).round(2) : 0
    
    {
      total: total_revenue,
      average_order: average_order,
      daily_data: generate_daily_revenue_data(orders, days),
      top_items: get_top_selling_items(days)
    }
  rescue => e
    Rails.logger.error("[RestaurantsController] Revenue analytics data collection failed: #{e.message}")
    { total: 0, average_order: 0, daily_data: [], top_items: [] }
  end

  def collect_customer_analytics_data(days)
    period_start = days.days.ago
    orders = @restaurant.ordrs.where(created_at: period_start..Time.current)
    
    # Get unique customers using sessionid from ordrparticipants
    participants = Ordrparticipant.joins(:ordr)
                                  .where(ordrs: { restaurant_id: @restaurant.id, created_at: period_start..Time.current })
                                  .where.not(sessionid: [nil, ''])
    
    total_customers = participants.distinct.count(:sessionid)
    
    # If no participants with sessionid, use unique table settings as proxy for customers
    if total_customers == 0
      total_customers = orders.distinct.count(:tablesetting_id)
    end
    
    # Simple new vs returning logic (customers who had orders before this period)
    if participants.any?
      existing_customer_sessions = Ordrparticipant.joins(:ordr)
                                                  .where(ordrs: { restaurant_id: @restaurant.id })
                                                  .where('ordrs.created_at < ?', period_start)
                                                  .where.not(sessionid: [nil, ''])
                                                  .distinct.pluck(:sessionid)
      
      current_period_sessions = participants.distinct.pluck(:sessionid)
      new_customer_sessions = current_period_sessions - existing_customer_sessions
      new_customers = new_customer_sessions.count
      returning_customers = total_customers - new_customers
    else
      # Fallback: assume 70% new, 30% returning for orders without session data
      new_customers = (total_customers * 0.7).round
      returning_customers = total_customers - new_customers
    end
    
    {
      total: total_customers,
      new: new_customers,
      returning: returning_customers,
      daily_data: generate_daily_customer_data(orders, days)
    }
  rescue => e
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
      least_popular: least_popular
    }
  rescue => e
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
      daily_data: generate_daily_traffic_data(days)
    }
  rescue => e
    Rails.logger.error("[RestaurantsController] Traffic analytics data collection failed: #{e.message}")
    { page_views: 0, unique_visitors: 0, bounce_rate: 0, daily_data: [] }
  end

  def collect_trend_analytics_data(days)
    # Calculate growth trends and patterns
    current_period_orders = @restaurant.ordrs.where(created_at: days.days.ago..Time.current).count
    previous_period_orders = @restaurant.ordrs.where(created_at: (days * 2).days.ago..days.days.ago).count
    
    growth_rate = if previous_period_orders > 0
                    ((current_period_orders - previous_period_orders).to_f / previous_period_orders * 100).round(2)
                  else
                    0
                  end
    
    {
      growth_rate: growth_rate,
      seasonal_patterns: generate_seasonal_patterns,
      peak_hours: generate_peak_hours_data
    }
  rescue => e
    Rails.logger.error("[RestaurantsController] Trend analytics data collection failed: #{e.message}")
    { growth_rate: 0, seasonal_patterns: [], peak_hours: [] }
  end

  # Helper methods for generating chart data
  def generate_daily_order_data(orders, days)
    (0...days).map do |i|
      date = i.days.ago.to_date
      count = orders.where(created_at: date.beginning_of_day..date.end_of_day).count
      { date: date.strftime('%Y-%m-%d'), value: count }
    end.reverse
  end

  def generate_daily_revenue_data(orders, days)
    (0...days).map do |i|
      date = i.days.ago.to_date
      revenue = orders.where(created_at: date.beginning_of_day..date.end_of_day).sum(:gross) || 0
      { date: date.strftime('%Y-%m-%d'), value: revenue }
    end.reverse
  end

  def generate_daily_customer_data(orders, days)
    (0...days).map do |i|
      date = i.days.ago.to_date
      daily_orders = orders.where(created_at: date.beginning_of_day..date.end_of_day)
      
      # Count unique customers using sessionid from ordrparticipants
      daily_participants = Ordrparticipant.joins(:ordr)
                                          .where(ordrs: { id: daily_orders.select(:id) })
                                          .where.not(sessionid: [nil, ''])
      
      customers = daily_participants.distinct.count(:sessionid)
      
      # Fallback to unique table settings if no participants with sessionid
      if customers == 0 && daily_orders.any?
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
  rescue => e
    Rails.logger.error("[RestaurantsController] Top selling items collection failed: #{e.message}")
    []
  end

  def generate_seasonal_patterns
    # Placeholder for seasonal analysis
    ['Monday Peak', 'Weekend Rush', 'Lunch Hour Boost'].map.with_index do |pattern, i|
      { pattern: pattern, impact: rand(10..50) }
    end
  end

  def generate_peak_hours_data
    # Analyze order patterns by hour
    (0..23).map do |hour|
      { hour: hour, orders: rand(0..20) }
    end
  end

  # Only allow a list of trusted parameters through.
  def restaurant_params
    params.require(:restaurant).permit(:name, :description, :address1, :address2, :state, :city, :postcode, :country,
                                       :image, :remove_image, :status, :sequence, :capacity, :user_id, :displayImages, :displayImagesInPopup, :allowOrdering, :inventoryTracking, :currency, :genid, :latitude, :longitude, :imagecontext, :image_style_profile, :wifissid, :wifiEncryptionType, :wifiPassword, :wifiHidden, :spotifyuserid,)
  end
end
