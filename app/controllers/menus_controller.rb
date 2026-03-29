require 'rqrcode'

class MenusController < Menus::BaseController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_menu, only: %i[show edit update destroy update_availabilities]
  before_action :ensure_owner_restaurant_context!, only: %i[update destroy update_availabilities]

  skip_around_action :switch_locale, only: %i[update_sequence bulk_update]

  # verify_authorized is inherited from Menus::BaseController
  skip_after_action :verify_authorized, only: %i[index update_sequence bulk_update]
  after_action :verify_policy_scoped, only: [:index], unless: :skip_policy_scope?

  # GET /restaurants/:restaurant_id/menus
  def index
    @today = Time.zone.today.strftime('%A').downcase!
    @currentHour = Time.now.strftime('%H').to_i
    @currentMin = Time.now.strftime('%M').to_i

    if current_user
      @menus = if @restaurant
                 base = policy_scope(Menu)
                   .distinct(false)
                   .joins(:restaurant_menus)
                   .where(restaurant_menus: { restaurant_id: @restaurant.id })
                   .for_management_display
                   .where(archived: false)
                   .order(Arel.sql('CASE WHEN restaurant_menus.sequence IS NULL THEN 1 ELSE 0 END, restaurant_menus.sequence ASC'))

                 request.format.json? ? base.includes(menusections: :menuitems, menuavailabilities: []) : base
               else
                 policy_scope(Menu).for_management_display.order(:sequence)
               end

      unless request.format.json?
        AnalyticsService.track_user_event(current_user, 'menus_viewed', {
          menus_count: @menus.size,
          restaurant_id: @restaurant&.id,
          viewing_context: params[:restaurant_id] ? 'restaurant_specific' : 'all_menus',
        })
      end
    elsif params[:restaurant_id]
      @restaurant = Restaurant.find_by(id: params[:restaurant_id])
      unless @restaurant
        redirect_to root_url, alert: 'Restaurant not found'
        return
      end
      @menus = Menu.joins(:restaurant_menus)
        .where(restaurant_menus: { restaurant_id: @restaurant.id, status: RestaurantMenu.statuses[:active] })
        .for_customer_display
        .where(archived: false)
        .order(Arel.sql('CASE WHEN restaurant_menus.sequence IS NULL THEN 1 ELSE 0 END, restaurant_menus.sequence ASC'))
      @tablesettings = @restaurant.tablesettings
      anonymous_id = session[:session_id] ||= SecureRandom.uuid
      AnalyticsService.track_anonymous_event(anonymous_id, 'menus_viewed_anonymous', {
        menus_count: @menus.count,
        restaurant_id: @restaurant.id,
        restaurant_name: @restaurant.name,
      })
    end

    respond_to do |format|
      format.html
      format.json { render 'index_minimal' }
    end
  end

  # GET /restaurants/:restaurant_id/menus/:id
  def show
    authorize @menu
    return unless params[:menu_id] && params[:id]

    if params[:restaurant_id]
      @restaurant = Restaurant.find_by(id: params[:restaurant_id])
      @menu = Menu.find_by(id: params[:menu_id])
      unless @menu
        redirect_to root_url
        return
      end
      if @menu.restaurant != @restaurant
        redirect_to root_url
        return
      end

      locale = params[:locale] || 'en'
      @menu_data = AdvancedCacheService.cached_menu_with_items(@menu.id, locale: locale, include_inactive: false)

      trigger_strategic_cache_warming

      if current_user
        AnalyticsService.track_user_event(current_user, AnalyticsService::MENU_VIEWED, {
          restaurant_id: @menu.restaurant.id,
          menu_id: @menu.id,
          menu_name: @menu.name,
          items_count: @menu_data[:metadata][:active_items],
          sections_count: @menu_data[:sections].count,
        })
      else
        anonymous_id = session[:session_id] ||= SecureRandom.uuid
        AnalyticsService.track_anonymous_event(anonymous_id, 'menu_viewed_anonymous', {
          restaurant_id: @menu.restaurant.id,
          menu_id: @menu.id,
          menu_name: @menu.name,
          items_count: @menu_data[:metadata][:active_items],
        })
      end
    end
    @participantsFirstTime = false
    @tablesetting = Tablesetting.find_by(id: params[:id])
    return unless @tablesetting

    @openOrder = Ordr.where(
      menu_id: params[:menu_id],
      tablesetting_id: params[:id],
      restaurant_id: @tablesetting.restaurant_id,
      status: [0, 20, 30],
    ).first
    return unless @openOrder

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
  end

  # GET /restaurants/:restaurant_id/menus/new
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
      properties: { restaurant_id: @menu.restaurant&.id },
    )
  end

  # GET /restaurants/:restaurant_id/menus/:id/edit
  def edit
    authorize @menu

    if params[:menu_id] && params[:id]
      if params[:restaurant_id]
        @restaurant = Restaurant.find_by(id: params[:restaurant_id])
        @menu = Menu.find_by(id: params[:menu_id])
        unless @menu
          redirect_to root_url
          return
        end
        if @menu.restaurant != @restaurant
          redirect_to root_url
          return
        end
      end
      Analytics.track(
        event: 'menus.edit',
        properties: { restaurant_id: @menu.restaurant.id, menu_id: @menu.id },
      )
    end
    respond_to do |format|
      format.html do
        ActiveRecord::Base.connected_to(role: :writing) do
          if @menu.smartmenu&.slug
            @qrURL = Rails.application.routes.url_helpers.smartmenu_url(@menu.smartmenu.slug, host: request.host_with_port)
            @qrURL.sub! 'http', 'https'
            @qr = RQRCode::QRCode.new(@qrURL)
          end

          @current_section = params[:section] || 'details'

          unless params[:old_ui] == 'true'
            if turbo_frame_request_id == 'menu_content'
              render partial: 'menus/section_frame_2025',
                     locals: {
                       menu: @menu,
                       partial_name: menu_section_partial_name(@current_section),
                       restaurant: @restaurant || @menu.restaurant,
                       restaurant_menu: @restaurant_menu,
                       read_only: @read_only_menu_context,
                     }
            else
              render :edit_2025
            end
          end
        end
      end
      format.json { head :ok }
    end
  end

  # POST /restaurants/:restaurant_id/menus
  def create
    context_restaurant = @restaurant || Restaurant.find(menu_params[:restaurant_id])
    @menu = context_restaurant.menus.build(menu_params)
    authorize @menu

    plan = current_user&.plan
    menus_limit = plan&.menusperlocation
    if menus_limit.present? && menus_limit != -1 && !current_user&.super_admin?
      active_menu_count = Menu.where(restaurant: context_restaurant, status: 'active', archived: false).count
      if active_menu_count >= menus_limit
        @menu.errors.add(:base, 'Your plan limit has been reached for number of menus')
        respond_to do |format|
          format.html { redirect_to edit_restaurant_path(id: context_restaurant.id), alert: @menu.errors.full_messages.to_sentence }
          format.json { render json: { errors: @menu.errors.full_messages }, status: :unprocessable_content }
        end
        return
      end
    end

    respond_to do |format|
      if (params.dig(:menu, :remove_pdf_menu_scan) == '1') && @menu.pdf_menu_scan.attached?
        @menu.pdf_menu_scan.purge
      end
      if @menu.save
        Analytics.track(
          user_id: current_user.id,
          event: 'menus.create',
          properties: { restaurant_id: @menu.restaurant.id, menu_id: @menu.id },
        )
        if @menu.genimage.nil?
          @genimage = Genimage.new(restaurant: @menu.restaurant, menu: @menu,
                                   created_at: DateTime.current, updated_at: DateTime.current,)
          @genimage.save
        end
        SmartMenuGeneratorJob.perform_async(@menu.restaurant.id)
        format.html { redirect_to edit_restaurant_path(id: @menu.restaurant.id), notice: t('common.flash.created', resource: t('activerecord.models.menu')) }
        format.json { render :show, status: :created, location: restaurant_menu_url(@restaurant || @menu.restaurant, @menu) }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @menu.errors, status: :unprocessable_content }
      end
    end
  rescue ArgumentError => e
    @menu = Menu.new
    @menu.errors.add(:status, e.message)
    respond_to do |format|
      format.html { render :new, status: :unprocessable_content }
      format.json { render json: @menu.errors, status: :unprocessable_content }
    end
  end

  # PATCH/PUT /restaurants/:restaurant_id/menus/:id
  def update
    authorize @menu

    respond_to do |format|
      if (params.dig(:menu, :remove_pdf_menu_scan) == '1') && @menu.pdf_menu_scan.attached?
        @menu.pdf_menu_scan.purge
      end

      raw_menu = params[:menu]
      status_value = params.dig(:menu, :status) || params[:status]
      attrs = {}
      if raw_menu.is_a?(ActionController::Parameters)
        begin
          attrs.merge!(menu_params.to_h)
        rescue StandardError => e
          Rails.logger.warn("[MenusController#update] menu_params error: #{e.message}")
        end
      end
      attrs[:status] = status_value if status_value.present?

      if attrs[:status].to_s == 'active'
        context_restaurant = @restaurant || @menu.owner_restaurant || @menu.restaurant
        unless context_restaurant&.publish_allowed?
          @menu.errors.add(:base, 'Publishing requires an active subscription with a payment method on file')
          format.html do
            redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu), alert: @menu.errors.full_messages.to_sentence
          end
          format.json { render json: { errors: @menu.errors.full_messages }, status: :unprocessable_content }
          next
        end
      end

      @menu.assign_attributes(attrs)
      updated = @menu.changed? ? @menu.save : true
      @menu.reload if updated

      if updated
        AdvancedCacheService.invalidate_menu_caches(@menu.id)
        AdvancedCacheService.invalidate_restaurant_caches(@menu.restaurant.id)

        Analytics.track(
          user_id: current_user.id,
          event: 'menus.update',
          properties: { restaurant_id: @menu.restaurant.id, menu_id: @menu.id },
        )
        if @menu.genimage.nil?
          @genimage = Genimage.new(restaurant: @menu.restaurant, menu: @menu,
                                   created_at: DateTime.current, updated_at: DateTime.current,)
          @genimage.save
        end
        SmartMenuGeneratorJob.perform_async(@menu.restaurant.id)
        format.html do
          if turbo_frame_request_id == 'menu_content'
            @current_section = 'settings'
            render partial: 'menus/section_frame_2025',
                   locals: { menu: @menu, partial_name: menu_section_partial_name(@current_section),
                             restaurant: @restaurant || @menu.restaurant, restaurant_menu: @restaurant_menu,
                             read_only: @read_only_menu_context, }
          elsif params[:return_to] == 'menu_edit'
            redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu), notice: t('common.flash.updated', resource: t('activerecord.models.menu'))
          else
            redirect_to edit_restaurant_path(id: @menu.restaurant.id), notice: t('common.flash.updated', resource: t('activerecord.models.menu'))
          end
        end
        format.json { render :show, status: :ok, location: restaurant_menu_url(@restaurant || @menu.restaurant, @menu) }
      else
        format.html do
          if turbo_frame_request_id == 'menu_content'
            @current_section = 'settings'
            render partial: 'menus/section_frame_2025',
                   locals: { menu: @menu, partial_name: menu_section_partial_name(@current_section),
                             restaurant: @restaurant || @menu.restaurant, restaurant_menu: @restaurant_menu,
                             read_only: @read_only_menu_context, },
                   status: :unprocessable_content
          elsif params[:return_to] == 'menu_edit'
            redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu), alert: @menu.errors.full_messages.presence || 'Failed to update menu'
          else
            render :edit, status: :unprocessable_content
          end
        end
        format.json { render json: @menu.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH /restaurants/:restaurant_id/menus/:id/update_availabilities
  def update_availabilities
    authorize @menu

    availabilities_params = params[:availabilities] || {}

    availabilities_params.each do |day, times|
      availability = @menu.menuavailabilities.find_or_initialize_by(dayofweek: day, sequence: 1)

      start_time = times[:start] || times['start']
      end_time = times[:end] || times['end']

      if start_time.present? && end_time.present?
        start_parts = start_time.split(':')
        end_parts = end_time.split(':')
        availability.starthour = start_parts[0].to_i
        availability.startmin = start_parts[1].to_i
        availability.endhour = end_parts[0].to_i
        availability.endmin = end_parts[1].to_i
        availability.status = :active
      end

      unless availability.save
        Rails.logger.error "[UpdateAvailabilities] Failed to save availability for #{day}: #{availability.errors.full_messages}"
      end
    end

    if params[:inactive].is_a?(Hash)
      params[:inactive].each do |day, is_inactive|
        next unless is_inactive == '1'

        availability = @menu.menuavailabilities.find_or_initialize_by(dayofweek: day, sequence: 1)
        availability.status = :inactive
        unless availability.save
          Rails.logger.error "[UpdateAvailabilities] Failed to mark #{day} as inactive: #{availability.errors.full_messages}"
        end
      end
    end

    AdvancedCacheService.invalidate_menu_caches(@menu.id) if defined?(AdvancedCacheService)
    AdvancedCacheService.invalidate_restaurant_caches(@menu.restaurant.id) if defined?(AdvancedCacheService)

    respond_to do |format|
      format.json { render json: { success: true, message: 'Availabilities saved successfully' }, status: :ok }
      format.html { redirect_to edit_restaurant_menu_path(@restaurant, @menu, section: 'schedule'), notice: 'Availabilities updated successfully' }
    end
  rescue StandardError => e
    Rails.logger.error("Error updating availabilities: #{e.message}")
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_content }
      format.html { redirect_to edit_restaurant_menu_path(@restaurant, @menu, section: 'schedule'), alert: 'Failed to update availabilities' }
    end
  end

  # DELETE /restaurants/:restaurant_id/menus/:id
  def destroy
    authorize @menu

    @menu.update(archived: true)
    AdvancedCacheService.invalidate_menu_caches(@menu.id)
    AdvancedCacheService.invalidate_restaurant_caches(@menu.restaurant.id)

    Analytics.track(
      user_id: current_user.id,
      event: 'menus.destroy',
      properties: { restaurant_id: @menu.restaurant.id, menu_id: @menu.id },
    )
    respond_to do |format|
      format.html { redirect_to edit_restaurant_path(id: @menu.restaurant.id), notice: t('common.flash.deleted', resource: t('activerecord.models.menu')) }
      format.json { head :no_content }
    end
  end

  # PATCH /restaurants/:restaurant_id/menus/update_sequence
  def update_sequence
    unless @restaurant.user_id == current_user.id
      return render json: { status: 'error', message: 'Unauthorized' }, status: :forbidden
    end

    order = params[:order] || []

    if order.blank?
      return render json: { status: 'error', message: 'No order data provided' }, status: :unprocessable_content
    end

    ActiveRecord::Base.transaction do
      order.each do |item|
        item_hash = item.is_a?(ActionController::Parameters) ? item.to_unsafe_h : item
        next unless item_hash.is_a?(Hash)

        id = item_hash[:id] || item_hash['id']
        seq = item_hash[:sequence] || item_hash['sequence']
        next if id.blank? || seq.nil?

        menu = Menu.joins(:restaurant_menus)
          .where(restaurant_menus: { restaurant_id: @restaurant.id })
          .find(id)
        authorize menu, :update?
        menu.update_column(:sequence, seq.to_i)
      end
    end

    render json: { status: 'success', message: 'Menus reordered successfully' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Menu not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "Update sequence error: #{e.message}"
    render json: { status: 'error', message: e.message }, status: :unprocessable_content
  end

  # PATCH /restaurants/:restaurant_id/menus/bulk_update
  def bulk_update
    ids = Array(params[:menu_ids]).map(&:to_s).compact_blank
    status = params[:status].to_s

    if ids.empty? || status.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('restaurant_content', partial: 'restaurants/sections/menus_2025', locals: { restaurant: @restaurant, filter: 'all' })
        end
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'menus') }
      end
      return
    end

    menus = policy_scope(Menu)
      .joins(:restaurant_menus)
      .where(restaurant_menus: { restaurant_id: @restaurant.id })
      .where(archived: false)
      .where(id: ids)

    if status == 'active' && !current_user_has_active_subscription?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('restaurant_content', partial: 'restaurants/sections/menus_2025', locals: { restaurant: @restaurant, filter: 'all' })
        end
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'You need an active subscription to activate a menu.' }
      end
      return
    end

    menus.find_each do |menu|
      authorize menu, :update?
      menu.update(status: status)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace('restaurant_content', partial: 'restaurants/sections/menus_2025', locals: { restaurant: @restaurant, filter: 'all' })
      end
      format.html { redirect_to edit_restaurant_path(@restaurant, section: 'menus') }
    end
  end

  private

  def menu_section_partial_name(section)
    case section
    when 'details' then 'details_2025'
    when 'sections' then 'sections_2025'
    when 'items' then 'items_2025'
    when 'schedule' then 'schedule_2025'
    when 'settings' then 'settings_2025'
    when 'qrcode' then 'qrcode_2025'
    when 'versions' then 'versions_2025'
    when 'profitability' then 'profitability_2025'
    else 'details_2025'
    end
  end

  def skip_policy_scope?
    current_user.blank? || (@restaurant.present? && request.format.json? && current_user.present?)
  end

  def menu_params
    params.require(:menu).permit(:name, :description, :image, :remove_image, :pdf_menu_scan, :status, :sequence,
                                 :restaurant_id, :displayImages, :displayImagesInPopup, :allowOrdering, :voiceOrderingEnabled, :inventoryTracking, :imagecontext, :covercharge, :test,)
  end
end
