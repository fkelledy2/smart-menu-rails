require 'rqrcode'

class MenusController < ApplicationController
  include CachePerformanceMonitoring

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_restaurant
  before_action :set_menu, only: %i[show edit update destroy regenerate_images performance]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index performance]
  after_action :verify_policy_scoped, only: [:index]

  # GET	/restaurants/:restaurant_id/menus
  # GET /menus or /menus.json
  def index
    @today = Time.zone.today.strftime('%A').downcase!
    @currentHour = Time.now.strftime('%H').to_i
    @currentMin = Time.now.strftime('%M').to_i
    if current_user
      @menus = if @restaurant
                 policy_scope(Menu).where(restaurant_id: @restaurant.id, archived: false)
                   .includes([:menuavailabilities])
                   .order(:sequence).all
               else
                 policy_scope(Menu).where(archived: false).order(:sequence)
                   .includes([:menuavailabilities])
                   .all
               end
      AnalyticsService.track_user_event(current_user, 'menus_viewed', {
        menus_count: @menus.count,
        restaurant_id: @restaurant&.id,
        viewing_context: params[:restaurant_id] ? 'restaurant_specific' : 'all_menus',
      },)
    elsif params[:restaurant_id]
      @restaurant = Restaurant.find_by(id: params[:restaurant_id])
      @menus = Menu.where(restaurant: @restaurant).all
      @tablesettings = @restaurant.tablesettings
      anonymous_id = session[:session_id] ||= SecureRandom.uuid
      AnalyticsService.track_anonymous_event(anonymous_id, 'menus_viewed_anonymous', {
        menus_count: @menus.count,
        restaurant_id: @restaurant.id,
        restaurant_name: @restaurant.name,
      },)
    end
  end

  # POST /menus/:id/regenerate_images
  def regenerate_images
    authorize @menu, :update?

    if @menu.nil?
      redirect_to root_url and return
    end

    scope = Genimage.where(menu_id: @menu.id)
    queued = 0
    scope.find_each do |genimage|
      next if genimage.menuitem&.itemtype == 'wine'

      # Prefer async to avoid blocking the request
      GenerateImageJob.perform_async(genimage.id)
      queued += 1
    end

    flash[:notice] = t('menus.controller.image_regeneration_queued', count: queued)
    redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu)
  end

  # GET	/restaurants/:restaurant_id/menus/:menu_id/tablesettings/:id(.:format)	menus#show
  # GET	/restaurants/:restaurant_id/menus/:id(.:format)	 menus#show
  # GET /menus/1 or /menus/1.json
  def show
    # Always authorize - policy handles public vs private access
    authorize @menu
    if params[:menu_id] && params[:id]
      if params[:restaurant_id]
        @restaurant = Restaurant.find_by(id: params[:restaurant_id])
        @menu = Menu.find_by(id: params[:menu_id])
        if @menu.restaurant != @restaurant
          redirect_to root_url
        end

        # Use AdvancedCacheService for comprehensive menu data with localization
        locale = params[:locale] || 'en'
        @menu_data = AdvancedCacheService.cached_menu_with_items(@menu.id, locale: locale, include_inactive: false)

        # Trigger strategic cache warming for menu and restaurant data
        trigger_strategic_cache_warming

        if current_user
          AnalyticsService.track_user_event(current_user, AnalyticsService::MENU_VIEWED, {
            restaurant_id: @menu.restaurant.id,
            menu_id: @menu.id,
            menu_name: @menu.name,
            items_count: @menu_data[:metadata][:active_items],
            sections_count: @menu_data[:sections].count,
          },)
        else
          anonymous_id = session[:session_id] ||= SecureRandom.uuid
          AnalyticsService.track_anonymous_event(anonymous_id, 'menu_viewed_anonymous', {
            restaurant_id: @menu.restaurant.id,
            menu_id: @menu.id,
            menu_name: @menu.name,
            items_count: @menu_data[:metadata][:active_items],
          },)
        end
      end
      @participantsFirstTime = false
      @tablesetting = Tablesetting.find_by(id: params[:id])
      @openOrder = Ordr.where(menu_id: params[:menu_id], tablesetting_id: params[:id],
                              restaurant_id: @tablesetting.restaurant_id, status: 0,)
        .or(Ordr.where(menu_id: params[:menu_id], tablesetting_id: params[:id],
                       restaurant_id: @tablesetting.restaurant_id, status: 20,))
        .or(Ordr.where(menu_id: params[:menu_id], tablesetting_id: params[:id],
                       restaurant_id: @tablesetting.restaurant_id, status: 30,)).first
      if @openOrder
        @openOrder.nett = @openOrder.runningTotal
        taxes = Tax.where(restaurant_id: @openOrder.restaurant.id).order(sequence: :asc)
        totalTax = 0
        totalService = 0
        taxes.each do |tax|
          if tax.taxtype == 'service'
            totalService += ((tax.taxpercentage * @openOrder.nett) / 100)
          else
            totalTax += ((tax.taxpercentage * @openOrder.nett) / 100)
          end
        end
        @openOrder.tax = totalTax
        @openOrder.service = totalService
        @openOrder.gross = @openOrder.nett + @openOrder.tip + @openOrder.service + @openOrder.tax
        if current_user
          @ep = Ordrparticipant.where(ordr: @openOrder, employee: @current_employee, role: 1,
                                      sessionid: session.id.to_s,).first
          if @ep.nil?
            @ordrparticipant = Ordrparticipant.new(ordr: @openOrder, employee: @current_employee, role: 1,
                                                   sessionid: session.id.to_s,)
            @ordrparticipant.save
          end
        else
          @ep = Ordrparticipant.where(ordr_id: @openOrder.id, role: 0, sessionid: session.id.to_s).first
          if @ep.nil?
            @ordrparticipant = Ordrparticipant.new(ordr_id: @openOrder.id, role: 0,
                                                   sessionid: session.id.to_s,)
            @ordrparticipant.save
            @ordraction = Ordraction.new(ordrparticipant_id: @ordrparticipant.id, ordr: @openOrder, action: 0)
          else
            @ordrparticipant = @ep
            @ordraction = Ordraction.new(ordrparticipant: @ep, ordr: @openOrder, action: 0)
          end
          @ordraction.save
        end
      end
    else
      @menu = Menu.find_by(id: params[:id])
      @allergyns = Allergyn.where(restaurant_id: @menu.restaurant.id)
    end
  end

  # GET /menus/new
  def new
    @menu = Menu.new
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @menu.restaurant = @futureParentRestaurant
    end
    authorize @menu

    Analytics.track(
      user_id: current_user.id,
      event: 'menus.new',
      properties: {
        restaurant_id: @menu.restaurant&.id,
      },
    )
  end

  # GET /menus/1/edit
  def edit
    authorize @menu

    if params[:menu_id] && params[:id]
      if params[:restaurant_id]
        @restaurant = Restaurant.find_by(id: params[:restaurant_id])
        @menu = Menu.find_by(id: params[:menu_id])
        if @menu.restaurant != @restaurant
          redirect_to root_url
        end
      end
      Analytics.track(
        event: 'menus.edit',
        properties: {
          restaurant_id: @menu.restaurant.id,
          menu_id: @menu.id,
        },
      )
    end
    @qrURL = Rails.application.routes.url_helpers.restaurant_menu_url(@restaurant || @menu.restaurant, @menu,
                                                                      host: request.host_with_port,)
    @qrURL.sub! 'http', 'https'
    @qrURL.sub! '/edit', ''
    @qr = RQRCode::QRCode.new(@qrURL)
  end

  # POST /menus or /menus.json
  def create
    @menu = (@restaurant || Restaurant.find(menu_params[:restaurant_id])).menus.build(menu_params)
    authorize @menu

    respond_to do |format|
      # Remove PDF if requested
      if (params[:menu][:remove_pdf_menu_scan] == '1') && @menu.pdf_menu_scan.attached?
        @menu.pdf_menu_scan.purge
      end
      if @menu.save
        Analytics.track(
          user_id: current_user.id,
          event: 'menus.create',
          properties: {
            restaurant_id: @menu.restaurant.id,
            menu_id: @menu.id,
          },
        )
        if @menu.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @menu.restaurant
          @genimage.menu = @menu
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
        Rails.logger.debug 'SmartMenuSyncJob.start'
        SmartMenuSyncJob.perform_async(@menu.restaurant.id)
        Rails.logger.debug 'SmartMenuSyncJob.end'
        format.html do
          redirect_to edit_restaurant_path(id: @menu.restaurant.id),
                      notice: t('common.flash.created', resource: t('activerecord.models.menu'))
        end
        format.json do
          render :show, status: :created, location: restaurant_menu_url(@restaurant || @menu.restaurant, @menu)
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menus/1 or /menus/1.json
  def update
    authorize @menu

    respond_to do |format|
      # Remove PDF if requested
      if (params[:menu][:remove_pdf_menu_scan] == '1') && @menu.pdf_menu_scan.attached?
        @menu.pdf_menu_scan.purge
      end
      if @menu.update(menu_params)
        # Invalidate AdvancedCacheService caches for this menu
        AdvancedCacheService.invalidate_menu_caches(@menu.id)
        AdvancedCacheService.invalidate_restaurant_caches(@menu.restaurant.id)

        Analytics.track(
          user_id: current_user.id,
          event: 'menus.update',
          properties: {
            restaurant_id: @menu.restaurant.id,
            menu_id: @menu.id,
          },
        )
        if @menu.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @menu.restaurant
          @genimage.menu = @menu
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
        Rails.logger.debug 'SmartMenuSyncJob.start'
        SmartMenuSyncJob.perform_async(@menu.restaurant.id)
        Rails.logger.debug 'SmartMenuSyncJob.end'
        format.html do
          redirect_to edit_restaurant_path(id: @menu.restaurant.id),
                      notice: t('common.flash.updated', resource: t('activerecord.models.menu'))
        end
        format.json { render :show, status: :ok, location: restaurant_menu_url(@restaurant || @menu.restaurant, @menu) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menus/1 or /menus/1.json
  def destroy
    authorize @menu

    @menu.update(archived: true)

    # Invalidate AdvancedCacheService caches for this menu
    AdvancedCacheService.invalidate_menu_caches(@menu.id)
    AdvancedCacheService.invalidate_restaurant_caches(@menu.restaurant.id)

    Analytics.track(
      user_id: current_user.id,
      event: 'menus.destroy',
      properties: {
        restaurant_id: @menu.restaurant.id,
        menu_id: @menu.id,
      },
    )
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_path(id: @menu.restaurant.id),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.menu'))
      end
      format.json { head :no_content }
    end
  end

  # GET /menus/1/performance
  def performance
    authorize @menu, :show?

    # Get performance period from params or default to 30 days
    days = params[:days]&.to_i || 30

    # Use AdvancedCacheService for menu performance analytics
    @performance_data = AdvancedCacheService.cached_menu_performance(@menu.id, days: days)

    # Track performance view
    AnalyticsService.track_user_event(current_user, 'menu_performance_viewed', {
      restaurant_id: @menu.restaurant.id,
      menu_id: @menu.id,
      menu_name: @menu.name,
      period_days: days,
      total_orders: @performance_data[:performance][:total_orders],
      total_revenue: @performance_data[:performance][:total_revenue],
    },)

    respond_to do |format|
      format.html
      format.json { render json: @performance_data }
    end
  end

  private

  # Set restaurant from nested route parameter
  def set_restaurant
    if params[:restaurant_id].present?
      @restaurant = if current_user
                      current_user.restaurants.find(params[:restaurant_id])
                    else
                      Restaurant.find(params[:restaurant_id])
                    end
      Rails.logger.debug { "[MenusController] Found restaurant: #{@restaurant&.id} - #{@restaurant&.name}" }
    else
      Rails.logger.debug { "[MenusController] No restaurant_id in params: #{params.inspect}" }
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "[MenusController] Restaurant not found for id=#{params[:restaurant_id]}: #{e.message}"
    redirect_to restaurants_path, alert: 'Restaurant not found or access denied'
  rescue StandardError => e
    Rails.logger.error "[MenusController] Error in set_restaurant: #{e.message}"
    redirect_to restaurants_path, alert: 'An error occurred while loading the restaurant'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_menu
    menu_id = params[:menu_id] || params[:id]

    Rails.logger.debug { "[MenusController] set_menu called with menu_id=#{menu_id}, restaurant=#{@restaurant&.id}" }

    if menu_id.blank?
      Rails.logger.error "[MenusController] No menu ID provided in params: #{params.inspect}"
      redirect_to restaurant_menus_path(@restaurant), alert: 'Menu not specified'
      return
    end

    @menu = if @restaurant
              @restaurant.menus.find(menu_id)
            else
              Menu.find(menu_id)
            end

    Rails.logger.debug { "[MenusController] Found menu: #{@menu&.id} - #{@menu&.name}" }

    # Check ownership
    if current_user && (@menu.nil? || (@menu.restaurant.user != current_user))
      Rails.logger.warn "[MenusController] Menu access denied for user #{current_user.id}"
      redirect_to restaurants_path, alert: 'Menu not found or access denied'
      return
    end

    # Set up additional menu context
    if @menu
      @restaurantCurrency = ISO4217::Currency.from_code(@menu.restaurant.currency || 'USD')
      @canAddMenuItem = false
      if current_user
        @menuItemCount = @menu.menuitems.count
        if @menuItemCount < current_user.plan.itemspermenu || current_user.plan.itemspermenu == -1
          @canAddMenuItem = true
        end
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "[MenusController] Menu not found for id=#{menu_id}: #{e.message}"
    redirect_to (@restaurant ? restaurant_menus_path(@restaurant) : restaurants_path), alert: 'Menu not found'
  rescue StandardError => e
    Rails.logger.error "[MenusController] Error in set_menu: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to (@restaurant ? restaurant_menus_path(@restaurant) : restaurants_path),
                alert: 'An error occurred while loading the menu'
  end

  # GET /restaurants/:restaurant_id/menus/:id/performance
  def performance
    Rails.logger.debug do
      "[MenusController#performance] Method called - @menu: #{@menu&.id}, @restaurant: #{@restaurant&.id}"
    end
    Rails.logger.debug { "[MenusController#performance] Params: #{params.inspect}" }

    # Safety check - ensure @menu is set
    unless @menu
      Rails.logger.error "[MenusController#performance] @menu is nil, @restaurant: #{@restaurant&.id}"
      if @restaurant
        redirect_to restaurant_menus_path(@restaurant), alert: 'Menu not found'
      else
        redirect_to restaurants_path, alert: 'Restaurant and menu not found'
      end
      return
    end

    # Check authorization manually since we excluded this action from verify_authorized
    unless policy(@menu).performance?
      Rails.logger.warn "[MenusController#performance] Authorization failed for menu #{@menu.id}"
      redirect_to restaurant_menus_path(@restaurant), alert: 'Access denied'
      return
    end

    Rails.logger.debug { "[MenusController#performance] Processing performance for menu #{@menu.id}" }

    # Get time period from params or default to last 30 days
    days = params[:days]&.to_i || 30
    period_start = days.days.ago

    # Collect menu-specific performance data
    begin
      @performance_data = {
        menu: {
          id: @menu.id,
          name: @menu.name,
          restaurant_name: @menu.restaurant.name,
          created_at: @menu.created_at,
        },
        period: {
          days: days,
          start_date: period_start.strftime('%Y-%m-%d'),
          end_date: Date.current.strftime('%Y-%m-%d'),
        },
        cache_performance: collect_menu_cache_performance_data,
        database_performance: collect_menu_database_performance_data,
        response_times: collect_menu_response_time_data,
        user_activity: collect_menu_user_activity_data(days),
        system_metrics: collect_menu_system_metrics_data,
      }
    rescue StandardError => e
      Rails.logger.error "[MenusController#performance] Error collecting performance data: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Provide fallback data structure
      @performance_data = {
        menu: {
          id: @menu.id,
          name: @menu.name,
          restaurant_name: @menu.restaurant.name,
          created_at: @menu.created_at,
        },
        period: {
          days: days,
          start_date: period_start.strftime('%Y-%m-%d'),
          end_date: Date.current.strftime('%Y-%m-%d'),
        },
        cache_performance: { hit_rate: 0, total_hits: 0, total_misses: 0, total_operations: 0,
                             last_reset: Time.current.iso8601, },
        database_performance: { primary_queries: 0, replica_queries: 0, replica_lag: 0, connection_pool_usage: 0,
                                slow_queries: 0, },
        response_times: { average: 0, maximum: 0, request_count: 0, cache_efficiency: 0 },
        user_activity: { total_sessions: 0, unique_visitors: 0, page_views: 0, average_session_duration: 0,
                         bounce_rate: 0, },
        system_metrics: { memory_usage: 0, cpu_usage: 0, disk_usage: 0, active_connections: 0, background_jobs: 0 },
      }
    end

    Rails.logger.debug do
      "[MenusController#performance] Performance data collected successfully: #{@performance_data.keys}"
    end

    # Track menu performance view
    AnalyticsService.track_user_event(current_user, 'menu_performance_viewed', {
      menu_id: @menu.id,
      restaurant_id: @menu.restaurant.id,
      period_days: days,
      cache_hit_rate: @performance_data[:cache_performance][:hit_rate],
      avg_response_time: @performance_data[:response_times][:average],
    },)

    Rails.logger.debug '[MenusController#performance] Responding with performance data'
    respond_to do |format|
      format.html
      format.json { render json: @performance_data }
    end
  end

  # Menu-specific performance data collection methods
  def collect_menu_cache_performance_data
    # Get menu-specific cache performance from AdvancedCacheService
    menu_performance = AdvancedCacheService.cached_menu_performance(@menu.id, 30)

    {
      hit_rate: menu_performance[:cache_stats][:hit_rate] || 0,
      total_hits: menu_performance[:cache_stats][:hits] || 0,
      total_misses: menu_performance[:cache_stats][:misses] || 0,
      total_operations: menu_performance[:cache_stats][:operations] || 0,
      last_reset: Time.current.iso8601,
    }
  rescue StandardError => e
    Rails.logger.error("[MenusController] Menu cache performance data collection failed: #{e.message}")
    { hit_rate: 0, total_hits: 0, total_misses: 0, total_operations: 0, last_reset: Time.current.iso8601 }
  end

  def collect_menu_database_performance_data
    # Menu-specific database queries and performance
    {
      primary_queries: 0, # Menu-specific primary queries
      replica_queries: 0, # Menu-specific replica queries
      replica_lag: DatabaseRoutingService.replica_lag_ms || 0,
      connection_pool_usage: calculate_connection_pool_usage,
      slow_queries: 0, # Menu-specific slow queries
    }
  rescue StandardError => e
    Rails.logger.error("[MenusController] Menu database performance data collection failed: #{e.message}")
    { primary_queries: 0, replica_queries: 0, replica_lag: 0, connection_pool_usage: 0, slow_queries: 0 }
  end

  def collect_menu_response_time_data
    # Get menu-specific response time data
    performance_summary = begin
      MenusController.cache_performance_summary(days: 30)
    rescue StandardError
      {}
    end
    menu_metrics = performance_summary['menus#show'] || {}

    {
      average: menu_metrics[:avg_time] || 0,
      maximum: menu_metrics[:max_time] || 0,
      request_count: menu_metrics[:count] || 0,
      cache_efficiency: menu_metrics[:avg_cache_hits] || 0,
    }
  rescue StandardError => e
    Rails.logger.error("[MenusController] Menu response time data collection failed: #{e.message}")
    { average: 0, maximum: 0, request_count: 0, cache_efficiency: 0 }
  end

  def collect_menu_user_activity_data(_days)
    # Menu-specific user activity and engagement
    {
      total_sessions: 0, # Sessions viewing this menu
      unique_visitors: 0, # Unique visitors to this menu
      page_views: 0, # Page views for this menu
      average_session_duration: 0, # Time spent viewing menu
      bounce_rate: 0, # Bounce rate for menu pages
    }
  rescue StandardError => e
    Rails.logger.error("[MenusController] Menu user activity data collection failed: #{e.message}")
    { total_sessions: 0, unique_visitors: 0, page_views: 0, average_session_duration: 0, bounce_rate: 0 }
  end

  def collect_menu_system_metrics_data
    # System metrics relevant to menu performance
    {
      memory_usage: get_memory_usage_mb,
      cpu_usage: 0,
      disk_usage: 0,
      active_connections: get_active_connections_count,
      background_jobs: 0,
    }
  rescue StandardError => e
    Rails.logger.error("[MenusController] Menu system metrics data collection failed: #{e.message}")
    { memory_usage: 0, cpu_usage: 0, disk_usage: 0, active_connections: 0, background_jobs: 0 }
  end

  def calculate_connection_pool_usage
    pool = ActiveRecord::Base.connection_pool
    ((pool.connections.count.to_f / pool.size) * 100).round(2)
  rescue StandardError
    0
  end

  def get_memory_usage_mb
    `ps -o rss= -p #{Process.pid}`.to_i / 1024
  rescue StandardError
    0
  end

  def get_active_connections_count
    ActiveRecord::Base.connection_pool.connections.count
  rescue StandardError
    0
  end

  # Only allow a list of trusted parameters through.
  def menu_params
    params.require(:menu).permit(:name, :description, :image, :remove_image, :pdf_menu_scan, :status, :sequence,
                                 :restaurant_id, :displayImages, :displayImagesInPopup, :allowOrdering, :inventoryTracking, :imagecontext, :covercharge,)
  end
end
