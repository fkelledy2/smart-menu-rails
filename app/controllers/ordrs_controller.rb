class OrdrsController < ApplicationController
  before_action :authenticate_user!, except: %i[show create update] # Allow customers to create/update orders
  before_action :set_restaurant
  before_action :set_ordr, only: %i[show edit update destroy analytics]
  before_action :set_currency

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /ordrs or /ordrs.json
  def index
    respond_to do |format|
      format.html do
        if @restaurant
          # Use enhanced cache service that returns model instances
          cached_result = AdvancedCacheServiceV2.cached_restaurant_orders_with_models(@restaurant.id, include_calculations: true)
          
          # Apply policy scoping to the model instances
          @ordrs = policy_scope(cached_result[:orders])
          @orders_data = cached_result # Contains both models and cached calculations
          @cached_calculations = cached_result[:cached_calculations] # Hash data for complex calculations
          
          # Track restaurant orders view
          AnalyticsService.track_user_event(current_user, 'restaurant_orders_viewed', {
            restaurant_id: @restaurant.id,
            restaurant_name: @restaurant.name,
            orders_count: @ordrs.count,
            viewing_context: 'restaurant_management'
          })
        else
          # Use enhanced cache service that returns model instances
          cached_result = AdvancedCacheServiceV2.cached_user_all_orders_with_models(current_user.id)
          
          # Apply policy scoping to the model instances
          @ordrs = policy_scope(cached_result[:orders])
          @all_orders_data = cached_result # Contains both models and cached data
          
          # Track all orders view
          AnalyticsService.track_user_event(current_user, 'all_orders_viewed', {
            user_id: current_user.id,
            restaurants_count: @all_orders_data[:metadata][:restaurants_count],
            total_orders: @ordrs.count
          })
        end
      end
      
      format.json do
        # For JSON requests, use actual ActiveRecord objects
        # Ensure user is authenticated for sensitive order data
        if !current_user
          head :unauthorized
          return
        end
        
        if @restaurant
          @ordrs = policy_scope(@restaurant.ordrs.includes(:ordritems, :tablesetting, :menu, :employee, :ordrparticipants))
        else
          # Get orders from all user's restaurants
          restaurant_ids = current_user.restaurants.pluck(:id)
          @ordrs = policy_scope(Ordr.where(restaurant_id: restaurant_ids).includes(:ordritems, :tablesetting, :menu, :employee, :ordrparticipants))
        end
      end
    end
  end

  # GET /ordrs/1 or /ordrs/1.json
  def show
    # Allow both staff and customers to view orders
    authorize @ordr if current_user
    
    respond_to do |format|
      format.html do
        # Use AdvancedCacheService for comprehensive order data with calculations
        @order_data = AdvancedCacheService.cached_order_with_details(@ordr.id)
        
        # Apply cached calculations to the order object for backward compatibility
        @ordr.nett = @order_data[:calculations][:nett]
        @ordr.tax = @order_data[:calculations][:tax]
        @ordr.service = @order_data[:calculations][:service]
        @ordr.covercharge = @order_data[:calculations][:covercharge]
        @ordr.gross = @order_data[:calculations][:gross]
      end
      
      format.json do
        # For JSON requests, @ordr is already set by before_action and is an ActiveRecord object
        # No additional setup needed - the JSON view will work with the ActiveRecord object
      end
    end
    
    # Track order view
    if current_user
      AnalyticsService.track_user_event(current_user, 'order_viewed', {
        order_id: @ordr.id,
        restaurant_id: @ordr.restaurant_id,
        order_status: @ordr.status,
        order_total: @ordr.gross,
        viewing_context: current_user.admin? ? 'staff_view' : 'customer_view'
      })
    end
  end

  # GET /ordrs/1/analytics
  def analytics
    authorize @ordr, :show?
    
    # Get analytics period from params or default to 7 days for order context
    days = params[:days]&.to_i || 7
    
    # Use AdvancedCacheService for order analytics and similar orders
    @analytics_data = AdvancedCacheService.cached_order_analytics(@ordr.id, days: days)
    
    # Track analytics view
    AnalyticsService.track_user_event(current_user, 'order_analytics_viewed', {
      order_id: @ordr.id,
      restaurant_id: @ordr.restaurant_id,
      period_days: days,
      order_total: @ordr.gross
    })
    
    respond_to do |format|
      format.html
      format.json { render json: @analytics_data }
    end
  end

  # GET /restaurants/:restaurant_id/ordrs/summary
  def summary
    authorize Ordr.new(restaurant: @restaurant), :index?
    
    # Get summary period from params or default to 30 days
    days = params[:days]&.to_i || 30
    
    # Use AdvancedCacheService for restaurant order summary
    @summary_data = AdvancedCacheService.cached_restaurant_order_summary(@restaurant.id, days: days)
    
    # Track summary view
    AnalyticsService.track_user_event(current_user, 'restaurant_order_summary_viewed', {
      restaurant_id: @restaurant.id,
      period_days: days,
      total_orders: @summary_data[:summary][:total_orders],
      total_revenue: @summary_data[:summary][:total_revenue]
    })
    
    respond_to do |format|
      format.html
      format.json { render json: @summary_data }
    end
  end

  # GET /ordrs/new
  def new
    @ordr = Ordr.new
    authorize @ordr if current_user
    @ordr.nett = 0
    @ordr.tip = 0
    @ordr.service = 0
    @ordr.tax = 0
    @ordr.gross = 0
    @ordr.ordrparticipants ||= []
    @ordr.ordritems ||= []
  end

  # GET /ordrs/1/edit
  def edit
    authorize @ordr
  end

  # POST /ordrs or /ordrs.json
  def create
    # Ensure restaurant_id is set from nested route
    restaurant_id = @restaurant&.id || ordr_params[:restaurant_id]
    @ordr = Ordr.new(ordr_params.merge(
                       restaurant_id: restaurant_id,
                       nett: 0, tip: 0, service: 0, tax: 0, gross: 0,
    ))
    authorize @ordr if current_user

    ActiveRecord::Base.transaction do
      if @ordr.save
        @tablesetting = @ordr.tablesetting
        @ordrparticipant = find_or_create_ordr_participant(@ordr)

        # Track order creation
        if current_user
          AnalyticsService.track_user_event(current_user, AnalyticsService::ORDER_STARTED, {
            order_id: @ordr.id,
            restaurant_id: @ordr.restaurant_id,
            menu_id: @ordr.menu_id,
            table_id: @ordr.tablesetting_id,
            order_status: @ordr.status
          })
        else
          anonymous_id = session[:session_id] ||= SecureRandom.uuid
          AnalyticsService.track_anonymous_event(anonymous_id, 'order_started_anonymous', {
            order_id: @ordr.id,
            restaurant_id: @ordr.restaurant_id,
            menu_id: @ordr.menu_id,
            table_id: @ordr.tablesetting_id
          })
        end

        if ordr_params[:status].to_i.zero?
          update_tablesetting_status(@tablesetting, 0)
          broadcast_partials(@ordr, @tablesetting, @ordrparticipant, false)
        end

        respond_to do |format|
          format.html {
 redirect_to restaurant_ordr_url(@restaurant || @ordr.restaurant, @ordr), notice: t('common.flash.created', resource: t('activerecord.models.ordr')) }
          format.json { render :show, status: :created, location: restaurant_ordr_url(@restaurant || @ordr.restaurant, @ordr) }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @ordr.errors, status: :unprocessable_entity }
        end
        return # Return early to prevent double render
      end
    end
  end

  # PATCH/PUT /ordrs/1 or /ordrs/1.json
  def update
    authorize @ordr if current_user

    ActiveRecord::Base.transaction do
      @ordr.assign_attributes(ordr_params)
      calculate_order_totals(@ordr)

      if @ordr.status_changed?
        handle_status_change(@ordr, ordr_params[:status])
      end
      @ordr.ordritems.added.update_all(status: 20) # Batch update

      if @ordr.save
        # Invalidate AdvancedCacheService caches for this order
        AdvancedCacheService.invalidate_order_caches(@ordr.id)
        AdvancedCacheService.invalidate_restaurant_caches(@ordr.restaurant_id)
        AdvancedCacheService.invalidate_user_caches(@ordr.restaurant.user_id) if @ordr.restaurant.user_id
        
        @tablesetting = @ordr.tablesetting
        @ordrparticipant = find_or_create_ordr_participant(@ordr)
        @ordr.status == 'closed'
        full_refresh = false
        respond_to do |format|
          format.json { render :show, status: :ok, location: restaurant_ordr_url(@restaurant || @ordr.restaurant, @ordr) }
          broadcast_partials(@ordr, @tablesetting, @ordrparticipant, full_refresh)
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @ordr.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /ordrs/1 or /ordrs/1.json
  def destroy
    authorize @ordr

    ActiveRecord::Base.transaction do
      # Store data for cache invalidation before destroying
      restaurant_id = @ordr.restaurant_id
      user_id = @ordr.restaurant.user_id
      
      @ordr.destroy!
      
      # Invalidate AdvancedCacheService caches for this order
      AdvancedCacheService.invalidate_order_caches(@ordr.id)
      AdvancedCacheService.invalidate_restaurant_caches(restaurant_id)
      AdvancedCacheService.invalidate_user_caches(user_id) if user_id
      
      respond_to do |format|
        format.html {
 redirect_to restaurant_ordrs_url(@restaurant), notice: t('common.flash.deleted', resource: t('activerecord.models.ordr')) }
        format.json { head :no_content }
      end
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    respond_to do |format|
      format.html { redirect_to restaurant_ordrs_url(@restaurant), alert: t('common.flash.action_failed', error: e.message) }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  private

  # Set restaurant from nested route parameter
  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id]) if params[:restaurant_id]
  end

  def find_or_create_ordr_participant(ordr)
    if current_user
      ordr.ordrparticipants.find_or_create_by!(
        employee: @current_employee,
        role: 1,
        sessionid: session.id.to_s,
      ) do |participant|
        participant.ordr = ordr
      end
    else
      # First ensure the participant is created and saved
      participant = ordr.ordrparticipants.find_or_initialize_by(
        role: 0,
        sessionid: session.id.to_s,
      )

      # Set order if this is a new record
      participant.ordr = ordr if participant.new_record?

      # Save the participant first to get an ID
      if participant.save!
        # Now create the ordraction with the saved participant
        ordr.ordractions.create!(
          ordrparticipant_id: participant.id,
          ordr_id: ordr.id,
          action: ordr.status == 'closed' ? 5 : 1,
        )
      end

      participant
    end
  end

  def calculate_order_totals(ordr)
    ordr.nett = ordr.runningTotal
    ordr.covercharge = ordr.ordercapacity * ordr.menu.covercharge

    taxes = Tax.where(restaurant_id: ordr.restaurant_id).order(:sequence)
    total_tax = 0
    total_service = 0
    taxable_amount = ordr.nett + ordr.covercharge

    taxes.each do |tax|
      amount = (tax.taxpercentage * taxable_amount) / 100
      tax.taxtype == 'service' ? total_service += amount : total_tax += amount
    end

    ordr.tip ||= 0
    ordr.tax = total_tax
    ordr.service = total_service
    ordr.gross = ordr.nett + ordr.covercharge + ordr.tip + ordr.service + ordr.tax
  end

  def update_tablesetting_status(tablesetting, status)
    tablesetting.update!(status: status)
  end

  def handle_status_change(ordr, new_status)
    case new_status.to_i
    when 0  # opened
      ordr.orderedAt = Time.current
    when 20 # ordered
      ordr.orderedAt = Time.current
    when 30 # bill requested
      ordr.billRequestedAt = Time.current
    when 40 # paid
      ordr.paidAt = Time.current
    end
  end

  def broadcast_partials(ordr, tablesetting, ordrparticipant, full_refresh)
    # Eager load all associations needed by partials to prevent N+1 queries
    ordr = Ordr.includes(menu: %i[restaurant menusections menuavailabilities]).find(ordr.id)
    menu = ordr.menu
    restaurant = menu.restaurant
    menuparticipant = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)
    allergyns = Allergyn.where(restaurant_id: restaurant.id)
    restaurant_currency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
    ordrparticipant.preferredlocale = menuparticipant.preferredlocale if menuparticipant

    partials = {
      context: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showContext',
          locals: {
            order: ordr,
            menu: menu,
            ordrparticipant: ordrparticipant,
            tablesetting: tablesetting,
            menuparticipant: menuparticipant,
            current_employee: @current_employee,
          },
        ),
      ),
      modals: compress_string(
        Rails.cache.fetch(
          CacheKeyService.modal_content_key(
            ordr: ordr,
            menu: menu,
            tablesetting: tablesetting,
            participant: menuparticipant,
            currency: restaurant_currency
          ),
          expires_in: 30.minutes
        ) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showModals',
            locals: {
              order: ordr,
              menu: menu,
              ordrparticipant: ordrparticipant,
              tablesetting: tablesetting,
              menuparticipant: menuparticipant,
              restaurantCurrency: restaurant_currency,
              current_employee: @current_employee,
            },
          )
        end,
      ),
      menuContentStaff: compress_string(
        Rails.cache.fetch(
          CacheKeyService.menu_content_key(
            ordr: ordr,
            menu: menu,
            participant: ordrparticipant,
            currency: restaurant_currency,
            allergyns_updated_at: allergyns.maximum(:updated_at)
          ),
          expires_in: 30.minutes
        ) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentStaff',
            locals: {
              order: ordr,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: ordrparticipant,
              menuparticipant: menuparticipant,
            },
          )
        end,
      ),
      menuContentCustomer: compress_string(
        Rails.cache.fetch([
          :menu_content_customer,
          ordr.cache_key_with_version,
          menu.cache_key_with_version,
          allergyns.maximum(:updated_at),
          restaurant_currency.code,
          ordrparticipant.try(:id),
          menuparticipant.try(:id),
        ]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentCustomer',
            locals: {
              order: ordr,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: ordrparticipant,
              menuparticipant: menuparticipant,
            },
          )
        end,
      ),
      orderCustomer: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/orderCustomer',
          locals: {
            order: ordr,
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: ordrparticipant,
          },
        ),
      ),
      orderStaff: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/orderStaff',
          locals: {
            order: ordr,
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: ordrparticipant,
          },
        ),
      ),
      tableLocaleSelectorStaff: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showTableLocaleSelectorStaff',
          locals: {
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: ordrparticipant,
            menuparticipant: menuparticipant,
          },
        ),
      ),
      tableLocaleSelectorCustomer: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showTableLocaleSelectorCustomer',
          locals: {
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: ordrparticipant,
            menuparticipant: menuparticipant,
          },
        ),
      ),
      fullPageRefresh: { refresh: full_refresh },
    }
    ActionCable.server.broadcast("ordr_#{menuparticipant.smartmenu.slug}_channel", partials)
  end


  def compress_string(str)
    require 'zlib'
    require 'base64'
    Base64.strict_encode64(Zlib::Deflate.deflate(str))
  end

    # Use callbacks to share common setup or constraints between actions.
  def set_ordr
    @ordr = Ordr.find(params[:id])
  end

  def set_currency
    if params[:restaurant_id]
        @restaurant = Restaurant.find(params[:restaurant_id])
        @restaurantCurrency = if @restaurant.currency
          ISO4217::Currency.from_code(@restaurant.currency)
        else
          ISO4217::Currency.from_code('USD')
                              end
    else
      @restaurantCurrency = ISO4217::Currency.from_code('USD')
    end
  end

    # Only allow a list of trusted parameters through.
  def ordr_params
    params.require(:ordr).permit(:orderedAt, :deliveredAt, :paidAt, :nett, :tip, :service, :tax, :gross, :status, 
:ordercapacity, :covercharge, :employee_id, :tablesetting_id, :menu_id, :restaurant_id)
  end
end
