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

    # Cache-buster for the header/table selector.
    # The header fragment cache key previously ignored newly created Smartmenus/Tablesettings,
    # causing stale table dropdown contents (e.g., missing newly added tables).
    begin
      latest_smartmenu_update = Smartmenu.where(
        restaurant_id: @restaurant&.id,
        menu_id: @menu&.id,
      ).maximum(:updated_at)

      latest_tablesetting_update = Tablesetting.where(
        restaurant_id: @restaurant&.id,
      ).maximum(:updated_at)

      @header_cache_buster = [latest_smartmenu_update, latest_tablesetting_update].compact.max
    rescue => e
      Rails.logger.warn("[SmartmenusController#show] header cache buster error: #{e.class}: #{e.message}")
      @header_cache_buster = nil
    end

    if @menu.restaurant != @restaurant
      redirect_to root_url and return
    end

    # Force customer view if query parameter is present
    # Allows staff to preview menu as customers see it
    @force_customer_view = params[:view] == 'customer'

    # Allergens must be those actually used by items in this menu
    allergyns_relation = @menu.allergyns
                              .where(archived: false)
                              .where(status: :active)
                              .order(Arel.sql('allergyns.sequence NULLS LAST, allergyns.name'))

    Rails.logger.warn("[SmartmenusController#show] allergyns SQL: #{allergyns_relation.to_sql}")
    @allergyns = allergyns_relation.to_a
    Rails.logger.warn(
      "[SmartmenusController#show] allergyns result count=#{@allergyns.size} ids=#{@allergyns.map(&:id)} names=#{@allergyns.map(&:name)}"
    )

    @debug_allergyns_info = {
      sql: allergyns_relation.to_sql,
      count: @allergyns.size,
      ids: @allergyns.map(&:id),
      names: @allergyns.map(&:name),
    }

    if @allergyns.empty?
      fallback_relation = @restaurant.allergyns
                                     .where(archived: false)
                                     .where(status: :active)
                                     .order(Arel.sql('allergyns.sequence NULLS LAST, allergyns.name'))
      Rails.logger.warn("[SmartmenusController#show] allergyns empty for menu; using restaurant fallback SQL: #{fallback_relation.to_sql}")
      @allergyns = fallback_relation.to_a
      Rails.logger.warn(
        "[SmartmenusController#show] fallback allergyns count=#{@allergyns.size} ids=#{@allergyns.map(&:id)} names=#{@allergyns.map(&:name)}"
      )
      @debug_allergyns_info[:fallback_sql] = fallback_relation.to_sql
      @debug_allergyns_info[:fallback_count] = @allergyns.size
    end

    if @tablesetting
      @openOrder = Ordr.where(
        menu_id: @menu.id,
        tablesetting_id: @tablesetting.id,
        restaurant_id: @tablesetting.restaurant_id,
        status: [0, 20, 22, 24, 25, 30], # opened, ordered, preparing, ready, delivered, billrequested
      ).first

      if @openOrder
        # Eager load ordritems and their menuitems/locales for state JSON and to avoid N+1
        begin
          @openOrder = Ordr.includes(
            ordritems: { menuitem: :menuitemlocales },
            ordractions: [:ordrparticipant, { ordritem: { menuitem: :menuitemlocales } }]
          ).find(@openOrder.id)
        rescue => e
          Rails.logger.warn("[SmartmenusController#show] failed to eager load order #{ @openOrder&.id }: #{e.class}: #{e.message}")
        end
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

    # HTTP caching with ETags for better performance (HTML only).
    # IMPORTANT: Include order context + session in cache key to avoid serving stale pages
    # that drop order context after hard refresh.
    # We intentionally skip conditional caching for JSON so the state endpoint always returns
    # a fresh payload (and logs), avoiding 304 for XHRs.
    if request.format.html?
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
    
    respond_to do |format|
      format.html
      format.json do
        payload = SmartmenuState.for_context(
          menu: @menu,
          restaurant: @restaurant,
          tablesetting: @tablesetting,
          open_order: @openOrder,
          ordrparticipant: @ordrparticipant,
          menuparticipant: @menuparticipant,
          session_id: session.id.to_s
        )
        begin
          items_len = payload.dig(:order, :items)&.length || 0
          item_ids = Array(payload.dig(:order, :items)).map { |i| i[:id] }.compact.take(20)
          Rails.logger.info("[SmartmenusController#show][JSON] order_id=#{payload.dig(:order, :id)} items=#{items_len} ids=#{item_ids.inspect} totals=#{payload[:totals] ? 'present' : 'nil'}")
        rescue => e
          Rails.logger.warn("[SmartmenusController#show][JSON] logging failed: #{e.class}: #{e.message}")
        end
        render json: payload
      end
    end
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
