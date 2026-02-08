def broadcast_state(ordr, tablesetting, ordrparticipant)
  menu = ordr.menu
  restaurant = menu.restaurant
  menuparticipant = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)

  Rails.logger.info("[BroadcastState][Ordrs] Building payload for order=#{ordr.id} table=#{tablesetting&.id} session=#{session.id}")

  payload = SmartmenuState.for_context(
    menu: menu,
    restaurant: restaurant,
    tablesetting: tablesetting,
    open_order: ordr,
    ordrparticipant: ordrparticipant,
    menuparticipant: menuparticipant,
    session_id: session.id.to_s,
  )

  begin
    keys = payload.is_a?(Hash) ? payload.keys : payload.class
    Rails.logger.info("[BroadcastState][Ordrs] Payload summary keys=#{keys} orderId=#{payload.dig(:order, :id)} totals?=#{!payload[:totals].nil?}")
  rescue StandardError => e
    Rails.logger.info("[BroadcastState][Ordrs] Payload summary failed: #{e.class}: #{e.message}")
  end

  # Broadcast to both order_id channel and slug channel for compatibility
  channel_order = "ordr_#{ordr.id}_channel"
  Rails.logger.info("[BroadcastState][Ordrs] Broadcasting to #{channel_order}")
  ActionCable.server.broadcast(channel_order, { state: payload })

  if menuparticipant&.smartmenu&.slug
    channel_slug = "ordr_#{menuparticipant.smartmenu.slug}_channel"
    Rails.logger.info("[BroadcastState][Ordrs] Broadcasting to #{channel_slug}")
    ActionCable.server.broadcast(channel_slug, { state: payload })
  end
rescue StandardError => e
  Rails.logger.warn("[SmartmenuState] Broadcast failed: #{e.class}: #{e.message}")
  begin
    Rails.logger.warn("[SmartmenuState] Backtrace:\n#{e.backtrace.join("\n")}")
  rescue StandardError
    # ignore
  end
end

