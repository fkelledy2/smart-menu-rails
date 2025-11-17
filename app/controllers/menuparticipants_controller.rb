class MenuparticipantsController < ApplicationController
  # Allow customers to interact with menus without authentication
  before_action :set_restaurant
  before_action :set_menu
  before_action :set_menuparticipant, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /restaurants/:restaurant_id/menus/:menu_id/menuparticipants
  def index
    @menuparticipants = if current_user
                          policy_scope(Menuparticipant).where(menu: @menu).limit(100)
                        else
                          Menuparticipant.where(menu: @menu).limit(100)
                        end
  end

  # GET /menuparticipants/1 or /menuparticipants/1.json
  def show
    # Always authorize - policy handles public vs private access
    authorize @menuparticipant
  end

  # GET /menus/:menu_id/menuparticipants/new
  def new
    @menuparticipant = Menuparticipant.new
    if params[:menu_id]
      @menu = Menu.find(params[:menu_id])
      @menuparticipant.menu = @menu
    end
    # Always authorize - policy handles public vs private access
    authorize @menuparticipant
  end

  # GET /menuparticipants/1/edit
  def edit
    # Always authorize - editing requires authentication
    authorize @menuparticipant
  end

  # POST /menuparticipants or /menuparticipants.json
  def create
    @menuparticipant = Menuparticipant.new(menuparticipant_params)
    # Always authorize - policy handles public vs private access
    authorize @menuparticipant

    respond_to do |format|
      if @menuparticipant.save
        # Set @restaurant and @menu for URL generation
        if @menuparticipant.smartmenu
          @restaurant ||= @menuparticipant.smartmenu.restaurant
          @menu ||= @menuparticipant.smartmenu.menu
        end
        broadcastPartials
        format.json do
          render :show, status: :created,
                        location: restaurant_menu_menuparticipant_url(@restaurant, @menu, @menuparticipant)
        end
      else
        @smartmenus = Smartmenu.all
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menuparticipant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menuparticipants/1 or /menuparticipants/1.json
  def update
    # Always authorize - policy handles public vs private access
    authorize @menuparticipant

    respond_to do |format|
      if @menuparticipant.update(menuparticipant_params)
        @menuparticipant.smartmenu = Smartmenu.find(params[:menuparticipant][:smartmenu_id]) if params[:menuparticipant][:smartmenu_id]
        @menuparticipant.save

        # If the participant's locale changed, keep any related
        # Ordrparticipants in sync and invalidate cached menu content
        # so the next broadcast renders with the new locale.
        if @menuparticipant.saved_change_to_preferredlocale?
          sync_ordrparticipants_locale_for_session(@menuparticipant)
          invalidate_menu_content_cache_for_menuparticipant(@menuparticipant)
        end

        # For locale changes when an order participant exists, the
        # OrdrparticipantsController broadcast handles the partial
        # refresh. In that case we can skip this broadcast to avoid
        # duplicate updates.
        broadcastPartials unless ActiveModel::Type::Boolean.new.cast(params[:skip_broadcast])
        #         format.html { redirect_to @menuparticipant, notice: "Menuparticipant was successfully updated." }
        format.json do
          render :show, status: :ok, location: restaurant_menu_menuparticipant_url(@restaurant, @menu, @menuparticipant)
        end
      else
        #         @smartmenus = Smartmenu.all
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menuparticipant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menuparticipants/1 or /menuparticipants/1.json
  def destroy
    @menuparticipant.destroy!

    respond_to do |format|
      format.html do
        redirect_to restaurant_menu_menuparticipants_path(@restaurant || @menu.restaurant, @menu), status: :see_other,
                                                                                                   notice: 'Menuparticipant was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  private

  # Set restaurant from nested route parameter
  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id]) if params[:restaurant_id]
  end

  # Set menu from nested route parameter
  def set_menu
    @menu = if @restaurant
              @restaurant.menus.find(params[:menu_id])
            else
              Menu.find(params[:menu_id])
            end
  end

  def broadcastPartials
    menuparticipant = Menuparticipant.includes(smartmenu: [:menu,
                                                           { restaurant: %i[menusections menuavailabilities] }, :tablesetting,]).find_by(sessionid: session.id.to_s)
    return unless menuparticipant

    smartmenu = menuparticipant.smartmenu
    menu = smartmenu.menu
    restaurant = smartmenu.restaurant
    tablesetting = smartmenu.tablesetting
    restaurant_currency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
    allergyns = Allergyn.where(restaurant_id: restaurant.id)
    full_refresh = false
    
    # Determine locale for rendering:
    # - use the restaurant's default locale when it is active and allowed
    # - otherwise fall back to the global I18n.default_locale
    allowed_locales = I18n.available_locales.map(&:to_s)

    participant_locale = nil

    if restaurant.defaultLocale&.locale.present?
      default_locale_str = restaurant.defaultLocale.locale.to_s.downcase
      participant_locale = default_locale_str.to_sym if allowed_locales.include?(default_locale_str)
    end

    # Final fallback to global default
    participant_locale ||= I18n.default_locale

    partials = I18n.with_locale(participant_locale) do
      {
      context: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showContext',
          locals: {
            order: nil,
            menu: menu,
            ordrparticipant: nil,
            tablesetting: tablesetting,
            menuparticipant: menuparticipant,
            current_employee: @current_employee,
          },
        ),
      ),
      modals: compress_string(
        Rails.cache.fetch([
          :show_modals,
          menu.try(:cache_key_with_version),
          tablesetting.try(:id),
          menuparticipant.try(:id),
          restaurant_currency.code,
          @current_employee.try(:id),
        ]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showModals',
            locals: {
              order: nil,
              menu: menu,
              ordrparticipant: nil,
              tablesetting: tablesetting,
              menuparticipant: menuparticipant,
              restaurantCurrency: restaurant_currency,
              current_employee: @current_employee,
            },
          )
        end,
      ),
      menuContentStaff: compress_string(
        Rails.cache.fetch([
          :menu_content_staff,
          menu.try(:cache_key_with_version),
          allergyns.maximum(:updated_at),
          restaurant_currency.code,
          menuparticipant.try(:id),
          tablesetting.try(:id),
        ]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentStaff',
            locals: {
              order: nil,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: nil,
              menuparticipant: menuparticipant,
              tablesetting: tablesetting,
            },
          )
        end,
      ),
      menuContentCustomer: compress_string(
        Rails.cache.fetch([
          :menu_content_customer,
          menu.try(:cache_key_with_version),
          allergyns.maximum(:updated_at),
          restaurant_currency.code,
          menuparticipant.try(:id),
          tablesetting.try(:id),
        ]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentCustomer',
            locals: {
              order: nil,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: nil,
              menuparticipant: menuparticipant,
              tablesetting: tablesetting,
            },
          )
        end,
      ),
      orderCustomer: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/orderCustomer',
          locals: {
            order: nil,
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: nil,
          },
        ),
      ),
      orderStaff: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/orderStaff',
          locals: {
            order: nil,
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: nil,
          },
        ),
      ),
      tableLocaleSelectorStaff: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showTableLocaleSelectorStaff',
          locals: {
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: nil,
            menuparticipant: menuparticipant,
          },
        ),
      ),
      tableLocaleSelectorCustomer: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showTableLocaleSelectorCustomer',
          locals: {
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: nil,
            menuparticipant: menuparticipant,
          },
        ),
      ),
      fullPageRefresh: { refresh: full_refresh },
      }
    end
    
    ActionCable.server.broadcast("ordr_#{smartmenu.slug}_channel", partials)
  end

  # Helper for compressing partials
  def compress_string(str)
    require 'zlib'
    require 'base64'
    Base64.strict_encode64(Zlib::Deflate.deflate(str))
  end

  # Keep any order participants for the same session in sync with the
  # menuparticipant's preferred locale so that both representations of
  # the participant use the same language.
  def sync_ordrparticipants_locale_for_session(menuparticipant)
    return unless menuparticipant.sessionid.present? && menuparticipant.preferredlocale.present?

    Ordrparticipant.where(sessionid: menuparticipant.sessionid).find_each do |ordrparticipant|
      next if ordrparticipant.preferredlocale == menuparticipant.preferredlocale

      ordrparticipant.update(preferredlocale: menuparticipant.preferredlocale)
    end
  end

  # Remove cached menu content entries tied to this menuparticipant so
  # that subsequent broadcasts render using the updated locale.
  def invalidate_menu_content_cache_for_menuparticipant(menuparticipant)
    smartmenu   = menuparticipant.smartmenu
    return unless smartmenu

    menu        = smartmenu.menu
    restaurant  = smartmenu.restaurant
    tablesetting = smartmenu.tablesetting

    restaurant_currency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
    allergyns = Allergyn.where(restaurant_id: restaurant.id)

    staff_key = [
      :menu_content_staff,
      menu.try(:cache_key_with_version),
      allergyns.maximum(:updated_at),
      restaurant_currency.code,
      menuparticipant.try(:id),
      menuparticipant.try(:preferredlocale),
      tablesetting.try(:id),
    ]

    customer_key = [
      :menu_content_customer,
      menu.try(:cache_key_with_version),
      allergyns.maximum(:updated_at),
      restaurant_currency.code,
      menuparticipant.try(:id),
      menuparticipant.try(:preferredlocale),
      tablesetting.try(:id),
    ]

    Rails.cache.delete(staff_key)
    Rails.cache.delete(customer_key)
  rescue StandardError => e
    Rails.logger.error("Failed to invalidate menu content cache for menuparticipant ##{menuparticipant.id}: #{e.message}")
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_menuparticipant
    @menuparticipant = Menuparticipant.includes(smartmenu: %i[menu restaurant]).find(params[:id])

    # Ensure @restaurant and @menu are set for form rendering
    if @menuparticipant.smartmenu
      @restaurant ||= @menuparticipant.smartmenu.restaurant
      @menu ||= @menuparticipant.smartmenu.menu
    end
  end

  # Only allow a list of trusted parameters through.
  def menuparticipant_params
    params.require(:menuparticipant).permit(:sessionid, :preferredlocale, :smartmenu_id)
  end
end
