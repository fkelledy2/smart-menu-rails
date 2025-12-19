class MenuitemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_menuitem, only: %i[show edit update destroy analytics generate_ai_image image_status]
  before_action :set_currency

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
          redirect_to edit_restaurant_menu_menusection_menuitem_url(
            @menuitem.menusection.menu.restaurant,
            @menuitem.menusection.menu,
            @menuitem.menusection,
            @menuitem,
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

    @menuitem.update(archived: true)

    # Invalidate AdvancedCacheService caches for this menuitem
    AdvancedCacheService.invalidate_menuitem_caches(@menuitem.id)
    AdvancedCacheService.invalidate_menu_caches(@menuitem.menusection.menu.id)
    AdvancedCacheService.invalidate_restaurant_caches(@menuitem.menusection.menu.restaurant.id)

    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_menu_menusection_path(
          @menuitem.menusection.menu.restaurant,
          @menuitem.menusection.menu,
          @menuitem.menusection,
        ), notice: t('common.flash.deleted', resource: t('activerecord.models.menuitem'))
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
                                     :alcoholic, :abv, :alcohol_classification,
                                     allergyn_ids: [], tag_ids: [], size_ids: [], ingredient_ids: [],)
  end
end
