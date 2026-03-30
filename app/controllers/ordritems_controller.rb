class OrdritemsController < ApplicationController
  include CsrfSafeGuestActions

  before_action :authenticate_user!, except: %i[create update destroy] # Allow customers to manage order items
  skip_before_action :verify_authenticity_token, only: %i[create update destroy]
  before_action :set_restaurant
  before_action :set_ordritem, only: %i[show edit update destroy]
  before_action :validate_guest_ordritem_ownership, only: %i[update destroy], unless: :user_signed_in?
  before_action :set_currency
  before_action :require_valid_dining_session!, only: %i[create update destroy], unless: :user_signed_in?

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

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

    # Extract note separately (not an Ordritem attribute)
    item_note = ordritem_params[:note]

    # Always authorize - policy handles public vs private access
    authorize Ordritem.new(ordritem_params.except(:note))

    requested_qty = (ordritem_params[:quantity] || 1).to_i.clamp(1, 99)
    menuitem = Menuitem.find_by(id: ordritem_params[:menuitem_id])
    if @ordr.menu&.inventoryTracking && menuitem&.inventory&.active?
      available_inventory = menuitem.inventory.currentinventory.to_i
      if available_inventory < requested_qty
        respond_to do |format|
          format.html do
            redirect_back_or_to(root_path, alert: "Only #{available_inventory} item(s) available")
          end
          format.json do
            render json: { error: 'insufficient_inventory', available: available_inventory }, status: :unprocessable_content
          end
        end
        return
      end
    end

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
              size_name: ordritem_params[:size_name],
              qty: requested_qty,
            },
          )
          OrderEventProjector.project!(@ordr.id)
          @ordritem = Ordritem.find_by(ordr_id: @ordr.id, line_key: line_key) ||
                      Ordritem.find_by!(
                        ordr_id: @ordr.id,
                        menuitem_id: ordritem_params[:menuitem_id],
                        size_name: ordritem_params[:size_name].presence,
                        status: :opened,
                      )
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

          # Create ordritemnote if note was provided
          if item_note.present?
            begin
              Ordritemnote.create!(
                ordritem: @ordritem,
                note: item_note,
              )
            rescue StandardError => e
              Rails.logger.warn("[Ordritemnote] failed to create note: #{e.class}: #{e.message}")
            end
          end

          adjust_inventory(@ordritem.menuitem&.inventory, -@ordritem.quantity)
          @ordrparticipant = find_or_create_participant(@ordritem.ordr)
          Ordraction.create!(ordrparticipant: @ordrparticipant, ordr: @ordritem.ordr, ordritem: @ordritem, action: 2)
          update_ordr(@ordritem.ordr)
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
            broadcast_state(order, order.tablesetting, participant)
            format.json { render :show, status: :ok, location: restaurant_ordritem_url(@restaurant || order.restaurant, @ordritem) }
          rescue StandardError => e
            Rails.logger.error("[OrderEvent] item_removed via update failed: #{e.class}: #{e.message}")
            format.json { render json: { error: e.message }, status: :internal_server_error }
            raise ActiveRecord::Rollback
          end
        else
          if ordritem_params.key?(:quantity)
            requested_quantity = ordritem_params[:quantity].to_i.clamp(1, 99)
            quantity_delta = requested_quantity - @ordritem.quantity.to_i
            if quantity_delta.positive? && @ordritem.ordr.menu&.inventoryTracking && @ordritem.menuitem&.inventory&.active?
              available_inventory = @ordritem.menuitem.inventory.currentinventory.to_i
              if available_inventory < quantity_delta
                format.json do
                  render json: {
                    error: 'insufficient_inventory',
                    available: available_inventory,
                    requested_increase: quantity_delta,
                  }, status: :unprocessable_content
                end
                raise ActiveRecord::Rollback
              end
            end
          end

          sanitized_params = ordritem_params.to_h
          sanitized_params['quantity'] = ordritem_params[:quantity].to_i.clamp(1, 99) if ordritem_params.key?(:quantity)

          if @ordritem.update(sanitized_params)
            # If menuitem_id changed, adjust old/new inventory
            if old_ordritem.menuitem_id != @ordritem.menuitem_id
              adjust_inventory(old_ordritem.menuitem&.inventory, old_ordritem.quantity.to_i)
              adjust_inventory(@ordritem.menuitem&.inventory, -@ordritem.quantity.to_i)
            elsif old_ordritem.quantity.to_i != @ordritem.quantity.to_i
              adjust_inventory(@ordritem.menuitem&.inventory, old_ordritem.quantity.to_i - @ordritem.quantity.to_i)
            end
            update_ordr(@ordritem.ordr)
            participant = find_or_create_participant(@ordritem.ordr)
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

  def csrf_skipped_action?
    %w[create update destroy].include?(action_name)
  end

  # Prevent anonymous users from mutating ordr items that don't belong to their session.
  # The Pundit policy allows any anonymous request, so we enforce session-level ownership
  # here before authorization runs. Authenticated users are covered by Pundit's owner? check.
  def validate_guest_ordritem_ownership
    return unless @ordritem

    # Collect all candidate session IDs. smartmenus_controller stores participants
    # using session.id.to_s first (safe_session_id), while older flows may use
    # session[:sid]. Accept either to avoid false 403s.
    sid_candidates = [
      session.id.to_s.presence,
      session[:sid].presence,
    ].compact.uniq
    return if sid_candidates.empty?

    has_session = Ordrparticipant.exists?(
      ordr_id: @ordritem.ordr_id,
      sessionid: sid_candidates,
    )

    return if has_session

    Rails.logger.warn(
      "[SECURITY] Guest sessions #{sid_candidates.inspect} attempted to mutate ordritem #{@ordritem.id} " \
      "(ordr #{@ordritem.ordr_id}) without a matching participant record",
    )
    respond_to do |format|
      format.json { render json: { error: 'forbidden' }, status: :forbidden }
      format.html { redirect_to root_path, alert: 'Not authorized.' }
    end
  end

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
    # Match safe_session_id priority in smartmenus_controller: prefer session.id.to_s
    # (reliable on all but the very first response) with session[:sid] UUID as fallback.
    sid = session.id.to_s.presence || (session[:sid] ||= SecureRandom.uuid)
    if current_user && @current_employee
      Ordrparticipant.where(ordr: ordr, employee: @current_employee, role: 1,
                            sessionid: sid,).first_or_create do |participant|
        participant.ordr = ordr
        participant.employee = @current_employee
        participant.role = 1
        participant.sessionid = sid
      end
    else
      # For anonymous users or users without employee record
      Ordrparticipant.where(ordr: ordr, role: 0, sessionid: sid).first_or_create do |participant|
        participant.ordr = ordr
        participant.role = 0
        participant.sessionid = sid
      end
    end
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
    taxable_amount = ordr.nett.to_f + ordr.covercharge.to_f
    taxes.each do |tax|
      if tax.taxtype == 'service'
        totalService += ((tax.taxpercentage * taxable_amount) / 100)
      else
        totalTax += ((tax.taxpercentage * taxable_amount) / 100)
      end
    end
    ordr.tax = totalTax
    ordr.service = totalService
    # Use to_f to safely handle nil values; include covercharge to match OrdrsController#calculate_order_totals
    ordr.gross = ordr.nett.to_f + ordr.covercharge.to_f + ordr.tip.to_f + ordr.service.to_f + ordr.tax.to_f
    ordr.save
  end

  def set_currency
    # Performance: re-use @ordritem loaded by set_ordritem (same before_action chain).
    # Only fall back to a fresh find when @ordritem is not yet assigned (e.g. non-resource actions).
    if @ordritem || params[:id]
      @ordritem ||= Ordritem.find(params[:id])
      @restaurantCurrency = ISO4217::Currency.from_code(@ordritem.ordr.restaurant.currency || 'USD')
    else
      @restaurantCurrency = ISO4217::Currency.from_code('USD')
    end
  end

  # Only allow a list of trusted parameters through.
  def ordritem_params
    params.require(:ordritem).permit(:ordr_id, :menuitem_id, :ordritemprice, :status, :size_name, :quantity, :note)
  end

  def broadcast_state(ordr, tablesetting, ordrparticipant)
    # Eager load ordritemnotes to ensure notes are included in broadcast
    ordr = Ordr.includes(ordritems: :ordritemnotes).find(ordr.id)
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
end
