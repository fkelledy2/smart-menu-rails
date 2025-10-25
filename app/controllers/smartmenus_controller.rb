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
          if @ordrparticipant.id
            Ordraction.create(ordrparticipant: @ordrparticipant, ordr: @openOrder, action: 0)
          end
        end
      end
    end

    @menuparticipant = Menuparticipant.find_or_create_by(sessionid: session.id.to_s) do |mp|
      mp.smartmenu = @smartmenu
    end
    @menuparticipant.update(smartmenu: @smartmenu) unless @menuparticipant.smartmenu == @smartmenu

    # HTTP caching with ETags for better performance
    # Cache is invalidated when menu, restaurant, or participant locale is updated
    # Include participant locale in ETag to ensure cache invalidation on locale switch
    participant_locale = @ordrparticipant&.preferredlocale || @menuparticipant&.preferredlocale
    fresh_when(
      etag: [@smartmenu, @menu, @restaurant, participant_locale],
      last_modified: [
        @smartmenu.updated_at,
        @menu.updated_at,
        @restaurant.updated_at,
        @ordrparticipant&.updated_at,
        @menuparticipant&.updated_at
      ].compact.max,
      public: false # Set to false since it varies by session/participant
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
        { menuitems: [
          :menuitemlocales,
          :allergyns,
          :ingredients,
          :sizes,
          :menuitem_allergyn_mappings,
          :menuitem_ingredient_mappings
        ] }
      ]
    ).find(@menu.id)
    
    # Filter to only active menu items after loading
    # This ensures inactive items are not shown in the smart menu
    @menu.menusections.each do |section|
      section.association(:menuitems).target.select! { |item| item.active? }
    end
  end

  # Only allow a list of trusted parameters through.
  def smartmenu_params
    params.require(:smartmenu).permit(:slug, :restaurant_id, :menu_id, :tablesetting_id)
  end
end