class OrdrsController < ApplicationController
  include CachePerformanceMonitoring

  before_action :authenticate_user!, except: %i[show create update] # Allow customers to create/update orders
  skip_before_action :verify_authenticity_token, only: %i[ack_alcohol]
  before_action :set_restaurant
  before_action :set_ordr, only: %i[show edit update destroy analytics ack_alcohol events]
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
          cached_result = AdvancedCacheServiceV2.cached_restaurant_orders_with_models(@restaurant.id,
                                                                                      include_calculations: true,)

          # Apply policy scoping to the model instances
          @ordrs = policy_scope(cached_result[:orders])
          @orders_data = cached_result # Contains both models and cached calculations
          @cached_calculations = cached_result[:cached_calculations] # Hash data for complex calculations

          # Track restaurant orders view
          AnalyticsService.track_user_event(current_user, 'restaurant_orders_viewed', {
            restaurant_id: @restaurant.id,
            restaurant_name: @restaurant.name,
            orders_count: @ordrs.count,
            viewing_context: 'restaurant_management',
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
            total_orders: @ordrs.count,
          })
        end
      end

      format.json do
        # For JSON requests, use actual ActiveRecord objects with minimal includes
        # Ensure user is authenticated for sensitive order data
        unless current_user
          head :unauthorized
          return
        end

        if @restaurant
          # For JSON requests (table data), only load minimal data needed for display
          @ordrs = policy_scope(@restaurant.ordrs.includes(:menu, :tablesetting).order(created_at: :desc))
        else
          # Get orders from all user's restaurants with minimal includes
          restaurant_ids = current_user.restaurants.pluck(:id)
          @ordrs = policy_scope(Ordr.where(restaurant_id: restaurant_ids)
                                   .includes(:menu, :tablesetting)
                                   .order(created_at: :desc))
        end

        # Use minimal JSON view for better performance
        render 'index_minimal'
      end
    end
  end

  def order_event_source
    return 'voice' if request.headers['X-Order-Source'].to_s == 'voice'

    current_user && @current_employee.present? ? 'staff' : 'guest'
  end

  # GET /ordrs/1 or /ordrs/1.json
  def show
    # Always authorize - policy handles public vs private access
    authorize @ordr

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
    return unless current_user

    AnalyticsService.track_user_event(current_user, 'order_viewed', {
      order_id: @ordr.id,
      restaurant_id: @ordr.restaurant_id,
      order_status: @ordr.status,
      order_total: @ordr.gross,
      viewing_context: current_user.admin? ? 'staff_view' : 'customer_view',
    })
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
      order_total: @ordr.gross,
    })

    respond_to do |format|
      format.html
      format.json { render json: @analytics_data }
    end
  end

  # GET /restaurants/:restaurant_id/ordrs/:id/events
  def events
    authorize @ordr, :show?

    events = OrderEvent.where(ordr_id: @ordr.id).order(:sequence)

    render json: {
      order_id: @ordr.id,
      cursor: @ordr.last_projected_order_event_sequence.to_i,
      count: events.count,
      events: events.map do |e|
        {
          id: e.id,
          sequence: e.sequence,
          event_type: e.event_type,
          entity_type: e.entity_type,
          entity_id: e.entity_id,
          source: e.source,
          idempotency_key: e.idempotency_key,
          occurred_at: e.occurred_at,
          created_at: e.created_at,
          payload: e.payload,
        }
      end,
    }
  end

  # GET /restaurants/:restaurant_id/order_events
  def restaurant_events
    authorize Ordr.new(restaurant: @restaurant), :index?

    scope = OrderEvent.joins(:ordr).where(ordrs: { restaurant_id: @restaurant.id })

    if params[:ordr_id].present?
      scope = scope.where(ordr_id: params[:ordr_id])
    end

    if params[:event_type].present?
      scope = scope.where(event_type: params[:event_type])
    end

    if params[:source].present?
      scope = scope.where(source: params[:source])
    end

    if params[:since].present?
      since_time = begin
        Time.iso8601(params[:since].to_s)
      rescue ArgumentError
        nil
      end
      scope = scope.where(order_events: { occurred_at: since_time.. }) if since_time
    end

    if params[:before_id].present?
      scope = scope.where(order_events: { id: ...params[:before_id].to_i })
    end

    limit = params[:limit].to_i
    limit = 200 if limit <= 0
    limit = 1000 if limit > 1000

    events = scope.includes(:ordr).order(id: :desc).limit(limit)

    render json: {
      restaurant_id: @restaurant.id,
      count: events.length,
      limit: limit,
      next_before_id: events.last&.id,
      events: events.map do |e|
        {
          id: e.id,
          ordr_id: e.ordr_id,
          ordr_cursor: e.ordr&.last_projected_order_event_sequence.to_i,
          sequence: e.sequence,
          event_type: e.event_type,
          entity_type: e.entity_type,
          entity_id: e.entity_id,
          source: e.source,
          idempotency_key: e.idempotency_key,
          occurred_at: e.occurred_at,
          created_at: e.created_at,
          payload: e.payload,
        }
      end,
    }
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
      total_revenue: @summary_data[:summary][:total_revenue],
    })

    respond_to do |format|
      format.html
      format.json { render json: @summary_data }
    end
  end

  # GET /ordrs/new
  def new
    @ordr = Ordr.new
    # Always authorize - policy handles public vs private access
    authorize @ordr
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
    # Always authorize - policy handles public vs private access
    authorize @ordr

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
            order_status: @ordr.status,
          })
        else
          anonymous_id = session[:session_id] ||= SecureRandom.uuid
          AnalyticsService.track_anonymous_event(anonymous_id, 'order_started_anonymous', {
            order_id: @ordr.id,
            restaurant_id: @ordr.restaurant_id,
            menu_id: @ordr.menu_id,
            table_id: @ordr.tablesetting_id,
          })
        end

        if ordr_params[:status].to_i.zero?
          update_tablesetting_status(@tablesetting, 0)
          broadcast_partials(@ordr, @tablesetting, @ordrparticipant, false)
          broadcast_state(@ordr, @tablesetting, @ordrparticipant)
        end

        respond_to do |format|
          format.html do
            redirect_to restaurant_ordr_url(@restaurant || @ordr.restaurant, @ordr),
                        notice: t('common.flash.created', resource: t('activerecord.models.ordr'))
          end
          format.json do
            render :show, status: :created, location: restaurant_ordr_url(@restaurant || @ordr.restaurant, @ordr)
          end
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_content }
          format.json { render json: @ordr.errors, status: :unprocessable_content }
        end
        return # Return early to prevent double render
      end
    end
  end

  # PATCH/PUT /ordrs/1 or /ordrs/1.json
  def update
    # Always authorize - policy handles public vs private access
    authorize @ordr

    begin
      ActiveRecord::Base.transaction do
        desired_status = ordr_params[:status]
        before_status = @ordr.status.to_s
        attrs = ordr_params.to_h.symbolize_keys
        attrs.delete(:status)
        @ordr.assign_attributes(attrs)

        # Ensure any newly added items are promoted from 'opened' to 'ordered' when submitting,
        # even if the overall order status was already 'ordered'.
        if desired_status.to_i == 20
          # 0 => opened, 20 => ordered (consistent with client usage)
          begin
            # Items are promoted + assigned to station tickets during submission
            OrdrStationTicketService.submit_unsubmitted_items!(@ordr)
          rescue StandardError => e
            Rails.logger.warn("[OrdrsController#update] Failed to submit unsubmitted items for order=#{@ordr.id}: #{e.class}: #{e.message}")
            begin
              opened_status = Ordritem.statuses['opened']
              ordered_status = Ordritem.statuses['ordered']
              @ordr.ordritems.where(status: opened_status).update_all(status: ordered_status)
            rescue StandardError
              nil
            end
          end
        end

        # Now that items may have changed status, recalculate totals
        calculate_order_totals(@ordr)

        if @ordr.save
          begin
            if desired_status.present?
              to = desired_status.to_s
              if to.match?(/^\d+$/)
                to = Ordr.statuses.key(to.to_i).to_s
              end
              if to.present? && to != before_status
                source = order_event_source
                OrderEvent.emit!(
                  ordr: @ordr,
                  event_type: 'status_changed',
                  entity_type: 'order',
                  entity_id: @ordr.id,
                  source: source,
                  payload: {
                    from: before_status,
                    to: to,
                  },
                )
                OrderEventProjector.project!(@ordr.id)
                @ordr.reload
              end
            end
          rescue StandardError => e
            Rails.logger.warn("[OrderEvent] status event-first update failed: #{e.class}: #{e.message}")
          end
          # Move cache invalidation to background job to improve response time
          CacheInvalidationJob.perform_later(
            order_id: @ordr.id,
            restaurant_id: @ordr.restaurant_id,
            user_id: @ordr.restaurant.user_id,
          )

          @tablesetting = @ordr.tablesetting
          @ordrparticipant = find_or_create_ordr_participant(@ordr)
          @ordr.status
          full_refresh = false
          respond_to do |format|
            format.json do
              render :show, status: :ok, location: restaurant_ordr_url(@restaurant || @ordr.restaurant, @ordr)
            end
            broadcast_partials(@ordr, @tablesetting, @ordrparticipant, full_refresh)
            broadcast_state(@ordr, @tablesetting, @ordrparticipant)
          end
        else
          respond_to do |format|
            format.html { render :edit, status: :unprocessable_content }
            format.json { render json: @ordr.errors, status: :unprocessable_content }
          end
        end
      end
    rescue ArgumentError => e
      # Handle invalid enum values
      @ordr.errors.add(:status, e.message)
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @ordr.errors, status: :unprocessable_content }
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

      # Move cache invalidation to background job
      CacheInvalidationJob.perform_later(
        order_id: @ordr.id,
        restaurant_id: restaurant_id,
        user_id: user_id,
      )

      respond_to do |format|
        format.html do
          redirect_to restaurant_ordrs_url(@restaurant),
                      notice: t('common.flash.deleted', resource: t('activerecord.models.ordr'))
        end
        format.json { head :no_content }
      end
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    respond_to do |format|
      format.html do
        redirect_to restaurant_ordrs_url(@restaurant), alert: t('common.flash.action_failed', error: e.message)
      end
      format.json { render json: { error: e.message }, status: :unprocessable_content }
    end
  end

  # POST /restaurants/:restaurant_id/ordrs/:id/ack_alcohol
  # Acknowledge that age check was performed for alcohol items on this order
  def ack_alcohol
    authorize @ordr, :update?

    employee_id = @current_employee&.id
    acknowledged_count = 0

    AlcoholOrderEvent.where(ordr_id: @ordr.id, age_check_acknowledged: false).find_each do |evt|
      evt.update(
        age_check_acknowledged: true,
        acknowledged_at: Time.zone.now,
        employee_id: employee_id || evt.employee_id,
      )
      acknowledged_count += 1
    end

    respond_to do |format|
      format.html do
        target = params[:return_to].presence || restaurant_ordr_path(@restaurant || @ordr.restaurant, @ordr)
        redirect_to target, notice: I18n.t('smartmenus.alcohol.acknowledged', default: 'Age check acknowledged')
      end
      format.json { render json: { ok: true, acknowledged: acknowledged_count } }
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

      # Transfer preferredlocale from Menuparticipant if present and participant has none
      begin
        mp = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)
        if mp&.preferredlocale.present? && participant.preferredlocale.blank?
          participant.preferredlocale = mp.preferredlocale.to_s.downcase
        end
      rescue StandardError
        # No-op
      end

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
    # In some production edge cases the order may not have an associated menu loaded
    # or the menu may not define a covercharge. Default to 0 to avoid exceptions.
    cover_per = ordr.menu&.covercharge.to_f
    ordr.covercharge = ordr.ordercapacity.to_i * cover_per

    # Use Rails.cache to avoid repeated tax queries for the same restaurant
    cache_key = "restaurant_taxes:#{ordr.restaurant_id}:#{Date.current}"
    taxes = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      Tax.where(restaurant_id: ordr.restaurant_id)
        .order(:sequence)
        .pluck(:taxpercentage, :taxtype)
    end

    total_tax = 0
    total_service = 0
    taxable_amount = ordr.nett.to_f + ordr.covercharge.to_f

    # Process cached tax data instead of ActiveRecord objects
    taxes.each do |tax_percentage, tax_type|
      amount = (tax_percentage * taxable_amount) / 100
      tax_type == 'service' ? total_service += amount : total_tax += amount
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
    # Comprehensive eager loading to prevent N+1 queries
    ordr = Ordr.includes(
      :ordritems, :ordrparticipants, :ordractions, :employee,
      menu: [
        :restaurant, :menusections, :menuavailabilities, :menulocales,
        { menusections: [
          :menuitems, :menusectionlocales,
          { menuitems: %i[
            menuitemlocales allergyns ingredients sizes
            menuitem_allergyn_mappings menuitem_ingredient_mappings
          ] },
        ] },
      ],
      tablesetting: [:restaurant],
      restaurant: %i[restaurantlocales taxes allergyns],
    ).find(ordr.id)

    menu = ordr.menu
    restaurant = ordr.restaurant

    # Use single query with includes instead of separate find_by
    menuparticipant = Menuparticipant.includes(:smartmenu)
      .where(sessionid: session.id.to_s)
      .first

    smartmenu = menuparticipant&.smartmenu

    # Allergyns already loaded via restaurant association
    allergyns = restaurant.allergyns

    table_smartmenus = begin
      if restaurant&.id && menu&.id
        Smartmenu.includes(:tablesetting)
          .where(restaurant_id: restaurant.id, menu_id: menu.id)
          .order(:id)
          .to_a
      else
        []
      end
    rescue StandardError
      []
    end

    active_locales = []
    default_locale = nil
    begin
      restaurantlocales = Array(restaurant&.restaurantlocales)
      active_locales = restaurantlocales.select { |rl| rl.status.to_s == 'active' }
      default_locale = active_locales.find { |rl| rl.dfault == true }
    rescue StandardError
      active_locales = []
      default_locale = nil
    end

    restaurant_currency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
    ordrparticipant.preferredlocale = menuparticipant.preferredlocale if menuparticipant&.preferredlocale

    needs_age_check = false
    begin
      needs_age_check = !(ordr && AlcoholOrderEvent.exists?(ordr_id: ordr.id, age_check_acknowledged: false)).nil?
    rescue StandardError
      needs_age_check = false
    end

    # Determine locale to render with
    render_locale = (
      ordrparticipant&.preferredlocale.presence ||
      menuparticipant&.preferredlocale.presence ||
      restaurant&.defaultLocale&.locale.presence ||
      I18n.default_locale
    ).to_s.downcase

    partials = {
      context: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showContext',
          locals: {
            order: ordr,
            menu: menu,
            restaurant: restaurant,
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
            currency: restaurant_currency,
            locale: render_locale,
          ),
          expires_in: 30.minutes,
        ) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showModals',
            locals: {
              order: ordr,
              menu: menu,
              restaurant: restaurant,
              allergyns: allergyns,
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
            allergyns_updated_at: allergyns.maximum(:updated_at),
            locale: render_locale,
          ),
          expires_in: 30.minutes,
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
              tablesetting: tablesetting,
            },
          )
        end,
      ),
      menuContentCustomer: compress_string(
        Rails.cache.fetch(
          CacheKeyService.menu_content_key(
            ordr: ordr,
            menu: menu,
            participant: ordrparticipant || menuparticipant,
            currency: restaurant_currency,
            allergyns_updated_at: allergyns.maximum(:updated_at),
            locale: render_locale,
          ),
          expires_in: 30.minutes,
        ) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentCustomer',
            locals: {
              order: ordr,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: ordrparticipant,
              menuparticipant: menuparticipant,
              tablesetting: tablesetting,
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
            smartmenu: smartmenu,
            needs_age_check: needs_age_check,
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
            table_smartmenus: table_smartmenus,
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
            table_smartmenus: table_smartmenus,
            active_locales: active_locales,
            default_locale: default_locale,
          },
        ),
      ),
      fullPageRefresh: { refresh: full_refresh },
    }
    if menuparticipant&.smartmenu&.slug
      ActionCable.server.broadcast("ordr_#{menuparticipant.smartmenu.slug}_channel", partials)
    end
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
      @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency || 'USD')
    else
      @restaurantCurrency = ISO4217::Currency.from_code('USD')
    end
  end

  # Only allow a list of trusted parameters through.
  def ordr_params
    params.require(:ordr).permit(:orderedAt, :deliveredAt, :paidAt, :nett, :tip, :service, :tax, :gross, :status,
                                 :ordercapacity, :covercharge, :employee_id, :tablesetting_id, :menu_id, :restaurant_id,)
  end
end
