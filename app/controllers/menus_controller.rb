require 'rqrcode'

class MenusController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  skip_before_action :verify_authenticity_token, only: %i[create_version activate_version]
  before_action :set_restaurant
  before_action :set_menu, only: %i[show edit update destroy regenerate_images image_generation_progress localize localization_progress performance update_availabilities polish polish_progress versions version_diff versions_diff create_version activate_version]
  before_action :ensure_owner_restaurant_context!, only: %i[update destroy regenerate_images localize update_availabilities polish create_version activate_version]

  skip_around_action :switch_locale, only: %i[update_sequence bulk_update]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index performance update_sequence bulk_update]
  after_action :verify_policy_scoped, only: [:index], unless: :skip_policy_scope?

  # GET	/restaurants/:restaurant_id/menus
  # GET /menus or /menus.json
  def index
    @today = Time.zone.today.strftime('%A').downcase!
    @currentHour = Time.now.strftime('%H').to_i
    @currentMin = Time.now.strftime('%M').to_i

    if current_user
      # Optimize query based on request format and restaurant scope
      @menus = if @restaurant
                 base = policy_scope(Menu)
                   .distinct(false)
                   .joins(:restaurant_menus)
                   .where(restaurant_menus: { restaurant_id: @restaurant.id })
                   .for_management_display
                   .where(archived: false)
                   .order(Arel.sql('CASE WHEN restaurant_menus.sequence IS NULL THEN 1 ELSE 0 END, restaurant_menus.sequence ASC'))

                 if request.format.json?
                   base.includes(menusections: :menuitems, menuavailabilities: [])
                 else
                   base
                 end
               else
                 # For all-menus requests, use policy scope
                 policy_scope(Menu).for_management_display.order(:sequence)
               end

      # Skip analytics for JSON requests to improve performance
      unless request.format.json?
        AnalyticsService.track_user_event(current_user, 'menus_viewed', {
          menus_count: @menus.size, # Use size instead of count (uses loaded records)
          restaurant_id: @restaurant&.id,
          viewing_context: params[:restaurant_id] ? 'restaurant_specific' : 'all_menus',
        })
      end
    elsif params[:restaurant_id]
      @restaurant = Restaurant.find_by(id: params[:restaurant_id])
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

    # Use minimal JSON view for better performance
    respond_to do |format|
      format.html # Default HTML view
      format.json { render 'index_minimal' } # Use optimized minimal JSON view
    end
  end

  # GET /restaurants/:restaurant_id/menus/:id/versions
  def versions
    authorize @menu, :update?

    versions = @menu.menu_versions.order(version_number: :desc)
    active = @menu.active_menu_version

    render json: {
      menu_id: @menu.id,
      active_menu_version_id: active&.id,
      count: versions.size,
      versions: versions.map do |v|
        {
          id: v.id,
          version_number: v.version_number,
          is_active: v.is_active,
          starts_at: v.starts_at,
          ends_at: v.ends_at,
          created_by_user_id: v.created_by_user_id,
          created_at: v.created_at,
        }
      end,
    }
  end

  # GET /restaurants/:restaurant_id/menus/:id/versions/:from_version_id/diff/:to_version_id
  def version_diff
    authorize @menu, :update?

    from_version = @menu.menu_versions.find(params[:from_version_id])
    to_version = @menu.menu_versions.find(params[:to_version_id])

    diff = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    render json: {
      menu_id: @menu.id,
      from_version_id: from_version.id,
      to_version_id: to_version.id,
      diff: diff,
    }
  end

  # GET /restaurants/:restaurant_id/menus/:id/versions/diff
  def versions_diff
    authorize @menu, :update?

    from_version = @menu.menu_versions.find(params[:from_version_id])
    to_version = @menu.menu_versions.find(params[:to_version_id])
    diff = MenuVersionDiffService.diff(from_version: from_version, to_version: to_version)

    respond_to do |format|
      format.json do
        render json: {
          menu_id: @menu.id,
          from_version_id: from_version.id,
          to_version_id: to_version.id,
          diff: diff,
        }
      end
      format.html do
        if turbo_frame_request_id == 'menu_versions_diff'
          render partial: 'menus/sections/version_diff_2025',
                 locals: {
                   menu: @menu,
                   restaurant: @restaurant || @menu.restaurant,
                   from_version: from_version,
                   to_version: to_version,
                   diff: diff,
                 }
        else
          redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu, section: 'versions')
        end
      end
    end
  end

  # POST /restaurants/:restaurant_id/menus/:id/create_version
  def create_version
    authorize @menu, :update?

    menu_version = MenuVersion.create_from_menu!(menu: @menu, user: current_user)

    respond_to do |format|
      format.json do
        render json: {
          menu_id: @menu.id,
          menu_version: {
            id: menu_version.id,
            version_number: menu_version.version_number,
            is_active: menu_version.is_active,
            starts_at: menu_version.starts_at,
            ends_at: menu_version.ends_at,
            created_at: menu_version.created_at,
          },
        }
      end
      format.html do
        redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu, section: 'versions'),
                    status: :see_other
      end
    end
  end

  # POST /restaurants/:restaurant_id/menus/:id/activate_version
  def activate_version
    authorize @menu, :update?

    menu_version = @menu.menu_versions.find(params[:menu_version_id])

    context_restaurant = @restaurant || @menu.owner_restaurant || @menu.restaurant
    zone_name = begin
      context_restaurant.respond_to?(:timezone) ? context_restaurant.timezone.to_s.presence : nil
    rescue StandardError
      nil
    end
    zone_name ||= Time.zone.name

    parse_in_zone = lambda do |raw|
      s = raw.to_s
      next nil if s.blank?

      Time.use_zone(zone_name) do
        if s.end_with?('Z') || s.match?(/[+-]\d\d:\d\d\z/)
          Time.iso8601(s)
        else
          Time.zone.parse(s)
        end
      rescue ArgumentError
        begin
          Time.zone.parse(s)
        rescue StandardError
          nil
        end
      end
    end

    starts_at = parse_in_zone.call(params[:starts_at])
    ends_at = parse_in_zone.call(params[:ends_at])

    MenuVersionActivationService.activate!(menu_version: menu_version, starts_at: starts_at, ends_at: ends_at)

    respond_to do |format|
      format.json do
        render json: {
          menu_id: @menu.id,
          active_menu_version_id: @menu.active_menu_version&.id,
          activated_menu_version_id: menu_version.id,
          menu_version: {
            id: menu_version.id,
            version_number: menu_version.version_number,
            is_active: menu_version.is_active,
            starts_at: menu_version.starts_at,
            ends_at: menu_version.ends_at,
          },
        }
      end
      format.html do
        redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu, section: 'versions'),
                    status: :see_other
      end
    end
  end

  # POST /restaurants/:restaurant_id/menus/:id/attach
  def attach
    menu = Menu.find(params[:id])
    restaurant_menu = RestaurantMenu.new(restaurant: @restaurant, menu: menu)
    authorize restaurant_menu, :attach?

    restaurant_menu.sequence ||= (@restaurant.restaurant_menus.maximum(:sequence).to_i + 1)
    restaurant_menu.status ||= :active
    restaurant_menu.availability_override_enabled = false if restaurant_menu.availability_override_enabled.nil?
    restaurant_menu.availability_state ||= :available
    restaurant_menu.save!

    ensure_smartmenus_for_restaurant_menu!(@restaurant, menu)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/menus_2025',
          locals: { restaurant: @restaurant, filter: 'all' },
        )
      end
      format.html do
        redirect_to edit_restaurant_path(@restaurant, section: 'menus')
      end
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Unable to attach menu'
  end

  # POST /restaurants/:restaurant_id/menus/:id/share
  def share
    menu = Menu.find(params[:id])
    authorize RestaurantMenu.new(restaurant: @restaurant, menu: menu), :attach?

    owner_restaurant_id = menu.owner_restaurant_id.presence || menu.restaurant_id
    unless owner_restaurant_id == @restaurant.id
      return redirect_to(edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Only the owner restaurant can share this menu')
    end

    Restaurant.where(user_id: current_user.id).where.not(id: @restaurant.id)

    raw_target_ids = []
    raw_target_ids.concat(Array(params[:target_restaurant_ids])) if params.key?(:target_restaurant_ids)
    raw_target_ids << params[:target_restaurant_id] if params.key?(:target_restaurant_id)
    raw_target_ids = raw_target_ids.map(&:to_s).map(&:strip).compact_blank

    other_restaurant_ids = Restaurant.on_primary do
      Restaurant.where(user_id: current_user.id).where.not(id: @restaurant.id).pluck(:id)
    end

    target_ids = if raw_target_ids.include?('all')
                   other_restaurant_ids
                 else
                   raw_target_ids.map(&:to_i).reject(&:zero?)
                 end

    target_restaurants = Restaurant.on_primary do
      Restaurant.where(user_id: current_user.id).where(id: target_ids).to_a
    end

    if target_restaurants.empty?
      return redirect_to(edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Restaurant not found')
    end

    target_restaurants.each do |target_restaurant|
      restaurant_menu = RestaurantMenu.find_or_initialize_by(restaurant: target_restaurant, menu: menu)
      authorize restaurant_menu, :attach?

      next if restaurant_menu.persisted?

      restaurant_menu.sequence ||= (target_restaurant.restaurant_menus.maximum(:sequence).to_i + 1)
      restaurant_menu.status ||= :active
      restaurant_menu.availability_override_enabled = false if restaurant_menu.availability_override_enabled.nil?
      restaurant_menu.availability_state ||= :available
      restaurant_menu.save!

      ensure_smartmenus_for_restaurant_menu!(target_restaurant, menu)
    end

    redirect_to edit_restaurant_path(@restaurant, section: 'menus')
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Restaurant not found'
  rescue ActiveRecord::RecordInvalid
    redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Unable to share menu'
  end

  def ensure_smartmenus_for_restaurant_menu!(restaurant, menu)
    Smartmenu.on_primary do
      if Smartmenu.where(restaurant_id: restaurant.id, menu_id: menu.id, tablesetting_id: nil).first.nil?
        Smartmenu.create!(restaurant: restaurant, menu: menu, tablesetting: nil, slug: SecureRandom.uuid)
      end

      restaurant.tablesettings.order(:id).each do |tablesetting|
        next unless Smartmenu.where(restaurant_id: restaurant.id, menu_id: menu.id, tablesetting_id: tablesetting.id).first.nil?

        Smartmenu.create!(restaurant: restaurant, menu: menu, tablesetting: tablesetting, slug: SecureRandom.uuid)
      end
    end
  end

  # DELETE /restaurants/:restaurant_id/menus/:id/detach
  def detach
    menu = Menu.find(params[:id])

    authorize RestaurantMenu.new(restaurant: @restaurant, menu: menu), :detach?

    owner_restaurant_id = menu.owner_restaurant_id.presence || menu.restaurant_id
    if owner_restaurant_id.present? && owner_restaurant_id == @restaurant.id
      return redirect_to(edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Owner restaurant cannot detach its own menu')
    end

    restaurant_menu = RestaurantMenu.find_by!(restaurant_id: @restaurant.id, menu_id: menu.id)
    authorize restaurant_menu, :detach?

    restaurant_menu.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/menus_2025',
          locals: { restaurant: @restaurant, filter: 'all' },
        )
      end
      format.html do
        redirect_to edit_restaurant_path(@restaurant, section: 'menus')
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Menu not attached'
  end

  # POST /menus/:id/regenerate_images
  def regenerate_images
    authorize @menu, :update?

    if @menu.nil?
      redirect_to root_url and return
    end

    # Check if user wants to generate AI images or regenerate WebP derivatives
    if params[:generate_ai] == 'true'
      # Generate new AI images using DALL-E
      total = Genimage.where(menu_id: @menu.id).count
      jid = MenuItemImageBatchJob.perform_async(@menu.id)

      # Initialize progress in Redis via Sidekiq connection
      begin
        Sidekiq.redis do |r|
          r.setex("image_gen:#{jid}", 24 * 3600, {
            status: 'queued',
            current: 0,
            total: total,
            message: 'Queued AI image generation',
            menu_id: @menu.id,
          }.to_json,)
        end
      rescue StandardError => e
        Rails.logger.warn("[MenusController] Failed to init progress for #{jid}: #{e.message}")
      end

      respond_to do |format|
        format.html do
          flash[:notice] = t('menus.controller.ai_image_generation_queued')
          redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu)
        end
        format.json do
          render json: { job_id: jid, total: total, status: 'queued' }
        end
      end
      return
    else
      # Regenerate WebP derivatives for existing images
      RegenerateMenuWebpJob.perform_async(@menu.id)
      flash[:notice] = t('menus.controller.webp_regeneration_queued')
    end

    redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu)
  end

  # GET /restaurants/:restaurant_id/menus/:id/image_generation_progress
  def image_generation_progress
    authorize @menu, :update?

    jid = params[:job_id].to_s
    payload = nil
    begin
      Sidekiq.redis do |r|
        json = r.get("image_gen:#{jid}")
        payload = json.present? ? JSON.parse(json) : {}
      end
    rescue StandardError => e
      Rails.logger.warn("[MenusController] Progress read failed for #{jid}: #{e.message}")
      payload ||= {}
    end

    payload ||= {}
    payload['job_id'] = jid
    payload['menu_id'] ||= @menu.id

    render json: payload
  end

  # POST /restaurants/:restaurant_id/menus/:id/polish
  def polish
    authorize @menu, :update?

    total = @menuItemCount.presence || @menu.menuitems.count
    jid = AiMenuPolisherJob.perform_async(@menu.id)

    begin
      Sidekiq.redis do |r|
        r.setex("polish:#{jid}", 24 * 3600, {
          status: 'queued',
          current: 0,
          total: total,
          message: 'Queued AI menu polishing',
          menu_id: @menu.id,
        }.to_json,)
      end
    rescue StandardError => e
      Rails.logger.warn("[MenusController] Failed to init polish progress for #{jid}: #{e.message}")
    end

    respond_to do |format|
      format.html do
        flash[:notice] = t('menus.controller.polish_queued', default: 'AI menu polishing has been queued.')
        redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu, section: 'details')
      end
      format.json do
        render json: { job_id: jid, total: total, status: 'queued' }
      end
    end
  end

  # GET /restaurants/:restaurant_id/menus/:id/polish_progress
  def polish_progress
    authorize @menu, :update?

    jid = params[:job_id].to_s
    payload = nil
    begin
      Sidekiq.redis do |r|
        json = r.get("polish:#{jid}")
        payload = json.present? ? JSON.parse(json) : {}
      end
    rescue StandardError => e
      Rails.logger.warn("[MenusController] Polish progress read failed for #{jid}: #{e.message}")
      payload ||= {}
    end

    payload ||= {}
    payload['job_id'] = jid
    payload['menu_id'] ||= @menu.id

    render json: payload
  end

  # POST /menus/:id/localize
  def localize
    authorize @menu, :update?

    restaurant = @restaurant || @menu.restaurant
    active_locales = Restaurantlocale.where(restaurant: restaurant, status: 'active')

    if active_locales.empty?
      flash.now[:alert] = t('menus.controller.no_active_locales', default: 'No active locales configured for this restaurant.')
      redirect_to edit_restaurant_menu_path(restaurant, @menu) and return
    end

    # Get force parameter (default: false - only translate missing localizations)
    force = params[:force].to_s == 'true'

    # Trigger the background job to localize the menu
    items_count = @menuItemCount.presence || @menu.menuitems.count
    total = active_locales.count * items_count
    jid = MenuLocalizationJob.perform_async('menu', @menu.id, force)

    # Initialize localization progress in Redis
    begin
      Sidekiq.redis do |r|
        r.setex("localize:#{jid}", 24 * 3600, {
          status: 'queued',
          current: 0,
          total: total,
          message: 'Queued menu localization',
          menu_id: @menu.id,
        }.to_json,)
      end
    rescue StandardError => e
      Rails.logger.warn("[MenusController] Failed to init localization progress for #{jid}: #{e.message}")
    end

    respond_to do |format|
      format.html do
        flash_message = if force
                          t('menus.controller.localization_queued_force',
                            default: "Menu re-translation has been queued. This will process #{total} item translations across #{active_locales.count} locale(s).",)
                        else
                          t('menus.controller.localization_queued',
                            default: "Menu localization has been queued. This will process up to #{total} item translations across #{active_locales.count} locale(s).",)
                        end
        flash[:notice] = flash_message
        redirect_to edit_restaurant_menu_path(restaurant, @menu)
      end
      format.json do
        render json: { job_id: jid, total: total, status: 'queued' }
      end
    end
  end

  # GET /restaurants/:restaurant_id/menus/:id/localization_progress
  def localization_progress
    authorize @menu, :update?

    jid = params[:job_id].to_s
    payload = nil
    begin
      Sidekiq.redis do |r|
        json = r.get("localize:#{jid}")
        payload = json.present? ? JSON.parse(json) : {}
      end
    rescue StandardError => e
      Rails.logger.warn("[MenusController] Localization progress read failed for #{jid}: #{e.message}")
      payload ||= {}
    end

    payload ||= {}
    payload['job_id'] = jid
    payload['menu_id'] ||= @menu.id

    render json: payload
  end

  # GET	/restaurants/:restaurant_id/menus/:menu_id/tablesettings/:id(.:format)	menus#show
  # GET	/restaurants/:restaurant_id/menus/:id(.:format)	 menus#show
  # GET /menus/1 or /menus/1.json
  def show
    # Always authorize - policy handles public vs private access
    authorize @menu
    if params[:menu_id] && params[:id]
      if params[:restaurant_id]
        @restaurant = Restaurant.find_by(id: params[:restaurant_id])
        @menu = Menu.find_by(id: params[:menu_id])
        if @menu.restaurant != @restaurant
          redirect_to root_url
        end

        # Use AdvancedCacheService for comprehensive menu data with localization
        locale = params[:locale] || 'en'
        @menu_data = AdvancedCacheService.cached_menu_with_items(@menu.id, locale: locale, include_inactive: false)

        # Trigger strategic cache warming for menu and restaurant data
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
      @openOrder = Ordr.where(menu_id: params[:menu_id], tablesetting_id: params[:id],
                              restaurant_id: @tablesetting.restaurant_id, status: 0,)
        .or(Ordr.where(menu_id: params[:menu_id], tablesetting_id: params[:id],
                       restaurant_id: @tablesetting.restaurant_id, status: 20,))
        .or(Ordr.where(menu_id: params[:menu_id], tablesetting_id: params[:id],
                       restaurant_id: @tablesetting.restaurant_id, status: 30,)).first
      if @openOrder
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
        if current_user
          @ep = Ordrparticipant.where(ordr: @openOrder, employee: @current_employee, role: 1,
                                      sessionid: session.id.to_s,).first
          if @ep.nil?
            @ordrparticipant = Ordrparticipant.new(ordr: @openOrder, employee: @current_employee, role: 1,
                                                   sessionid: session.id.to_s,)
            @ordrparticipant.save
          end
        else
          @ep = Ordrparticipant.where(ordr_id: @openOrder.id, role: 0, sessionid: session.id.to_s).first
          if @ep.nil?
            @ordrparticipant = Ordrparticipant.new(ordr_id: @openOrder.id, role: 0,
                                                   sessionid: session.id.to_s,)
            @ordrparticipant.save
            @ordraction = Ordraction.new(ordrparticipant_id: @ordrparticipant.id, ordr: @openOrder, action: 0)
          else
            @ordrparticipant = @ep
            @ordraction = Ordraction.new(ordrparticipant: @ep, ordr: @openOrder, action: 0)
          end
          @ordraction.save
        end
      end
    else
      @menu = Menu.find_by(id: params[:id])
      @allergyns = Allergyn.where(restaurant_id: @menu.restaurant.id)
    end
  end

  # GET /menus/new
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
      properties: {
        restaurant_id: @menu.restaurant&.id,
      },
    )
  end

  # GET /menus/1/edit
  def edit
    authorize @menu

    if params[:menu_id] && params[:id]
      if params[:restaurant_id]
        @restaurant = Restaurant.find_by(id: params[:restaurant_id])
        @menu = Menu.find_by(id: params[:menu_id])
        if @menu.restaurant != @restaurant
          redirect_to root_url
          return
        end
      end
      Analytics.track(
        event: 'menus.edit',
        properties: {
          restaurant_id: @menu.restaurant.id,
          menu_id: @menu.id,
        },
      )
    end
    respond_to do |format|
      format.html do
        ActiveRecord::Base.connected_to(role: :writing) do
          # Generate QR code for public menu URL (smartmenu slug)
          if @menu.smartmenu&.slug
            @qrURL = Rails.application.routes.url_helpers.smartmenu_url(@menu.smartmenu.slug, host: request.host_with_port)
            @qrURL.sub! 'http', 'https'
            @qr = RQRCode::QRCode.new(@qrURL)
          end

          # Set current section for 2025 UI
          @current_section = params[:section] || 'details'

          # 2025 UI is now the default
          # Provides modern sidebar navigation
          # Use ?old_ui=true to access legacy UI if needed
          unless params[:old_ui] == 'true'
            # Handle Turbo Frame requests for section content
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
      # Avoid MissingTemplate if a JSON request hits edit (e.g. during locale switching)
      format.json { head :ok }
    end
  end

  # POST /menus or /menus.json
  def create
    context_restaurant = @restaurant || Restaurant.find(menu_params[:restaurant_id])
    @menu = context_restaurant.menus.build(menu_params)
    authorize @menu

    plan = current_user&.plan
    menus_limit = plan&.menusperlocation
    if menus_limit.present? && menus_limit != -1
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
      # Remove PDF if requested
      if (params.dig(:menu, :remove_pdf_menu_scan) == '1') && @menu.pdf_menu_scan.attached?
        @menu.pdf_menu_scan.purge
      end
      if @menu.save
        Analytics.track(
          user_id: current_user.id,
          event: 'menus.create',
          properties: {
            restaurant_id: @menu.restaurant.id,
            menu_id: @menu.id,
          },
        )
        if @menu.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @menu.restaurant
          @genimage.menu = @menu
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
        Rails.logger.debug 'SmartMenuGeneratorJob.start'
        SmartMenuGeneratorJob.perform_async(@menu.restaurant.id)
        Rails.logger.debug 'SmartMenuGeneratorJob.end'
        format.html do
          redirect_to edit_restaurant_path(id: @menu.restaurant.id),
                      notice: t('common.flash.created', resource: t('activerecord.models.menu'))
        end
        format.json do
          render :show, status: :created, location: restaurant_menu_url(@restaurant || @menu.restaurant, @menu)
        end
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @menu.errors, status: :unprocessable_content }
      end
    end
  rescue ArgumentError => e
    # Handle invalid enum values
    @menu = Menu.new
    @menu.errors.add(:status, e.message)
    respond_to do |format|
      format.html { render :new, status: :unprocessable_content }
      format.json { render json: @menu.errors, status: :unprocessable_content }
    end
  end

  # PATCH/PUT /menus/1 or /menus/1.json
  def update
    authorize @menu

    respond_to do |format|
      # Remove PDF if requested
      if (params.dig(:menu, :remove_pdf_menu_scan) == '1') && @menu.pdf_menu_scan.attached?
        @menu.pdf_menu_scan.purge
      end
      # Build attributes once and save
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

      Rails.logger.info("[MenusController#update] raw_menu=#{raw_menu.inspect} built_attrs=#{attrs.inspect}")

      @menu.assign_attributes(attrs)
      updated = @menu.changed? ? @menu.save : true
      Rails.logger.info("[MenusController#update] save_result=#{updated} persisted_status=#{@menu.status}")

      @menu.reload if updated

      if updated
        # Invalidate AdvancedCacheService caches for this menu
        AdvancedCacheService.invalidate_menu_caches(@menu.id)
        AdvancedCacheService.invalidate_restaurant_caches(@menu.restaurant.id)

        Analytics.track(
          user_id: current_user.id,
          event: 'menus.update',
          properties: {
            restaurant_id: @menu.restaurant.id,
            menu_id: @menu.id,
          },
        )
        if @menu.genimage.nil?
          @genimage = Genimage.new
          @genimage.restaurant = @menu.restaurant
          @genimage.menu = @menu
          @genimage.created_at = DateTime.current
          @genimage.updated_at = DateTime.current
          @genimage.save
        end
        Rails.logger.debug 'SmartMenuGeneratorJob.start'
        SmartMenuGeneratorJob.perform_async(@menu.restaurant.id)
        Rails.logger.debug 'SmartMenuGeneratorJob.end'
        format.html do
          if turbo_frame_request_id == 'menu_content'
            @current_section = 'settings'
            render partial: 'menus/section_frame_2025',
                   locals: { menu: @menu, partial_name: menu_section_partial_name(@current_section) }
          elsif params[:return_to] == 'menu_edit'
            redirect_to edit_restaurant_menu_path(@restaurant || @menu.restaurant, @menu),
                        notice: t('common.flash.updated', resource: t('activerecord.models.menu'))
          else
            redirect_to edit_restaurant_path(id: @menu.restaurant.id),
                        notice: t('common.flash.updated', resource: t('activerecord.models.menu'))
          end
        end
        format.json { render :show, status: :ok, location: restaurant_menu_url(@restaurant || @menu.restaurant, @menu) }
      else
        Rails.logger.warn("[MenusController#update] Update failed for menu=#{@menu.id} errors=#{@menu.errors.full_messages}")
        format.html do
          if turbo_frame_request_id == 'menu_content'
            @current_section = 'settings'
            render partial: 'menus/section_frame_2025',
                   locals: { menu: @menu, partial_name: menu_section_partial_name(@current_section) },
                   status: :unprocessable_content
          elsif params[:return_to] == 'menu_edit'
            # Redirect back to menu edit with alert for quick-action UX
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

    Rails.logger.info "[UpdateAvailabilities] Received request for menu #{@menu.id}"
    Rails.logger.info "[UpdateAvailabilities] Availabilities params: #{params[:availabilities].inspect}"
    Rails.logger.info "[UpdateAvailabilities] Inactive params: #{params[:inactive].inspect}"

    availabilities_params = params[:availabilities] || {}

    # Process each day's availabilities
    availabilities_params.each do |day, times|
      Rails.logger.info "[UpdateAvailabilities] Processing day: #{day}, times: #{times.inspect}"

      # Find or create menuavailability for this day
      availability = @menu.menuavailabilities.find_or_initialize_by(
        dayofweek: day,
        sequence: 1, # Default sequence for primary availability
      )

      Rails.logger.info "[UpdateAvailabilities] Found/Created availability: #{availability.inspect}"

      # Parse times (handle both symbol and string keys from FormData)
      start_time = times[:start] || times['start']
      end_time = times[:end] || times['end']

      if start_time.present? && end_time.present?
        start_parts = start_time.split(':')
        end_parts = end_time.split(':')

        availability.starthour = start_parts[0].to_i
        availability.startmin = start_parts[1].to_i
        availability.endhour = end_parts[0].to_i
        availability.endmin = end_parts[1].to_i
        availability.status = :active # Use enum symbol

        Rails.logger.info "[UpdateAvailabilities] Setting times: #{availability.starthour}:#{availability.startmin} - #{availability.endhour}:#{availability.endmin}"
      else
        Rails.logger.warn "[UpdateAvailabilities] No time data for #{day}: start=#{start_time.inspect}, end=#{end_time.inspect}"
      end

      if availability.save
        Rails.logger.info "[UpdateAvailabilities] Saved availability for #{day}: #{availability.id}"
      else
        Rails.logger.error "[UpdateAvailabilities] Failed to save availability for #{day}: #{availability.errors.full_messages}"
      end
    end

    # Handle inactive days (checkboxes that are checked)
    if params[:inactive].is_a?(Hash)
      params[:inactive].each do |day, is_inactive|
        Rails.logger.info "[UpdateAvailabilities] Processing inactive day: #{day} = #{is_inactive}"
        next unless is_inactive == '1'

        availability = @menu.menuavailabilities.find_or_initialize_by(
          dayofweek: day,
          sequence: 1,
        )
        availability.status = :inactive # Use enum symbol
        if availability.save
          Rails.logger.info "[UpdateAvailabilities] Marked #{day} as inactive"
        else
          Rails.logger.error "[UpdateAvailabilities] Failed to mark #{day} as inactive: #{availability.errors.full_messages}"
        end
      end
    end

    Rails.logger.info '[UpdateAvailabilities] Finished processing all availabilities'

    # Invalidate caches
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

  # DELETE /menus/1 or /menus/1.json
  def destroy
    authorize @menu

    @menu.update(archived: true)

    # Invalidate AdvancedCacheService caches for this menu
    AdvancedCacheService.invalidate_menu_caches(@menu.id)
    AdvancedCacheService.invalidate_restaurant_caches(@menu.restaurant.id)

    Analytics.track(
      user_id: current_user.id,
      event: 'menus.destroy',
      properties: {
        restaurant_id: @menu.restaurant.id,
        menu_id: @menu.id,
      },
    )
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_path(id: @menu.restaurant.id),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.menu'))
      end
      format.json { head :no_content }
    end
  end

  # GET /menus/1/performance
  # GET /restaurants/:restaurant_id/menus/:id/performance
  def performance
    Rails.logger.debug do
      "[MenusController#performance] Method called - @menu: #{@menu&.id}, @restaurant: #{@restaurant&.id}"
    end
    Rails.logger.debug { "[MenusController#performance] Params: #{params.inspect}" }

    # Safety check - ensure @menu is set
    unless @menu
      Rails.logger.error "[MenusController#performance] @menu is nil, @restaurant: #{@restaurant&.id}"
      if @restaurant
        redirect_to restaurant_menus_path(@restaurant), alert: 'Menu not found'
      else
        redirect_to restaurants_path, alert: 'Restaurant and menu not found'
      end
      return
    end

    # Check authorization manually since we excluded this action from verify_authorized
    unless policy(@menu).performance?
      Rails.logger.warn "[MenusController#performance] Authorization failed for menu #{@menu.id}"
      redirect_to restaurant_menus_path(@restaurant), alert: 'Access denied'
      return
    end

    Rails.logger.debug { "[MenusController#performance] Processing performance for menu #{@menu.id}" }

    # Get time period from params or default to last 30 days
    days = params[:days]&.to_i || 30
    period_start = days.days.ago

    # Collect menu-specific performance data
    begin
      @performance_data = {
        menu: {
          id: @menu.id,
          name: @menu.name,
          restaurant_name: @menu.restaurant.name,
          created_at: @menu.created_at,
        },
        period: {
          days: days,
          start_date: period_start.strftime('%Y-%m-%d'),
          end_date: Date.current.strftime('%Y-%m-%d'),
        },
        cache_performance: collect_menu_cache_performance_data,
        database_performance: collect_menu_database_performance_data,
        response_times: collect_menu_response_time_data,
        user_activity: collect_menu_user_activity_data(days),
        system_metrics: collect_menu_system_metrics_data,
      }
    rescue StandardError => e
      Rails.logger.error "[MenusController#performance] Error collecting performance data: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Provide fallback data structure
      @performance_data = {
        menu: {
          id: @menu.id,
          name: @menu.name,
          restaurant_name: @menu.restaurant.name,
          created_at: @menu.created_at,
        },
        period: {
          days: days,
          start_date: period_start.strftime('%Y-%m-%d'),
          end_date: Date.current.strftime('%Y-%m-%d'),
        },
        cache_performance: { hit_rate: 0, total_hits: 0, total_misses: 0, total_operations: 0,
                             last_reset: Time.current.iso8601, },
        database_performance: { primary_queries: 0, replica_queries: 0, replica_lag: 0, connection_pool_usage: 0,
                                slow_queries: 0, },
        response_times: { average: 0, maximum: 0, request_count: 0, cache_efficiency: 0 },
        user_activity: { total_sessions: 0, unique_visitors: 0, page_views: 0, average_session_duration: 0,
                         bounce_rate: 0, },
        system_metrics: { memory_usage: 0, cpu_usage: 0, disk_usage: 0, active_connections: 0, background_jobs: 0 },
      }
    end

    Rails.logger.debug do
      "[MenusController#performance] Performance data collected successfully: #{@performance_data.keys}"
    end

    # Track menu performance view
    AnalyticsService.track_user_event(current_user, 'menu_performance_viewed', {
      menu_id: @menu.id,
      restaurant_id: @menu.restaurant.id,
      period_days: days,
      cache_hit_rate: @performance_data[:cache_performance][:hit_rate],
      avg_response_time: @performance_data[:response_times][:average],
    })

    Rails.logger.debug '[MenusController#performance] Responding with performance data'
    respond_to do |format|
      format.html
      format.json { render json: @performance_data }
    end
  end

  # PATCH /restaurants/:restaurant_id/menus/update_sequence
  def update_sequence
    # Check restaurant ownership
    unless @restaurant.user_id == current_user.id
      return render json: { status: 'error', message: 'Unauthorized' }, status: :forbidden
    end

    Rails.logger.info "Received params: #{params.inspect}"

    order = params[:order] || []

    Rails.logger.info "Order array: #{order.inspect}"

    if order.blank?
      return render json: { status: 'error', message: 'No order data provided' }, status: :unprocessable_content
    end

    ActiveRecord::Base.transaction do
      order.each do |item|
        item_hash = if item.is_a?(ActionController::Parameters)
                      item.to_unsafe_h
                    elsif item.is_a?(Hash)
                      item
                    else
                      Rails.logger.warn("[MenusController#update_sequence] skipping non-hash item item_class=#{item.class} item=#{item.inspect}")
                      next
                    end

        id = item_hash[:id] || item_hash['id']
        seq = item_hash[:sequence] || item_hash['sequence']
        if id.blank? || seq.nil?
          Rails.logger.warn("[MenusController#update_sequence] skipping invalid item item=#{item_hash.inspect}")
          next
        end

        Rails.logger.info "Processing item: #{item_hash.inspect}"
        menu = Menu.joins(:restaurant_menus)
          .where(restaurant_menus: { restaurant_id: @restaurant.id })
          .find(id)
        authorize menu, :update?
        menu.update_column(:sequence, seq.to_i)
      end
    end

    render json: { status: 'success', message: 'Menus reordered successfully' }, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Menu not found: #{e.message}"
    render json: { status: 'error', message: 'Menu not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "Update sequence error: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { status: 'error', message: e.message }, status: :unprocessable_content
  end

  # PATCH /restaurants/:restaurant_id/menus/bulk_update
  def bulk_update
    ids = Array(params[:menu_ids]).map(&:to_s).compact_blank
    status = params[:status].to_s

    if ids.empty? || status.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/menus_2025',
            locals: { restaurant: @restaurant, filter: 'all' },
          )
        end
        format.html do
          redirect_to edit_restaurant_path(@restaurant, section: 'menus')
        end
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
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/menus_2025',
            locals: { restaurant: @restaurant, filter: 'all' },
          )
        end
        format.html do
          redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'You need an active subscription to activate a menu.'
        end
      end
      return
    end

    menus.find_each do |menu|
      authorize menu, :update?
      menu.update(status: status)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/menus_2025',
          locals: { restaurant: @restaurant, filter: 'all' },
        )
      end
      format.html do
        redirect_to edit_restaurant_path(@restaurant, section: 'menus')
      end
    end
  end

  private

  def ensure_owner_restaurant_context!
    return unless @restaurant && @menu

    owner_restaurant_id = @menu.owner_restaurant_id.presence || @menu.restaurant_id
    return if owner_restaurant_id.blank?
    return if @restaurant.id == owner_restaurant_id

    redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'This menu is read-only for this restaurant'
  end

  # Map section names to partial names for 2025 UI
  def menu_section_partial_name(section)
    case section
    when 'details' then 'details_2025'
    when 'sections' then 'sections_2025'
    when 'items' then 'items_2025'
    when 'schedule' then 'schedule_2025'
    when 'settings' then 'settings_2025'
    when 'qrcode' then 'qrcode_2025'
    when 'versions' then 'versions_2025'
    else 'details_2025'
    end
  end

  # Skip policy scope verification for optimized restaurant-specific JSON requests
  def skip_policy_scope?
    current_user.blank? || (@restaurant.present? && request.format.json? && current_user.present?)
  end

  # Set restaurant from nested route parameter - optimized for fast failure
  def set_restaurant
    return if params[:restaurant_id].blank?

    if current_user
      # Fast ownership check to avoid expensive exception handling
      restaurant_id = params[:restaurant_id].to_i
      is_owner = current_user.restaurants.exists?(id: restaurant_id)
      is_active_employee = Employee.exists?(user_id: current_user.id, restaurant_id: restaurant_id, status: :active)

      unless is_owner || is_active_employee
        Rails.logger.warn "[MenusController] Access denied: User #{current_user.id} cannot access restaurant #{restaurant_id}"
        respond_to do |format|
          format.html { redirect_to restaurants_path, alert: 'Restaurant not found or access denied' }
          format.json { head :forbidden }
        end
        return
      end

      @restaurant = if is_owner
                      current_user.restaurants.find(restaurant_id)
                    else
                      Restaurant.find(restaurant_id)
                    end
    else
      # For non-authenticated users (public access)
      @restaurant = Restaurant.find(params[:restaurant_id])
    end

    Rails.logger.debug { "[MenusController] Found restaurant: #{@restaurant&.id} - #{@restaurant&.name}" }
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "[MenusController] Restaurant not found for id=#{params[:restaurant_id]}: #{e.message}"
    respond_to do |format|
      format.html { redirect_to restaurants_path, alert: 'Restaurant not found' }
      format.json { head :not_found }
    end
  rescue StandardError => e
    Rails.logger.error "[MenusController] Error in set_restaurant: #{e.message}"
    respond_to do |format|
      format.html { redirect_to restaurants_path, alert: 'An error occurred while loading the restaurant' }
      format.json { head :internal_server_error }
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_menu
    menu_id = params[:menu_id] || params[:id]

    Rails.logger.debug { "[MenusController] set_menu called with menu_id=#{menu_id}, restaurant=#{@restaurant&.id}" }

    if menu_id.blank?
      Rails.logger.error "[MenusController] No menu ID provided in params: #{params.inspect}"
      redirect_to restaurant_menus_path(@restaurant), alert: 'Menu not specified'
      return
    end

    @menu = if @restaurant
              Menu.joins(:restaurant_menus)
                .where(restaurant_menus: { restaurant_id: @restaurant.id })
                .find(menu_id)
            else
              Menu.find(menu_id)
            end

    if @restaurant && @menu
      @restaurant_menu = RestaurantMenu.find_by(restaurant_id: @restaurant.id, menu_id: @menu.id)
      owner_restaurant_id = @menu.owner_restaurant_id.presence || @menu.restaurant_id
      @read_only_menu_context = owner_restaurant_id.present? && @restaurant.id != owner_restaurant_id

      ensure_smartmenus_for_restaurant_menu!(@restaurant, @menu)
    end

    Rails.logger.debug { "[MenusController] Found menu: #{@menu&.id} - #{@menu&.name}" }

    # Access to menu is already scoped to an attached restaurant for nested routes.

    # Set up additional menu context
    if @menu
      restaurant_currency_code = @restaurant&.currency || @menu.restaurant.currency || 'USD'
      @restaurantCurrency = ISO4217::Currency.from_code(restaurant_currency_code)
      @canAddMenuItem = false
      if current_user
        @menuItemCount ||= @menu.menuitems.count
        if @menuItemCount < current_user.plan.itemspermenu || current_user.plan.itemspermenu == -1
          @canAddMenuItem = true
        end
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "[MenusController] Menu not found for id=#{menu_id}: #{e.message}"
    redirect_to (@restaurant ? restaurant_menus_path(@restaurant) : restaurants_path), alert: 'Menu not found'
  rescue StandardError => e
    Rails.logger.error "[MenusController] Error in set_menu: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to (@restaurant ? restaurant_menus_path(@restaurant) : restaurants_path),
                alert: 'An error occurred while loading the menu'
  end

  # Menu-specific performance data collection methods
  def collect_menu_cache_performance_data
    # Get menu-specific cache performance from AdvancedCacheService
    menu_performance = AdvancedCacheService.cached_menu_performance(@menu.id, 30)

    {
      hit_rate: menu_performance[:cache_stats][:hit_rate] || 0,
      total_hits: menu_performance[:cache_stats][:hits] || 0,
      total_misses: menu_performance[:cache_stats][:misses] || 0,
      total_operations: menu_performance[:cache_stats][:operations] || 0,
      last_reset: Time.current.iso8601,
    }
  rescue StandardError => e
    Rails.logger.error("[MenusController] Menu cache performance data collection failed: #{e.message}")
    { hit_rate: 0, total_hits: 0, total_misses: 0, total_operations: 0, last_reset: Time.current.iso8601 }
  end

  def collect_menu_database_performance_data
    # Menu-specific database queries and performance
    {
      primary_queries: 0, # Menu-specific primary queries
      replica_queries: 0, # Menu-specific replica queries
      replica_lag: DatabaseRoutingService.replica_lag_ms || 0,
      connection_pool_usage: calculate_connection_pool_usage,
      slow_queries: 0, # Menu-specific slow queries
    }
  rescue StandardError => e
    Rails.logger.error("[MenusController] Menu database performance data collection failed: #{e.message}")
    { primary_queries: 0, replica_queries: 0, replica_lag: 0, connection_pool_usage: 0, slow_queries: 0 }
  end

  def collect_menu_response_time_data
    # Get menu-specific response time data
    performance_summary = begin
      MenusController.cache_performance_summary(days: 30)
    rescue StandardError
      {}
    end
    menu_metrics = performance_summary['menus#show'] || {}

    {
      average: menu_metrics[:avg_time] || 0,
      maximum: menu_metrics[:max_time] || 0,
      request_count: menu_metrics[:count] || 0,
      cache_efficiency: menu_metrics[:avg_cache_hits] || 0,
    }
  rescue StandardError => e
    Rails.logger.error("[MenusController] Menu response time data collection failed: #{e.message}")
    { average: 0, maximum: 0, request_count: 0, cache_efficiency: 0 }
  end

  def collect_menu_user_activity_data(_days)
    # Menu-specific user activity and engagement
    {
      total_sessions: 0, # Sessions viewing this menu
      unique_visitors: 0, # Unique visitors to this menu
      page_views: 0, # Page views for this menu
      average_session_duration: 0, # Time spent viewing menu
      bounce_rate: 0, # Bounce rate for menu pages
    }
  rescue StandardError => e
    Rails.logger.error("[MenusController] Menu user activity data collection failed: #{e.message}")
    { total_sessions: 0, unique_visitors: 0, page_views: 0, average_session_duration: 0, bounce_rate: 0 }
  end

  def collect_menu_system_metrics_data
    # System metrics relevant to menu performance
    {
      memory_usage: get_memory_usage_mb,
      cpu_usage: 0,
      disk_usage: 0,
      active_connections: get_active_connections_count,
      background_jobs: 0,
    }
  rescue StandardError => e
    Rails.logger.error("[MenusController] Menu system metrics data collection failed: #{e.message}")
    { memory_usage: 0, cpu_usage: 0, disk_usage: 0, active_connections: 0, background_jobs: 0 }
  end

  def calculate_connection_pool_usage
    pool = ActiveRecord::Base.connection_pool
    ((pool.connections.count.to_f / pool.size) * 100).round(2)
  rescue StandardError
    0
  end

  def get_memory_usage_mb
    `ps -o rss= -p #{Process.pid}`.to_i / 1024
  rescue StandardError
    0
  end

  def get_active_connections_count
    ActiveRecord::Base.connection_pool.connections.count
  rescue StandardError
    0
  end

  # Menu-specific performance data collection methods
  def collect_menu_cache_performance_data
    # Get menu-specific cache performance from AdvancedCacheService
    menu_performance = AdvancedCacheService.cached_menu_performance(@menu.id, 30)

    {
      hit_rate: menu_performance[:cache_stats][:hit_rate] || 0,
      total_hits: menu_performance[:cache_stats][:hits] || 0,
      total_misses: menu_performance[:cache_stats][:misses] || 0,
      total_operations: menu_performance[:cache_stats][:operations] || 0,
      last_reset: Time.current.iso8601,
    }
  rescue StandardError => e
    Rails.logger.error "[MenusController#performance] Cache performance collection failed: #{e.message}"
    { hit_rate: 0, total_hits: 0, total_misses: 0, total_operations: 0, last_reset: Time.current.iso8601 }
  end

  def collect_menu_database_performance_data
    {
      primary_queries: 0, # Would need actual query monitoring
      replica_queries: 0,
      replica_lag: 0,
      connection_pool_usage: calculate_connection_pool_usage,
      slow_queries: 0, # Would need slow query log analysis
    }
  rescue StandardError => e
    Rails.logger.error "[MenusController#performance] Database performance collection failed: #{e.message}"
    { primary_queries: 0, replica_queries: 0, replica_lag: 0, connection_pool_usage: 0, slow_queries: 0 }
  end

  def collect_menu_response_time_data
    # This would typically come from application performance monitoring
    {
      average: 250, # milliseconds - placeholder
      maximum: 1200,
      request_count: 0,
      cache_efficiency: 85.5,
    }
  rescue StandardError => e
    Rails.logger.error "[MenusController#performance] Response time collection failed: #{e.message}"
    { average: 0, maximum: 0, request_count: 0, cache_efficiency: 0 }
  end

  def collect_menu_user_activity_data(_days)
    # This would typically come from analytics service
    {
      total_sessions: 0,
      unique_visitors: 0,
      page_views: 0,
      average_session_duration: 0,
      bounce_rate: 0,
    }
  rescue StandardError => e
    Rails.logger.error "[MenusController#performance] User activity collection failed: #{e.message}"
    { total_sessions: 0, unique_visitors: 0, page_views: 0, average_session_duration: 0, bounce_rate: 0 }
  end

  def collect_menu_system_metrics_data
    {
      memory_usage: calculate_memory_usage,
      cpu_usage: 0, # Would need system monitoring
      disk_usage: 0,
      active_connections: calculate_active_connections,
      background_jobs: 0, # Would need Sidekiq stats
    }
  rescue StandardError => e
    Rails.logger.error "[MenusController#performance] System metrics collection failed: #{e.message}"
    { memory_usage: 0, cpu_usage: 0, disk_usage: 0, active_connections: 0, background_jobs: 0 }
  end

  def calculate_memory_usage
    # Basic memory usage calculation
    `ps -o rss= -p #{Process.pid}`.to_i / 1024 # Convert KB to MB
  rescue StandardError
    0
  end

  def calculate_active_connections
    ActiveRecord::Base.connection_pool.connections.count
  rescue StandardError
    0
  end

  def calculate_connection_pool_usage
    pool = ActiveRecord::Base.connection_pool
    (pool.connections.count.to_f / pool.size * 100).round(2)
  rescue StandardError
    0
  end

  # Only allow a list of trusted parameters through.
  def menu_params
    params.require(:menu).permit(:name, :description, :image, :remove_image, :pdf_menu_scan, :status, :sequence,
                                 :restaurant_id, :displayImages, :displayImagesInPopup, :allowOrdering, :voiceOrderingEnabled, :inventoryTracking, :imagecontext, :covercharge, :test,)
  end
end
