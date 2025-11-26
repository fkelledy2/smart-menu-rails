class SmartmenusController < ApplicationController
  layout 'smartmenu', only: [:show]
  before_action :authenticate_user!, except: %i[index show] # Public menu viewing
  before_action :set_smartmenu, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index show]
  after_action :verify_policy_scoped, only: [:index]

  # GET /smartmenus or /smartmenus.json
  def index
    @smartmenus = if current_user
                    policy_scope(Smartmenu)
                      .includes(:menu, :restaurant, :tablesetting)
                      .joins(:menu)
                      .where(tablesetting_id: nil, menus: { status: 'active' })
                      .limit(100)
                  else
                    Smartmenu
                      .includes(:menu, :restaurant, :tablesetting)
                      .joins(:menu)
                      .where(tablesetting_id: nil, menus: { status: 'active' })
                      .limit(100)
                  end
  end

  # GET /smartmenus/1 or /smartmenus/1.json
  def show
    load_menu_associations_for_show

    if @menu.restaurant != @restaurant
      redirect_to root_url and return
    end

    # Force customer view if query parameter is present
    # Allows staff to preview menu as customers see it
    @force_customer_view = params[:view] == 'customer'

    @allergyns = Allergyn.where(restaurant_id: @menu.restaurant_id)

    if @tablesetting
      @openOrder = Ordr.where(
        menu_id: @menu.id,
        tablesetting_id: @tablesetting.id,
        restaurant_id: @tablesetting.restaurant_id,
        status: [0, 20, 22, 24, 25, 30], # opened, ordered, preparing, ready, delivered, billrequested
      ).first

      if @openOrder
        if current_user
          @ordrparticipant = Ordrparticipant.find_or_create_by(
            ordr: @openOrder,
            employee: @current_employee,
            role: 1,
            sessionid: session.id.to_s,
          )
          Ordraction.create!(ordrparticipant: @ordrparticipant, ordr: @openOrder, action: 1) if @ordrparticipant&.id
        else
          @ordrparticipant = Ordrparticipant.find_or_create_by(
            ordr_id: @openOrder.id,
            role: 0,
            sessionid: session.id.to_s,
          )
          @ordrparticipant.save
          @menuparticipant = Menuparticipant.find_by(sessionid: session.id.to_s)
          if @menuparticipant
            @ordrparticipant.update(preferredlocale: @menuparticipant.preferredlocale)
            @ordrparticipant.save
          end
          Ordraction.create!(ordrparticipant: @ordrparticipant, ordr: @openOrder, action: 0) if @ordrparticipant&.id
        end
      end
    end

    @menuparticipant = Menuparticipant.find_or_create_by(sessionid: session.id.to_s) do |mp|
      mp.smartmenu = @smartmenu
    end
    @menuparticipant.update(smartmenu: @smartmenu) unless @menuparticipant.smartmenu == @smartmenu

    # HTTP caching with ETags for better performance
    # IMPORTANT: Include order context + session in cache key to avoid serving stale pages
    # that drop order context after hard refresh.
    participant_locale = @ordrparticipant&.preferredlocale || @menuparticipant&.preferredlocale

    # Build conservative last_modified including order and items where possible
    order_items_last_modified = nil
    if @openOrder && @openOrder.respond_to?(:ordritems)
      # Safe query for maximum updated_at across order items
      order_items_last_modified = @openOrder.ordritems.maximum(:updated_at)
    end

    last_modified_candidates = [
      @smartmenu&.updated_at,
      @menu&.updated_at,
      @restaurant&.updated_at,
      @tablesetting&.updated_at,
      @ordrparticipant&.updated_at,
      @menuparticipant&.updated_at,
      @openOrder&.updated_at,
      order_items_last_modified,
    ].compact

    etag_parts = [
      @smartmenu,
      @menu,
      @restaurant,
      @tablesetting,
      @openOrder,
      @ordrparticipant,
      participant_locale,
      "sid:#{session.id}",
    ]

    # Enforce private, per-session caching and language variance
    response.headers['Cache-Control'] = 'private, must-revalidate, max-age=0'
    response.headers['Vary'] = [response.headers['Vary'], 'Cookie', 'Accept-Language'].compact.join(', ')

    fresh_when(
      etag: etag_parts,
      last_modified: last_modified_candidates.max,
      public: false,
    )
  end

  # GET /smartmenus/new
  def new
    @smartmenu = Smartmenu.new
  end

  # GET /smartmenus/1/edit
  def edit; end

  # POST /smartmenus or /smartmenus.json
  def create
    @smartmenu = Smartmenu.new(smartmenu_params)

    respond_to do |format|
      if @smartmenu.save
        format.html do
          redirect_to @smartmenu, notice: t('common.flash.created', resource: t('activerecord.models.smartmenu'))
        end
        format.json { render :show, status: :created, location: @smartmenu }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @smartmenu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /smartmenus/1 or /smartmenus/1.json
  def update
    authorize @smartmenu

    respond_to do |format|
      if @smartmenu.update(smartmenu_params)
        format.html do
          redirect_to @smartmenu, notice: t('common.flash.updated', resource: t('activerecord.models.smartmenu'))
        end
        format.json { render :show, status: :ok, location: @smartmenu }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @smartmenu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /smartmenus/1 or /smartmenus/1.json
  def destroy
    authorize @smartmenu

    @smartmenu.destroy!

    respond_to do |format|
      format.html do
        redirect_to smartmenus_path, status: :see_other,
                                     notice: t('common.flash.deleted', resource: t('activerecord.models.smartmenu'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_smartmenu
    @smartmenu = Smartmenu.where(slug: params[:id]).includes(
      :restaurant,
      :tablesetting,
      menu: [restaurant: :user],
    ).first
    if @smartmenu
      @restaurant = @smartmenu.restaurant
      @menu = @smartmenu.menu
      @tablesetting = @smartmenu.tablesetting
      if current_user && (@menu.nil? || (@menu.restaurant.user != current_user))
        redirect_to root_url
      end
      @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency || 'USD')
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  # Load menu associations specifically needed for the show action
  def load_menu_associations_for_show
    return unless @menu

    # Comprehensive eager loading to prevent N+1 queries
    # This loads all associations needed for rendering the smartmenu view
    # Only load active menu items for public-facing smart menu
    @menu = Menu.includes(
      :restaurant,
      :menulocales,
      :menuavailabilities,
      menusections: [
        :menusectionlocales,
        { menuitems: %i[
          menuitemlocales
          allergyns
          ingredients
          sizes
          menuitem_allergyn_mappings
          menuitem_ingredient_mappings
        ] },
      ],
    ).find(@menu.id)

    # Filter to only active menu items after loading
    # This ensures inactive items are not shown in the smart menu
    @menu.menusections.each do |section|
      section.association(:menuitems).target.select!(&:active?)
    end
  end

  # Only allow a list of trusted parameters through.
  def smartmenu_params
    params.require(:smartmenu).permit(:slug, :restaurant_id, :menu_id, :tablesetting_id)
  end
end
