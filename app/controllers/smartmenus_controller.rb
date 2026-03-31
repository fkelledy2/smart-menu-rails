class SmartmenusController < ApplicationController
  layout 'smartmenu', only: %i[show show_by_token]
  before_action :authenticate_user!, except: %i[index show show_by_token] # Public menu viewing
  before_action :set_smartmenu, only: %i[show edit update destroy]
  before_action :set_smartmenu_by_token, only: %i[show_by_token]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index show show_by_token]
  after_action :verify_policy_scoped, only: [:index]

  # GET /smartmenus/:id/preview?theme_preview=elegant
  # Opens a preview of the smartmenu public URL — no server-side rendering needed.
  # Redirects to the public token URL; theme is applied client-side via data-theme
  # once the theme is saved. This action exists as a convenience redirect.
  def preview
    sm = Smartmenu.find_by!(slug: params[:id])
    authorize sm, :show?
    redirect_to table_link_url(public_token: sm.public_token), allow_other_host: false
  end

  # GET /smartmenus or /smartmenus.json
  def index
    @smartmenus = policy_scope(Smartmenu)
      .includes(:menu, :restaurant, :tablesetting)
      .joins(:menu)
      .where(tablesetting_id: nil, menus: { status: 'active' })
      .limit(100)
  end

  # GET /smartmenus/1 — legacy slug route, permanently redirected to token URL
  def show
    return redirect_to(root_url, status: :moved_permanently) if @smartmenu&.public_token.blank?

    redirect_to table_link_path(@smartmenu.public_token, request.query_parameters), status: :moved_permanently
  end

  # GET /t/:public_token — QR code entry point
  # Creates or refreshes a DiningSession and renders the smartmenu show view.
  # Returns 404 for invalid tokens (not 403, to avoid confirming token existence).
  def show_by_token
    create_or_refresh_dining_session!
    # Delegate to the same rendering pipeline as show
    call_show_pipeline
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
        format.turbo_stream do
          flash.now[:notice] = t('common.flash.updated', resource: t('activerecord.models.smartmenu'))
          render turbo_stream: turbo_stream.prepend('flash_toasts', partial: 'shared/notices')
        end
        format.html do
          redirect_back_or_to @smartmenu, notice: t('common.flash.updated', resource: t('activerecord.models.smartmenu'))
        end
        format.json { render :show, status: :ok, location: @smartmenu }
      else
        format.turbo_stream do
          flash.now[:alert] = @smartmenu.errors.full_messages.to_sentence
          render turbo_stream: turbo_stream.prepend('flash_toasts', partial: 'shared/notices')
        end
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
    # Check for an active A/B experiment first (only if flag is enabled and we have a dining session)
    if @menu && @dining_session && Flipper.enabled?(:menu_experiments, @restaurant)
      resolve_experiment_version
    end

    # Fall through to standard active version if no experiment was assigned
    unless @active_menu_version
      @active_menu_version = @menu&.active_menu_version
      if @active_menu_version
        MenuVersionApplyService.apply_snapshot!(menu: @menu, menu_version: @active_menu_version)
      end
    end
  rescue StandardError => e
    Rails.logger.warn("[SmartmenusController#show] menu version apply failed: #{e.class}: #{e.message}")
    @active_menu_version = nil
  end

  # Resolve experiment assignment for this dining session.
  # Assigns the session to control or variant, persists the assignment, and
  # enqueues exposure logging. Uses snapshot_json directly — does NOT call
  # MenuVersionApplyService (which is for rollback preview flows only).
  def resolve_experiment_version
    active_experiment = MenuExperiment.active_for_menu(@menu)
    return unless active_experiment

    version = if @dining_session.menu_experiment_id == active_experiment.id && @dining_session.assigned_version
                # Re-use the existing assignment — session consistency guarantee
                @dining_session.assigned_version
              else
                # First visit under this experiment — compute and persist assignment
                assigned = MenuExperiments::VersionAssignmentService.assign(
                  dining_session: @dining_session,
                  menu_experiment: active_experiment,
                )
                @dining_session.update_columns(
                  menu_experiment_id: active_experiment.id,
                  assigned_version_id: assigned.id,
                )
                assigned
              end

    MenuExperiments::ExposureLogger.log(@dining_session, active_experiment, version)

    # Read snapshot directly — do NOT call apply_snapshot! in the render path
    @active_menu_version = version
    @menu_experiment = active_experiment
  rescue StandardError => e
    Rails.logger.warn("[SmartmenusController#resolve_experiment_version] #{e.class}: #{e.message}")
    @active_menu_version = nil
    @menu_experiment = nil
  end

  def load_header_cache_buster
    # Smartmenu and Tablesetting both touch restaurant, so restaurant.updated_at reflects
    # changes that should invalidate the header cache without needing per-request MAX() queries.
    @header_cache_buster = @restaurant&.updated_at
  rescue StandardError => e
    Rails.logger.warn("[SmartmenusController#show] header cache buster error: #{e.class}: #{e.message}")
    @header_cache_buster = nil
  end

  # For table smartmenus the theme is inherited from the primary (non-table)
  # smartmenu for the same restaurant+menu, so that updating the theme on the
  # main smartmenu propagates to all tables without needing per-table updates.
  def set_effective_theme
    if @smartmenu.tablesetting_id.present?
      primary = @table_smartmenus.find { |sm| sm.tablesetting_id.nil? }
      @effective_theme = primary&.theme || @smartmenu.theme
    else
      @effective_theme = @smartmenu.theme
    end
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
  rescue StandardError => e
    Rails.logger.warn("[SmartmenusController#load_table_smartmenus] failed to load table smartmenus: #{e.message}")
    @table_smartmenus = []
  end

  def load_restaurant_locales
    # Restaurantlocales are already eager-loaded via set_smartmenu includes.
    # No reload needed — avoids 3-5 extra queries per request.
    @active_locales = @restaurant&.restaurantlocales&.select { |rl| rl.status.to_s == 'active' } || []
    @default_locale = @active_locales.find { |rl| rl.dfault == true }
  rescue StandardError => e
    Rails.logger.warn("[SmartmenusController#load_restaurant_locales] failed to load restaurant locales: #{e.message}")
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
    # Use a subquery to deduplicate allergyns at the SQL level.
    # The has_many :through chain (menu → menuitems → mappings → allergyns) produces
    # duplicate rows when the same allergyn appears on multiple items. Wrapping the
    # join in a subquery (SELECT id FROM ...) and querying Allergyn directly avoids
    # duplicates without needing Ruby-level dedup or problematic SQL DISTINCT on joins.
    allergyn_ids_subquery = @menu.allergyns.select('allergyns.id')
    allergyns_relation = Allergyn.where(id: allergyn_ids_subquery, archived: false, status: :active)
      .order('sequence NULLS LAST, name')

    log_allergyns_debug(allergyns_relation) if allergyns_debug_enabled?
    @allergyns = allergyns_relation.to_a

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

    # Fallback to restaurant allergyns via same subquery pattern
    fallback_ids_subquery = @restaurant.allergyns.select('allergyns.id')
    fallback_relation = Allergyn.where(id: fallback_ids_subquery, archived: false, status: :active)
      .order('sequence NULLS LAST, name')
    log_fallback_allergyns_debug(fallback_relation) if allergyns_debug_enabled?
    @allergyns = fallback_relation.to_a

    return unless allergyns_debug_enabled?

    log_fallback_allergyns_result_debug(@allergyns)
    @debug_allergyns_info ||= {}
    @debug_allergyns_info[:fallback_sql] = fallback_relation.to_sql
    @debug_allergyns_info[:fallback_count] = @allergyns.size
  end

  def eager_load_open_order
    # Eager load ordritems and their menuitems/locales for state JSON and to avoid N+1
    @openOrder = Ordr.includes(
      ordritems: [:ordritemnotes, { menuitem: :menuitemlocales }],
      ordractions: [:ordrparticipant, { ordritem: [:ordritemnotes, { menuitem: :menuitemlocales }] }],
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
      sessionid: safe_session_id,
    )

    return unless @ordrparticipant.persisted?

    create_staff_participant_activity
  end

  def maybe_sync_customer_preferred_locale
    @menuparticipant = Menuparticipant.find_by(sessionid: safe_session_id, smartmenu_id: @smartmenu.id)
    return unless @menuparticipant

    # Compare case-insensitively and sync if menuparticipant has a locale set
    menu_locale = @menuparticipant.preferredlocale&.downcase
    return if menu_locale.blank? || @ordrparticipant.preferredlocale&.downcase == menu_locale

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
      sessionid: safe_session_id,
    )
    maybe_sync_customer_preferred_locale

    return unless @ordrparticipant.persisted?

    create_customer_participant_activity
  end

  def load_open_order_and_participant
    return unless @tablesetting

    # Ensure a stable session identifier exists.
    # Rails cookie store may return nil for session.id until after the response,
    # so we maintain our own UUID in the session for reliable lookups.
    session[:sid] ||= SecureRandom.uuid

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

  # SEO: Build Schema.org JSON-LD and dynamic meta tags for public smartmenu pages
  def set_seo_metadata
    return unless @restaurant && @menu && @smartmenu

    # Schema.org JSON-LD — cached per menu+restaurant update pair to avoid repeated
    # eager loads and serialization on every request.
    schema_cache_key = "schema_org/v1/smartmenu/#{@smartmenu.id}/menu/#{@menu.id}/#{@menu.updated_at.to_i}-#{@restaurant.updated_at.to_i}"
    @schema_org_json_ld = Rails.cache.fetch(schema_cache_key, expires_in: 1.hour) do
      menusections = Menusection.where(menu_id: @menu.id, archived: false)
        .includes(menuitems: :allergyns)
        .order(:sequence)
      SchemaOrgSerializer.new(
        restaurant: @restaurant,
        menu: @menu,
        menusections: menusections,
        smartmenu: @smartmenu,
      ).to_json_ld
    end

    # Dynamic meta tags
    @page_title = "#{@restaurant.name} — Menu | mellow.menu"
    @page_description = "View the menu for #{@restaurant.name}" +
                        (@restaurant.city.present? ? " in #{@restaurant.city}" : '') +
                        '. Prices, allergens, and descriptions.'
    @og_title = @page_title
    @og_description = @page_description
    @og_url = "https://mellow.menu/t/#{@smartmenu.public_token}"
    @og_image = @restaurant.try(:image_url) || 'https://mellow.menu/images/featured-dish.jpg'
    @canonical_url = @og_url
    @geo_lat = @restaurant.latitude
    @geo_lng = @restaurant.longitude
    @geo_city = @restaurant.city
  rescue StandardError => e
    Rails.logger.warn("[SmartmenusController#set_seo_metadata] #{e.class}: #{e.message}")
  end

  # Set smartmenu via public_token for the /t/:public_token route.
  # Returns 404 for missing/invalid tokens.
  def set_smartmenu_by_token
    @smartmenu = Smartmenu.where(public_token: params[:public_token]).includes(
      :tablesetting,
      restaurant: %i[restaurantlocales tips alcohol_policy],
      menu: [
        { restaurant: %i[restaurantlocales tips alcohol_policy] },
        :menulocales,
        :menu_versions,
        { menusections: [
          :menusectionlocales,
          { menuitems: [
            :menuitemlocales,
            :allergyns,
            { menuitem_size_mappings: :size },
          ] },
        ] },
      ],
    ).first

    if @smartmenu
      @restaurant = @smartmenu.restaurant
      @menu = @smartmenu.menu
      @tablesetting = @smartmenu.tablesetting
      @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency || 'USD')
    else
      head :not_found
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def create_or_refresh_dining_session!
    return unless @smartmenu && @tablesetting

    existing_token = session[:dining_session_token]
    dining_session = nil

    if existing_token.present?
      dining_session = DiningSession.find_by(
        session_token: existing_token,
        smartmenu_id: @smartmenu.id,
        active: true,
      )
      dining_session&.touch_activity! unless dining_session&.expired?
      dining_session = nil if dining_session&.expired?
    end

    unless dining_session
      ua_hash = Digest::SHA256.hexdigest(request.user_agent.to_s)[0, 64]
      dining_session = DiningSession.create!(
        smartmenu: @smartmenu,
        tablesetting: @tablesetting,
        restaurant: @restaurant,
        session_token: SecureRandom.hex(32),
        ip_address: request.remote_ip,
        user_agent_hash: ua_hash,
      )
      session[:dining_session_token] = dining_session.session_token
    end

    @dining_session = dining_session
  rescue StandardError => e
    Rails.logger.warn("[SmartmenusController#create_or_refresh_dining_session!] #{e.class}: #{e.message}")
    @dining_session = nil
  end

  # Shared rendering pipeline used by both show and show_by_token.
  # Extracted so token-based entry doesn't duplicate the full show body.
  def call_show_pipeline
    load_menu_associations_for_show
    set_seo_metadata

    if @restaurant.respond_to?(:preview_published?) && @restaurant.preview_published? && @restaurant.unclaimed?
      @meta_robots = @restaurant.preview_indexable? ? 'index, follow' : 'noindex, nofollow'
      response.headers['X-Robots-Tag'] = @meta_robots
    end

    load_active_menu_version
    load_header_cache_buster

    unless @menu && (@menu.restaurant_id == @restaurant.id || RestaurantMenu.exists?(restaurant_id: @restaurant.id, menu_id: @menu.id))
      redirect_to root_url and return
    end

    # Mode is determined by a signed preview token generated on the menu edit page.
    # Without a valid token the page is always customer view — no toggle, no params.
    preview = SmartmenuPreviewToken.decode(params[:preview])
    @staff_view_mode = preview.present? && preview[:mode] == 'staff'
    @preview_edit_path = @staff_view_mode ? edit_restaurant_menu_path(@restaurant, @menu) : nil

    load_table_smartmenus
    set_effective_theme
    load_restaurant_locales
    load_allergyns
    load_open_order_and_participant

    begin
      @needs_age_check = @openOrder.present? && AlcoholOrderEvent.exists?(ordr_id: @openOrder.id, age_check_acknowledged: false)
    rescue StandardError => e
      Rails.logger.warn("[SmartmenusController#show] age check lookup failed: #{e.message}")
      @needs_age_check = false
    end

    @menuparticipant = Menuparticipant.find_or_create_by(sessionid: safe_session_id) do |mp|
      mp.smartmenu = @smartmenu
    end
    if @menuparticipant.persisted? && @menuparticipant.smartmenu_id != @smartmenu.id
      @menuparticipant.update_column(:smartmenu_id, @smartmenu.id)
    end

    if params[:locale].present?
      requested = params[:locale].to_s.downcase
      if I18n.available_locales.map(&:to_s).include?(requested) && (@menuparticipant.preferredlocale.to_s.downcase != requested)
        @menuparticipant.update(preferredlocale: requested)
      end
    end

    if request.format.html?
      participant_locale = @ordrparticipant&.preferredlocale || @menuparticipant&.preferredlocale
      order_items_last_modified = nil
      if @openOrder.respond_to?(:ordritems)
        order_items_last_modified = @openOrder.ordritems.maximum(:updated_at)
      end

      last_modified_candidates = [
        @smartmenu&.updated_at, @menu&.updated_at, @restaurant&.updated_at,
        @tablesetting&.updated_at, @ordrparticipant&.updated_at,
        @menuparticipant&.updated_at, @openOrder&.updated_at, order_items_last_modified,
      ].compact

      etag_parts = [
        @smartmenu, @menu, @restaurant, @tablesetting, @openOrder, @ordrparticipant,
        participant_locale, "sid:#{session.id}", "build:#{BUILD_VERSION}",
        @staff_view_mode ? 'staff' : 'customer',
      ]

      has_order_context = @openOrder.present? || @ordrparticipant.present?
      if has_order_context
        response.headers['Cache-Control'] = 'private, must-revalidate, max-age=0'
        response.headers['Vary'] = [response.headers['Vary'], 'Cookie', 'Accept-Language'].compact.join(', ')
      else
        # no-cache means the browser always validates with the ETag (conditional GET).
        # This ensures theme/menu changes are immediately visible without stale content windows.
        # Performance is preserved: ETag match returns 304 with no body transfer.
        response.headers['Cache-Control'] = 'public, no-cache'
        response.headers['Vary'] = [response.headers['Vary'], 'Accept-Language'].compact.join(', ')
      end

      return unless stale?(etag: etag_parts, last_modified: last_modified_candidates.max, public: !has_order_context)
    end

    respond_to do |format|
      format.html { render :show }
      format.json do
        payload = SmartmenuState.for_context(
          menu: @menu,
          restaurant: @restaurant,
          tablesetting: @tablesetting,
          open_order: @openOrder,
          ordrparticipant: @ordrparticipant,
          menuparticipant: @menuparticipant,
          session_id: safe_session_id,
        )
        if @active_menu_version
          payload[:menuVersion] = { id: @active_menu_version.id, version_number: @active_menu_version.version_number }
        end
        render json: payload
      end
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_smartmenu
    @smartmenu = Smartmenu.where(slug: params[:id]).includes(
      :tablesetting,
      restaurant: %i[restaurantlocales tips alcohol_policy],
      menu: [
        { restaurant: %i[restaurantlocales tips alcohol_policy] },
        :menulocales,
        :menu_versions,
        { menusections: [
          :menusectionlocales,
          { menuitems: [
            :menuitemlocales,
            :allergyns,
            { menuitem_size_mappings: :size },
          ] },
        ] },
      ],
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
  # NOTE: Associations are now eager-loaded in set_smartmenu. This method
  # only filters to active items without issuing additional queries.
  def load_menu_associations_for_show
    return unless @menu

    # Filter to only active menu items after loading
    # This ensures inactive items are not shown in the smart menu
    @menu.menusections.each do |section|
      section.association(:menuitems).target.select!(&:active?)
    end
  end

  # Stable session identifier — Rails cookie store may return nil for session.id
  # until after the first response, so fall back to a UUID stored in session[:sid].
  def safe_session_id
    sid = session.id.to_s.presence || (session[:sid] ||= SecureRandom.uuid)
    sid.to_s
  end

  # Only allow a list of trusted parameters through.
  def smartmenu_params
    params.require(:smartmenu).permit(:slug, :restaurant_id, :menu_id, :tablesetting_id, :theme)
  end
end
