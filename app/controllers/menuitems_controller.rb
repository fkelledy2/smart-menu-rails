class MenuitemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_menuitem, only: %i[show edit update destroy analytics generate_ai_image image_status]
  before_action :set_currency
  before_action :ensure_owner_restaurant_context_for_menu!, only: %i[new edit create update destroy reorder generate_ai_image bulk_update]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index], unless: :skip_policy_scope_for_json?

  # GET /menus/:menu_id/menuitems or /menuitems/1/analytics
  def index
    if params[:menusection_id]
      menusection = Menusection.find_by(id: params[:menusection_id])
      authorize menusection.menu, :show? # Authorize access to the menu

      # Optimize query based on request format
      @menuitems = if request.format.json?
                     # JSON: Direct association with minimal includes for performance
                     menusection.menuitems.includes(:genimage, :inventory,
                                                    menusection: { menu: :restaurant },).order(:sequence)
                   else
                     # HTML: Use AdvancedCacheServiceV2 for comprehensive data
                     @section_items_data = AdvancedCacheServiceV2.cached_section_items_with_details(menusection.id)
                     policy_scope(@section_items_data[:items])
                   end

      # Track section items view
      AnalyticsService.track_user_event(current_user, 'section_items_viewed', {
        menusection_id: menusection.id,
        menusection_name: menusection.name,
        menu_id: menusection.menu.id,
        restaurant_id: menusection.menu.restaurant.id,
        items_count: @menuitems.count,
      },)
    elsif params[:menu_id]
      @menu = Menu.find(params[:menu_id])
      authorize @menu, :show? # Authorize access to the menu

      # Optimize query based on request format
      @menuitems = if request.format.json?
                     # JSON: Direct association with minimal includes for performance
                     @menu.menuitems.includes(:genimage, :inventory,
                                              menusection: { menu: :restaurant },).order(:sequence)
                   else
                     # HTML: Use AdvancedCacheServiceV2 for comprehensive data
                     @menu_items_data = AdvancedCacheServiceV2.cached_menu_items_with_details(@menu.id,
                                                                                              include_analytics: true,)
                     policy_scope(@menu_items_data[:items])
                   end

      # Track menu items view (only for HTML requests to avoid overhead)
      unless request.format.json?
        AnalyticsService.track_user_event(current_user, 'menu_items_viewed', {
          menu_id: @menu.id,
          menu_name: @menu.name,
          restaurant_id: @menu.restaurant.id,
          items_count: @menuitems.count,
          viewing_context: 'menu_management',
        },)
      end

    else
      @menuitems = policy_scope(Menuitem.none) # Empty scope with policy applied
    end

    # Use minimal JSON view for better performance
    respond_to do |format|
      format.html # Default HTML view
      format.json { render 'index_minimal' } # Use optimized minimal JSON view
    end
  end

  # PATCH /restaurants/:restaurant_id/menus/:menu_id/menuitems/bulk_update
  def bulk_update
    @menu = Menu.find(params[:menu_id])
    @restaurant = @menu.restaurant
    authorize @menu, :update?

    menuitem_ids = Array(params[:menuitem_ids]).compact_blank.map(&:to_i)
    operation = params[:operation].to_s
    value = params[:value]

    Rails.logger.info({
      event: 'menuitems.bulk_update.request',
      user_id: current_user&.id,
      restaurant_id: @restaurant.id,
      menu_id: @menu.id,
      operation: operation,
      value: value,
      menuitem_ids_count: menuitem_ids.size,
      menuitem_ids_sample: menuitem_ids.first(20),
    }.to_json)

    selected_ids = Menuitem.on_primary do
      Menuitem.joins(:menusection)
        .where(menusections: { menu_id: @menu.id })
        .where(id: menuitem_ids)
        .pluck(:id)
    end

    if menuitem_ids.blank? || selected_ids.blank?
      Rails.logger.info({
        event: 'menuitems.bulk_update.no_selection',
        user_id: current_user&.id,
        restaurant_id: @restaurant.id,
        menu_id: @menu.id,
        operation: operation,
        value: value,
      }.to_json)
      return redirect_to edit_restaurant_menu_path(@restaurant, @menu, section: 'items'),
                         alert: 'No items selected'
    end

    case operation
    when 'archive'
      # No additional value required; operation is the intent.
      nil
    when 'set_status'
      status = value.to_s
      return redirect_to(edit_restaurant_menu_path(@restaurant, @menu, section: 'items'), alert: 'Invalid status') unless Menuitem.statuses.key?(status)
    when 'set_itemtype'
      itemtype = value.to_s
      return redirect_to(edit_restaurant_menu_path(@restaurant, @menu, section: 'items'), alert: 'Invalid food type') unless Menuitem.itemtypes.key?(itemtype)
    when 'set_alcoholic'
      return redirect_to(edit_restaurant_menu_path(@restaurant, @menu, section: 'items'), alert: 'Invalid alcoholic value') if value.nil? || value.to_s == ''
    else
      return redirect_to edit_restaurant_menu_path(@restaurant, @menu, section: 'items'),
                         alert: 'Invalid bulk operation'
    end

    updated = 0
    archived_ids = []
    Menuitem.on_primary do
      Menuitem.transaction do
        items = Menuitem.where(id: selected_ids)

        case operation
        when 'archive'
          archived_ids = selected_ids
          archived_status_value = Menuitem.statuses['archived']
          updated = items.update_all(status: archived_status_value, archived: true, updated_at: Time.current)
        when 'set_status'
          status = value.to_s
          items.find_each do |item|
            item.update!(status: status)
            updated += 1
          end
        when 'set_itemtype'
          itemtype = value.to_s
          items.find_each do |item|
            item.update!(itemtype: itemtype)
            updated += 1
          end
        when 'set_alcoholic'
          bool = ActiveModel::Type::Boolean.new.cast(value)
          items.find_each do |item|
            attrs = {}
            if bool
              if item.alcohol_classification.to_s == 'non_alcoholic' || item.alcohol_classification.to_s.strip == ''
                attrs[:alcohol_classification] = 'other'
              end
            else
              attrs[:alcohol_classification] = 'non_alcoholic'
              attrs[:abv] = 0
            end
            item.update!(attrs)
            updated += 1
          end
        else
          raise ActiveRecord::Rollback
        end
      end
    end

    # Invalidate caches once per menu/restaurant (avoid per-item invalidation cost)
    begin
      archived_ids.each do |id|
        AdvancedCacheService.invalidate_menuitem_caches(id)
      end
      AdvancedCacheService.invalidate_menu_caches(@menu.id)
      AdvancedCacheService.invalidate_restaurant_caches(@restaurant.id)
    rescue StandardError
      nil
    end

    redirect_to edit_restaurant_menu_path(@restaurant, @menu, section: 'items'),
                notice: "Updated #{updated} item#{updated == 1 ? '' : 's'}"
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_restaurant_path(params[:restaurant_id], section: 'menus'), alert: 'Menu not found'
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_restaurant_menu_path(@restaurant, @menu, section: 'items'), alert: e.record.errors.full_messages.first
  ensure
    Rails.logger.info({
      event: 'menuitems.bulk_update.complete',
      user_id: current_user&.id,
      restaurant_id: @restaurant&.id,
      menu_id: @menu&.id,
      operation: operation,
      value: value,
      updated_count: defined?(updated) ? updated : nil,
    }.to_json)
  end

  # POST /restaurants/:restaurant_id/menus/:menu_id/menusections/:menusection_id/menuitems/:id/generate_ai_image
  def generate_ai_image
    authorize @menuitem, :update?

    # Ensure there's a genimage record for this item
    if @menuitem.genimage.nil?
      @genimage = Genimage.new
      @genimage.restaurant = @menuitem.menusection.menu.restaurant
      @genimage.menu = @menuitem.menusection.menu
      @genimage.menusection = @menuitem.menusection
      @genimage.menuitem = @menuitem
      @genimage.created_at = DateTime.current
      @genimage.updated_at = DateTime.current
      @genimage.save
    end

    if @menuitem.itemtype != 'wine' && @menuitem.genimage.present?
      MenuItemImageGeneratorJob.perform_async(@menuitem.genimage.id)
    end

    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_menu_menusection_menuitem_path(
          @menuitem.menusection.menu.restaurant,
          @menuitem.menusection.menu,
          @menuitem.menusection,
          @menuitem,
        )
      end
      format.json { render json: { status: 'queued' } }
    end
  end

  # GET /restaurants/:restaurant_id/menus/:menu_id/menusections/:menusection_id/menuitems/:id/image_status
  def image_status
    authorize @menuitem, :show?

    image_url = @menuitem.webp_url(:medium) || @menuitem.medium_url || @menuitem.image_url
    render json: {
      menuitem_id: @menuitem.id,
      updated_at: @menuitem.updated_at.to_i,
      has_image: @menuitem.image.present?,
      image_url: image_url,
    }
  end

  # GET /menuitems/1 or /menuitems/1.json
  def show
    authorize @menuitem

    # Use AdvancedCacheServiceV2 for comprehensive menuitem data (returns model instances)
    @menuitem_data = AdvancedCacheServiceV2.cached_menuitem_with_analytics(@menuitem.id)

    # Track menuitem view
    AnalyticsService.track_user_event(current_user, 'menuitem_viewed', {
      menuitem_id: @menuitem.id,
      menuitem_name: @menuitem.name,
      menu_id: @menuitem.menusection.menu.id,
      restaurant_id: @menuitem.menusection.menu.restaurant.id,
      price: @menuitem.price,
      has_image: @menuitem.image.present?,
    },)
  end

  # GET /menuitems/1/analytics
  def analytics
    authorize @menuitem, :show?

    # Get analytics period from params or default to 30 days
    days = params[:days]&.to_i || 30

    # Use AdvancedCacheService for menuitem performance analytics
    @analytics_data = AdvancedCacheService.cached_menuitem_performance(@menuitem.id, days: days)

    # Track analytics view
    AnalyticsService.track_user_event(current_user, 'menuitem_analytics_viewed', {
      menuitem_id: @menuitem.id,
      menuitem_name: @menuitem.name,
      period_days: days,
      total_orders: @analytics_data[:performance][:total_orders],
      total_revenue: @analytics_data[:performance][:total_revenue],
    },)

    respond_to do |format|
      format.html
      format.json { render json: @analytics_data }
    end
  end

  # GET /menus/:menu_id/menusections/:menusection_id/menuitems/new
  def new
    @menuitem = Menuitem.new

    # Menuitems are always nested under menusections
    if params[:menusection_id]
      @futureParentMenuSection = Menusection.find_by(id: params[:menusection_id])
      @menuitem.menusection = @futureParentMenuSection
      @menu = @futureParentMenuSection&.menu
    elsif params[:menu_id]
      # If only menu_id is provided, redirect to menu edit page
      # User should create menuitem from within a menusection
      @menu = Menu.find(params[:menu_id])
      redirect_to edit_restaurant_menu_path(@menu.restaurant, @menu),
                  alert: t('menuitems.errors.menusection_required')
      return
    end

    # Set default values
    @menuitem.sequence = 999
    @menuitem.calories = 0
    @menuitem.price = 0
    @menuitem.sizesupport = false

    authorize @menuitem
  end

  # GET /menuitems/1/edit
  def edit
    authorize @menuitem
    
    # Use 2025 UI
    render 'edit_2025'
  end

  # POST /menuitems or /menuitems.json
  def create
    @menuitem = Menuitem.new(menuitem_params)
    authorize @menuitem

    respond_to do |format|
      if @menuitem.save
        if @menuitem.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @menuitem.menusection.menu.restaurant
          @genimage.menu = @menuitem.menusection.menu
          @genimage.menusection = @menuitem.menusection
          @genimage.menuitem = @menuitem
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
        format.html do
          redirect_to edit_restaurant_menu_menusection_menuitem_url(
            @menuitem.menusection.menu.restaurant,
            @menuitem.menusection.menu,
            @menuitem.menusection,
            @menuitem,
          ), notice: t('common.flash.created', resource: t('activerecord.models.menuitem'))
        end
        format.json do
          render :show, status: :created,
                        location: restaurant_menu_menusection_menuitem_url(@menuitem.menusection.menu.restaurant, @menuitem.menusection.menu, @menuitem.menusection, @menuitem)
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menuitem.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menuitems/1 or /menuitems/1.json
  def update
    authorize @menuitem

    respond_to do |format|
      @menuitem = Menuitem.find(params[:id])
      if @menuitem.update(menuitem_params)
        # Invalidate AdvancedCacheService caches for this menuitem
        AdvancedCacheService.invalidate_menuitem_caches(@menuitem.id)
        AdvancedCacheService.invalidate_menu_caches(@menuitem.menusection.menu.id)
        AdvancedCacheService.invalidate_restaurant_caches(@menuitem.menusection.menu.restaurant.id)

        if @menuitem.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @menuitem.menusection.menu.restaurant
          @genimage.menu = @menuitem.menusection.menu
          @genimage.menusection = @menuitem.menusection
          @genimage.menuitem = @menuitem
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
        if params[:remove_image]
          @menuitem.image = nil
          @menuitem.save
        end
        format.html do
          redirect_to edit_restaurant_menu_path(
            @menuitem.menusection.menu.restaurant,
            @menuitem.menusection.menu,
            section: 'items',
          ), notice: t('common.flash.updated', resource: t('activerecord.models.menuitem'))
        end
        format.json do
          render :show, status: :ok,
                        location: restaurant_menu_menusection_menuitem_url(@menuitem.menusection.menu.restaurant, @menuitem.menusection.menu, @menuitem.menusection, @menuitem)
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menuitem.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menuitems/1 or /menuitems/1.json
  def destroy
    authorize @menuitem

    @menuitem.update(status: :archived, archived: true)

    # Invalidate AdvancedCacheService caches for this menuitem
    AdvancedCacheService.invalidate_menuitem_caches(@menuitem.id)
    AdvancedCacheService.invalidate_menu_caches(@menuitem.menusection.menu.id)
    AdvancedCacheService.invalidate_restaurant_caches(@menuitem.menusection.menu.restaurant.id)

    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_menu_path(
          @menuitem.menusection.menu.restaurant,
          @menuitem.menusection.menu,
          section: 'items',
        ), notice: t('common.flash.updated', resource: t('activerecord.models.menuitem'))
      end
      format.json { head :no_content }
    end
  end

  # PATCH /restaurants/:restaurant_id/menus/:menu_id/menusections/:menusection_id/menuitems/reorder
  def reorder
    @menusection = Menusection.find(params[:menusection_id])
    @menu = @menusection.menu
    @restaurant = @menu.restaurant
    
    # Authorize that user owns this restaurant
    authorize @menu, :update?
    
    # Update sequence for each item within this section
    params[:order].each do |item|
      menuitem = @menusection.menuitems.find(item[:id])
      menuitem.update_column(:sequence, item[:sequence])
    end
    
    render json: { status: 'success' }, status: :ok
  rescue => e
    render json: { status: 'error', message: e.message }, status: :unprocessable_entity
  end

  private

  def ensure_owner_restaurant_context_for_menu!
    return if params[:restaurant_id].blank?

    menu = if defined?(@menuitem) && @menuitem&.menusection&.menu
      @menuitem.menusection.menu
    elsif params[:menusection_id]
      Menusection.find_by(id: params[:menusection_id])&.menu
    elsif params.dig(:menuitem, :menusection_id)
      Menusection.find_by(id: params.dig(:menuitem, :menusection_id))&.menu
    elsif params[:menu_id]
      Menu.find_by(id: params[:menu_id])
    end

    return unless menu

    owner_restaurant_id = menu.owner_restaurant_id.presence || menu.restaurant_id
    return if owner_restaurant_id.blank?
    return if params[:restaurant_id].to_i == owner_restaurant_id

    redirect_to edit_restaurant_path(params[:restaurant_id], section: 'menus'), alert: 'This menu is read-only for this restaurant'
  end

  # Skip policy scope verification for optimized JSON requests
  def skip_policy_scope_for_json?
    request.format.json? && current_user.present?
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_menuitem
    @menuitem = Menuitem.find(params[:id])
  end

  def set_currency
    if params[:id]
      @menuitem = Menuitem.find(params[:id])
      @restaurantCurrency = ISO4217::Currency.from_code(@menuitem.menusection.menu.restaurant.currency || 'USD')
    else
      @restaurantCurrency = ISO4217::Currency.from_code('USD')
    end
  end

  # Only allow a list of trusted parameters through.
  def menuitem_params
    params.require(:menuitem).permit(:name, :description, :itemtype, :sizesupport, :image, :status, :remove_image,
                                     :calories, :sequence, :unitcost, :price, :menusection_id, :preptime,
                                     :tasting_optional, :tasting_supplement_cents, :tasting_supplement_currency, :course_order,
                                     :hidden, :tasting_carrier,
                                     :abv, :alcohol_classification,
                                     allergyn_ids: [], tag_ids: [], size_ids: [], ingredient_ids: [],)
  end
end
