class SmartmenusController < ApplicationController
  layout 'smartmenu', only: [:show]
  before_action :authenticate_user!, except: %i[index show] # Public menu viewing
  before_action :set_smartmenu, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index show]
  after_action :verify_policy_scoped, only: [:index]

  # GET /smartmenus or /smartmenus.json
  def index
    @smartmenus = policy_scope(Smartmenu)
      .includes(:menu, :restaurant, :tablesetting)
      .joins(:menu)
      .where(tablesetting_id: nil, menus: { status: 'active' })
      .limit(100)
  end

  # GET /smartmenus/1 or /smartmenus/1.json
  def show
    load_menu_associations_for_show

    if @restaurant&.respond_to?(:preview_published?) && @restaurant.preview_published? && @restaurant.unclaimed?
      @meta_robots = @restaurant.preview_indexable? ? 'index, follow' : 'noindex, nofollow'
      response.headers['X-Robots-Tag'] = @meta_robots
    end

    load_active_menu_version

    # Cache-buster for the header/table selector.
    # The header fragment cache key previously ignored newly created Smartmenus/Tablesettings,
    # causing stale table dropdown contents (e.g., missing newly added tables).
    load_header_cache_buster

    unless @menu.restaurant_id == @restaurant.id || RestaurantMenu.exists?(restaurant_id: @restaurant.id, menu_id: @menu.id)
      redirect_to root_url and return
    end

    # Force customer view if query parameter is present
    # Allows staff to preview menu as customers see it
    @force_customer_view = params[:view] == 'customer'

    load_table_smartmenus

    load_restaurant_locales

    load_allergyns

    load_open_order_and_participant

    begin
      @needs_age_check = !(@openOrder && AlcoholOrderEvent.exists?(ordr_id: @openOrder.id, age_check_acknowledged: false)).nil?
    rescue StandardError
      @needs_age_check = false
    end

    @menuparticipant = Menuparticipant.find_or_create_by(sessionid: session.id.to_s) do |mp|
      mp.smartmenu = @smartmenu
    end
    @menuparticipant.update(smartmenu: @smartmenu) unless @menuparticipant.smartmenu == @smartmenu

    if params[:locale].present?
      requested = params[:locale].to_s.downcase
      if I18n.available_locales.map(&:to_s).include?(requested) && (@menuparticipant.preferredlocale.to_s.downcase != requested)
        @menuparticipant.update(preferredlocale: requested)
      end
    end

    # HTTP caching with ETags for better performance (HTML only).
    # IMPORTANT: Include order context + session in cache key to avoid serving stale pages
    # that drop order context after hard refresh.
    # We intentionally skip conditional caching for JSON so the state endpoint always returns
    # a fresh payload (and logs), avoiding 304 for XHRs.
    if request.format.html?
      participant_locale = @ordrparticipant&.preferredlocale || @menuparticipant&.preferredlocale

      # Build conservative last_modified including order and items where possible
      order_items_last_modified = nil
      if @openOrder.respond_to?(:ordritems)
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
          session_id: session.id.to_s,
        )

        if @active_menu_version
          payload[:menuVersion] = {
            id: @active_menu_version.id,
            version_number: @active_menu_version.version_number,
          }
        end
        begin
          items_len = payload.dig(:order, :items)&.length || 0
          item_ids = Array(payload.dig(:order, :items)).filter_map { |i| i[:id] }.take(20)
          Rails.logger.info("[SmartmenusController#show][JSON] order_id=#{payload.dig(:order, :id)} items=#{items_len} ids=#{item_ids.inspect} totals=#{payload[:totals] ? 'present' : 'nil'}")
        rescue StandardError => e
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
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @smartmenu.errors, status: :unprocessable_content }
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
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @smartmenu.errors, status: :unprocessable_content }
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

  def load_active_menu_version
    @active_menu_version = @menu&.active_menu_version
    if @active_menu_version
      MenuVersionApplyService.apply_snapshot!(menu: @menu, menu_version: @active_menu_version)
    end
  rescue StandardError => e
    Rails.logger.warn("[SmartmenusController#show] menu version apply failed: #{e.class}: #{e.message}")
    @active_menu_version = nil
  end

  def load_header_cache_buster
    # Smartmenu and Tablesetting both touch restaurant, so restaurant.updated_at reflects
    # changes that should invalidate the header cache without needing per-request MAX() queries.
    @header_cache_buster = @restaurant&.updated_at
  rescue StandardError => e
    Rails.logger.warn("[SmartmenusController#show] header cache buster error: #{e.class}: #{e.message}")
    @header_cache_buster = nil
  end

  def load_table_smartmenus
    @table_smartmenus = if @restaurant&.id && @menu&.id
                          Smartmenu.includes(:tablesetting)
                            .where(restaurant_id: @restaurant.id, menu_id: @menu.id)
                            .order(:id)
                            .to_a
                        else
                          []
                        end
  rescue StandardError
    @table_smartmenus = []
  end

  def load_restaurant_locales
    # Pre-load restaurantlocales to avoid N+1 queries
    # Force reload to ensure we have fresh data
    @restaurant&.reload
    @active_locales = @restaurant&.restaurantlocales&.select { |rl| rl.status.to_s == 'active' } || []
    @default_locale = @active_locales.find { |rl| rl.dfault == true }
  rescue StandardError
    @active_locales = []
    @default_locale = nil
  end

  def allergyns_debug_enabled?
    params[:debug_allergyns].to_s == 'true'
  end

  def log_allergyns_debug(relation)
    Rails.logger.warn("[SmartmenusController#show] allergyns SQL: #{relation.to_sql}")
  end

  def log_allergyns_result_debug(allergyns)
    Rails.logger.warn(
      "[SmartmenusController#show] allergyns result count=#{allergyns.size} ids=#{allergyns.map(&:id)} names=#{allergyns.map(&:name)}",
    )
  end

  def log_fallback_allergyns_debug(relation)
    Rails.logger.warn("[SmartmenusController#show] allergyns empty for menu; using restaurant fallback SQL: #{relation.to_sql}")
  end

  def log_fallback_allergyns_result_debug(allergyns)
    Rails.logger.warn(
      "[SmartmenusController#show] fallback allergyns count=#{allergyns.size} ids=#{allergyns.map(&:id)} names=#{allergyns.map(&:name)}",
    )
  end

  def load_allergyns
    # Allergens must be those actually used by items in this menu
    # We deduplicate in Ruby since the has_many :through association can cause DISTINCT issues
    allergyns_relation = @menu.allergyns
      .where(archived: false)
      .where(status: :active)
      .order('allergyns.sequence NULLS LAST, allergyns.name')

    log_allergyns_debug(allergyns_relation) if allergyns_debug_enabled?
    @allergyns = allergyns_relation.to_a.uniq(&:id)

    if allergyns_debug_enabled?
      log_allergyns_result_debug(@allergyns)
      @debug_allergyns_info = {
        sql: allergyns_relation.to_sql,
        count: @allergyns.size,
        ids: @allergyns.map(&:id),
        names: @allergyns.map(&:name),
      }
    end

    return unless @allergyns.empty?

    # Fallback to restaurant allergyns (deduplicate in Ruby)
    fallback_relation = @restaurant.allergyns
      .where(archived: false)
      .where(status: :active)
      .order('allergyns.sequence NULLS LAST, allergyns.name')
    log_fallback_allergyns_debug(fallback_relation) if allergyns_debug_enabled?
    @allergyns = fallback_relation.to_a.uniq(&:id)

    return unless allergyns_debug_enabled?

    log_fallback_allergyns_result_debug(@allergyns)
    @debug_allergyns_info ||= {}
    @debug_allergyns_info[:fallback_sql] = fallback_relation.to_sql
    @debug_allergyns_info[:fallback_count] = @allergyns.size
  end

  def eager_load_open_order
    # Eager load ordritems and their menuitems/locales for state JSON and to avoid N+1
    @openOrder = Ordr.includes(
      ordritems: { menuitem: :menuitemlocales },
      ordractions: [:ordrparticipant, { ordritem: { menuitem: :menuitemlocales } }],
    ).find(@openOrder.id)
  rescue StandardError => e
    Rails.logger.warn("[SmartmenusController#show] failed to eager load order #{@openOrder&.id}: #{e.class}: #{e.message}")
  end

  def create_staff_participant_activity
    @ordrparticipant.reload
    @ordrparticipant = Ordrparticipant.includes(:ordrparticipant_allergyn_filters).find(@ordrparticipant.id)
    Ordraction.find_or_create_by!(
      ordrparticipant: @ordrparticipant,
      ordr: @openOrder,
      ordritem: nil,
      action: :openorder,
    )
  rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotFound => e
    Rails.logger.warn("[SmartmenusController#show] skipped ordraction create (staff): #{e.class}: #{e.message}")
  end

  def load_staff_participant
    @ordrparticipant = Ordrparticipant.find_or_create_by!(
      ordr: @openOrder,
      employee: @current_employee,
      role: :staff,
      sessionid: session.id.to_s,
    )

    return unless @ordrparticipant.persisted?

    create_staff_participant_activity
  end

  def maybe_sync_customer_preferred_locale
    @menuparticipant = Menuparticipant.find_by(sessionid: session.id.to_s)
    return unless @menuparticipant
    return if @ordrparticipant.preferredlocale == @menuparticipant.preferredlocale

    @ordrparticipant.update!(preferredlocale: @menuparticipant.preferredlocale)
  end

  def create_customer_participant_activity
    @ordrparticipant.reload
    @ordrparticipant = Ordrparticipant.includes(:ordrparticipant_allergyn_filters).find(@ordrparticipant.id)
    Ordraction.find_or_create_by!(
      ordrparticipant: @ordrparticipant,
      ordr: @openOrder,
      ordritem: nil,
      action: :participate,
    )
  rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotFound => e
    Rails.logger.warn("[SmartmenusController#show] skipped ordraction create (customer): #{e.class}: #{e.message}")
  end

  def load_customer_participant
    @ordrparticipant = Ordrparticipant.find_or_create_by!(
      ordr: @openOrder,
      role: :customer,
      sessionid: session.id.to_s,
    )
    maybe_sync_customer_preferred_locale

    return unless @ordrparticipant.persisted?

    create_customer_participant_activity
  end

  def load_open_order_and_participant
    return unless @tablesetting

    @openOrder = Ordr.where(
      menu_id: @menu.id,
      tablesetting_id: @tablesetting.id,
      restaurant_id: @tablesetting.restaurant_id,
      status: [0, 20, 22, 24, 25, 30], # opened, ordered, preparing, ready, delivered, billrequested
    ).first
    return unless @openOrder

    eager_load_open_order

    Ordrparticipant.on_primary do
      if current_user
        load_staff_participant
      else
        load_customer_participant
      end
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_smartmenu
    @smartmenu = Smartmenu.where(slug: params[:id]).includes(
      :tablesetting,
      restaurant: %i[user restaurantlocales tips alcohol_policy],
      menu: [restaurant: %i[user restaurantlocales tips alcohol_policy]],
    ).first
    if @smartmenu
      @restaurant = @smartmenu.restaurant
      @menu = @smartmenu.menu
      @tablesetting = @smartmenu.tablesetting
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
      { restaurant: %i[restaurantlocales tips alcohol_policy] },
      :menulocales,
      :menuavailabilities,
      menusections: [
        :menusectionlocales,
        { menuitems: [
          :menuitemlocales,
          :allergyns,
          { menuitem_size_mappings: :size },
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
