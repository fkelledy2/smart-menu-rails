def broadcast_state(ordr, tablesetting, ordrparticipant)
  menu = ordr.menu
  restaurant = menu.restaurant
  menuparticipant = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)

  Rails.logger.info("[BroadcastState][Ordritems] Building payload for order=#{ordr.id} table=#{tablesetting&.id} session=#{session.id}")

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
    Rails.logger.info("[BroadcastState][Ordritems] Payload summary keys=#{keys} orderId=#{payload.dig(:order, :id)} totals?=#{!payload[:totals].nil?}")
  rescue StandardError => e
    Rails.logger.info("[BroadcastState][Ordritems] Payload summary failed: #{e.class}: #{e.message}")
  end

  channel_order = "ordr_#{ordr.id}_channel"
  Rails.logger.info("[BroadcastState][Ordritems] Broadcasting to #{channel_order}")
  ActionCable.server.broadcast(channel_order, { state: payload })

  if menuparticipant&.smartmenu&.slug
    channel_slug = "ordr_#{menuparticipant.smartmenu.slug}_channel"
    Rails.logger.info("[BroadcastState][Ordritems] Broadcasting to #{channel_slug}")
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

class OrdritemsController < ApplicationController
  include CsrfSafeGuestActions

  before_action :authenticate_user!, except: %i[create update destroy] # Allow customers to manage order items
  skip_before_action :verify_authenticity_token, only: %i[create update destroy]
  before_action :set_restaurant
  before_action :set_ordritem, only: %i[show edit update destroy]
  before_action :set_currency

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  private def csrf_skipped_action?
    %w[create update destroy].include?(action_name)
  end

  # GET /ordritems or /ordritems.json
  def index
    @ordritems = policy_scope(Ordritem)
  end

  # GET /ordritems/1 or /ordritems/1.json
  def show
    # Always authorize - policy handles public vs private access
    authorize @ordritem
  end

  # GET /ordritems/new
  def new
    @ordritem = Ordritem.new
    # Always authorize - policy handles public vs private access
    authorize @ordritem
  end

  # GET /ordritems/1/edit
  def edit
    # Always authorize - policy handles public vs private access
    authorize @ordritem
  end

  # POST /ordritems or /ordritems.json
  def create
    # Guard: require a valid existing order; never create wrapper orders implicitly
    begin
      target_order_id = ordritem_params[:ordr_id]
      @ordr = Ordr.find(target_order_id)
    rescue ActiveRecord::RecordNotFound, NoMethodError
      respond_to do |format|
        format.html do
          redirect_back_or_to(root_path, alert: I18n.t('ordritems.errors.order_missing', default: 'Cannot add item: order does not exist'))
        end
        format.json { render json: { error: 'order_not_found' }, status: :unprocessable_content }
      end
      return
    end

    # Always authorize - policy handles public vs private access
    authorize Ordritem.new(ordritem_params)

    respond_to do |format|
      ActiveRecord::Base.transaction do
        begin
          line_key = SecureRandom.uuid
          source = if request.headers['X-Order-Source'].to_s == 'voice'
                     'voice'
                   else
                     (current_user && @current_employee.present? ? 'staff' : 'guest')
                   end
          OrderEvent.emit!(
            ordr: @ordr,
            event_type: 'item_added',
            entity_type: 'item',
            source: source,
            payload: {
              line_key: line_key,
              menuitem_id: ordritem_params[:menuitem_id],
              ordritemprice: ordritem_params[:ordritemprice],
              qty: 1,
            },
          )
          OrderEventProjector.project!(@ordr.id)
          @ordritem = Ordritem.find_by!(ordr_id: @ordr.id, line_key: line_key)
        rescue StandardError => e
          Rails.logger.error "Error creating order item (event-first): #{e.message}"
          format.html do
            redirect_back_or_to(root_path, alert: I18n.t('ordritems.errors.create_failed', default: 'Cannot add item right now'))
          end
          format.json { render json: { error: e.message }, status: :internal_server_error }
          raise ActiveRecord::Rollback
        end

        if @ordritem.present?
          begin
            mi = @ordritem.menuitem
            if mi&.alcoholic?
              AlcoholOrderEvent.create!(
                ordr: @ordritem.ordr,
                ordritem: @ordritem,
                menuitem: mi,
                restaurant: @ordritem.ordr.restaurant,
                employee_id: @current_employee&.id,
                customer_sessionid: session.id.to_s,
                alcoholic: true,
                abv: mi.try(:abv),
                alcohol_classification: mi.try(:alcohol_classification),
                age_check_acknowledged: @current_employee.present?,
                acknowledged_at: (@current_employee.present? ? Time.zone.now : nil),
              )
            end
          rescue StandardError => e
            Rails.logger.warn("[AlcoholOrderEvent] failed to create event: #{e.class}: #{e.message}")
          end
          adjust_inventory(@ordritem.menuitem&.inventory, -1)
          @ordrparticipant = find_or_create_participant(@ordritem.ordr)
          Ordraction.create!(ordrparticipant: @ordrparticipant, ordr: @ordritem.ordr, ordritem: @ordritem, action: 2)
          update_ordr(@ordritem.ordr)
          broadcast_partials(@ordritem.ordr, @ordritem.ordr.tablesetting, @ordrparticipant)
          broadcast_state(@ordritem.ordr, @ordritem.ordr.tablesetting, @ordrparticipant)
          format.html do
            redirect_to restaurant_ordrs_path(@restaurant || @ordritem.ordr.restaurant),
                        notice: 'Ordritem was successfully created.'
          end
          format.json do
            render :show, status: :created,
                          location: restaurant_ordritem_url(@restaurant || @ordritem.ordr.restaurant, @ordritem)
          end
        end
      end
    rescue StandardError => e
      Rails.logger.error "Error creating order item: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      format.json { render json: { error: e.message }, status: :internal_server_error }
    end
  end

  # PATCH/PUT /ordritems/1 or /ordritems/1.json
  def update
    # Always authorize - policy handles public vs private access
    authorize @ordritem

    respond_to do |format|
      ActiveRecord::Base.transaction do
        old_ordritem = @ordritem.dup
        if ordritem_params[:status].to_i == Ordritem.statuses['removed']
          begin
            order = @ordritem.ordr
            source = if request.headers['X-Order-Source'].to_s == 'voice'
                       'voice'
                     else
                       (current_user && @current_employee.present? ? 'staff' : 'guest')
                     end
            removed_line_key = @ordritem.line_key
            removed_ordritem_id = @ordritem.id
            menuitem = @ordritem.menuitem

            OrderEvent.emit!(
              ordr: order,
              event_type: 'item_removed',
              entity_type: 'item',
              entity_id: removed_ordritem_id,
              source: source,
              payload: {
                line_key: removed_line_key,
                ordritem_id: removed_ordritem_id,
              },
            )
            OrderEventProjector.project!(order.id)
            @ordritem.reload

            adjust_inventory(menuitem&.inventory, 1)
            update_ordr(order)
            participant = find_or_create_participant(order)
            Ordraction.create!(ordrparticipant: participant, ordr: order, ordritem: @ordritem, action: 3)
            broadcast_partials(order, order.tablesetting, participant)
            broadcast_state(order, order.tablesetting, participant)
            format.json { render :show, status: :ok, location: restaurant_ordritem_url(@restaurant || order.restaurant, @ordritem) }
          rescue StandardError => e
            Rails.logger.error("[OrderEvent] item_removed via update failed: #{e.class}: #{e.message}")
            format.json { render json: { error: e.message }, status: :internal_server_error }
            raise ActiveRecord::Rollback
          end
        elsif @ordritem.update(ordritem_params)
          # If menuitem_id changed, adjust old/new inventory
          if old_ordritem.menuitem_id != @ordritem.menuitem_id
            adjust_inventory(old_ordritem.menuitem&.inventory, 1)
            adjust_inventory(@ordritem.menuitem&.inventory, -1)
          end
          update_ordr(@ordritem.ordr)
          participant = find_or_create_participant(@ordritem.ordr)
          broadcast_partials(@ordritem.ordr, @ordritem.ordr.tablesetting, participant)
          broadcast_state(@ordritem.ordr, @ordritem.ordr.tablesetting, participant)
          format.json do
            render :show, status: :ok,
                          location: restaurant_ordritem_url(@restaurant || @ordritem.ordr.restaurant, @ordritem)
          end
        else
          format.html { render :edit, status: :unprocessable_content }
          format.json { render json: @ordritem.errors, status: :unprocessable_content }
        end
      end
    end
  end

  # DELETE /ordritems/1 or /ordritems/1.json
  def destroy
    # Always authorize - policy handles public vs private access
    authorize @ordritem

    begin
      ActiveRecord::Base.transaction do
        order = @ordritem.ordr
        source = if request.headers['X-Order-Source'].to_s == 'voice'
                   'voice'
                 else
                   (current_user && @current_employee.present? ? 'staff' : 'guest')
                 end
        removed_line_key = @ordritem.line_key
        removed_ordritem_id = @ordritem.id
        menuitem = @ordritem.menuitem

        begin
          OrderEvent.emit!(
            ordr: order,
            event_type: 'item_removed',
            entity_type: 'item',
            entity_id: removed_ordritem_id,
            source: source,
            payload: {
              line_key: removed_line_key,
              ordritem_id: removed_ordritem_id,
            },
          )
          OrderEventProjector.project!(order.id)
          @ordritem.reload
        rescue StandardError => e
          Rails.logger.error("[OrderEvent] item_removed event-first failed: #{e.class}: #{e.message}")
          raise ActiveRecord::Rollback
        end

        adjust_inventory(menuitem&.inventory, 1)
        update_ordr(order)
        ordrparticipant = find_or_create_participant(order)
        Ordraction.create!(ordrparticipant: ordrparticipant, ordr: order, ordritem: @ordritem, action: 3)
        broadcast_partials(order, order.tablesetting, ordrparticipant)
        broadcast_state(order, order.tablesetting, ordrparticipant)
        respond_to do |format|
          format.html do
            redirect_to restaurant_ordrs_path(@restaurant || order.restaurant),
                        notice: 'Ordritem was successfully destroyed.'
          end
          format.json { head :no_content }
        end
      end
    rescue StandardError => e
      Rails.logger.error "Error removing order item: #{e.message}"
      respond_to do |format|
        format.html do
          redirect_back_or_to(root_path, alert: I18n.t('ordritems.errors.remove_failed', default: 'Cannot remove item right now'))
        end
        format.json { render json: { error: e.message }, status: :internal_server_error }
      end
    end
  end

  private

  # Set restaurant from nested route parameter
  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id]) if params[:restaurant_id]
  end

  def adjust_inventory(inventory, delta)
    return unless inventory

    inventory.with_lock do
      inventory.currentinventory += delta
      inventory.currentinventory = 0 if inventory.currentinventory.negative?
      inventory.currentinventory = inventory.startinginventory if inventory.currentinventory > inventory.startinginventory
      inventory.save!
    end
  end

  def find_or_create_participant(ordr)
    if current_user && @current_employee
      Ordrparticipant.where(ordr: ordr, employee: @current_employee, role: 1,
                            sessionid: session.id.to_s,).first_or_create do |participant|
        participant.ordr = ordr
        participant.employee = @current_employee
        participant.role = 1
        participant.sessionid = session.id.to_s
      end
    else
      # For anonymous users or users without employee record
      Ordrparticipant.where(ordr: ordr, role: 0, sessionid: session.id.to_s).first_or_create do |participant|
        participant.ordr = ordr
        participant.role = 0
        participant.sessionid = session.id.to_s
      end
    end
  end

  def broadcast_partials(ordr, tablesetting, ordrparticipant)
    # Eager load all associations needed by partials to prevent N+1 queries
    ordr = Ordr.includes(menu: %i[restaurant menusections menuavailabilities]).find(ordr.id)
    menu = ordr.menu
    restaurant = menu.restaurant
    menuparticipant = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)
    allergyns = Allergyn.where(restaurant_id: restaurant.id)

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
    full_refresh = ordr.status == 'closed'
    ordrparticipant.preferredlocale = menuparticipant.preferredlocale if menuparticipant

    # Prefer the customer's ordrparticipant (role 0) when determining locale
    customer_ordrparticipant = ordr.ordrparticipants.where(role: 0).first

    # Determine a safe locale for rendering smartmenu partials
    available = I18n.available_locales.map(&:to_s)
    raw_locale = nil

    if customer_ordrparticipant&.preferredlocale.present? && available.include?(customer_ordrparticipant.preferredlocale.downcase)
      raw_locale = customer_ordrparticipant.preferredlocale.downcase
    elsif ordrparticipant&.preferredlocale.present? && available.include?(ordrparticipant.preferredlocale.downcase)
      raw_locale = ordrparticipant.preferredlocale.downcase
    elsif menuparticipant&.preferredlocale.present? && available.include?(menuparticipant.preferredlocale.downcase)
      raw_locale = menuparticipant.preferredlocale.downcase
    elsif restaurant.defaultLocale&.locale.present? && available.include?(restaurant.defaultLocale.locale.to_s.downcase)
      raw_locale = restaurant.defaultLocale.locale.to_s.downcase
    elsif available.include?(I18n.default_locale.to_s)
      raw_locale = I18n.default_locale.to_s
    end

    render_locale = (raw_locale || I18n.default_locale.to_s).to_sym

    partials = I18n.with_locale(render_locale) do
      {
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
          ),
        ),
        menuContentStaff: compress_string(
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
          ),
        ),
        menuContentCustomer: compress_string(
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentCustomer',
            locals: {
              order: ordr,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: customer_ordrparticipant,
              menuparticipant: menuparticipant,
              tablesetting: tablesetting,
            },
          ),
        ),
        orderCustomer: compress_string(
          ApplicationController.renderer.render(
            partial: 'smartmenus/orderCustomer',
            locals: {
              order: ordr,
              menu: menu,
              restaurant: restaurant,
              tablesetting: tablesetting,
              ordrparticipant: customer_ordrparticipant,
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
              ordrparticipant: customer_ordrparticipant,
              menuparticipant: menuparticipant,
              table_smartmenus: table_smartmenus,
              active_locales: active_locales,
              default_locale: default_locale,
            },
          ),
        ),
        fullPageRefresh: { refresh: full_refresh },
      }
    end
    # Only broadcast if menuparticipant and smartmenu exist
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
  def set_ordritem
    @ordritem = Ordritem.find(params[:id])
  end

  def update_ordr(ordr)
    ordr.nett = ordr.runningTotal
    taxes = Tax.where(restaurant_id: ordr.restaurant.id).order(sequence: :asc)
    totalTax = 0
    totalService = 0
    taxes.each do |tax|
      if tax.taxtype == 'service'
        totalService += ((tax.taxpercentage * ordr.nett.to_f) / 100)
      else
        totalTax += ((tax.taxpercentage * ordr.nett.to_f) / 100)
      end
    end
    ordr.tax = totalTax
    ordr.service = totalService
    # Use to_f to safely handle nil values
    ordr.gross = ordr.nett.to_f + ordr.tip.to_f + ordr.service.to_f + ordr.tax.to_f
    ordr.save
  end

  def set_currency
    if params[:id]
      @ordritem = Ordritem.find(params[:id])
      @restaurantCurrency = ISO4217::Currency.from_code(@ordritem.ordr.restaurant.currency || 'USD')
    else
      @restaurantCurrency = ISO4217::Currency.from_code('USD')
    end
  end

  # Only allow a list of trusted parameters through.
  def ordritem_params
    params.require(:ordritem).permit(:ordr_id, :menuitem_id, :ordritemprice, :status)
  end
end
