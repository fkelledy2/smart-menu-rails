class OrdrparticipantsController < ApplicationController
  before_action :authenticate_user!, except: [:update] # Allow unauthenticated updates for smart menu
  before_action :set_restaurant, except: [:update] # Allow direct updates without restaurant context
  before_action :set_ordrparticipant, only: %i[show edit update destroy]
  before_action :set_ordrparticipant_for_direct_update, only: [:update], if: -> { params[:restaurant_id].blank? }

  # Pundit authorization
  after_action :verify_authorized, except: %i[index update] # Skip authorization for direct updates
  after_action :verify_policy_scoped, only: [:index]

  # GET /ordrparticipants or /ordrparticipants.json
  def index
    @ordrparticipants = policy_scope(Ordrparticipant)
  end

  # GET /ordrparticipants/1 or /ordrparticipants/1.json
  def show
    authorize @ordrparticipant
  end

  # GET /ordrparticipants/new
  def new
    @ordrparticipant = Ordrparticipant.new
    authorize @ordrparticipant
  end

  # GET /ordrparticipants/1/edit
  def edit
    authorize @ordrparticipant
  end

  # POST /ordrparticipants or /ordrparticipants.json
  def create
    @ordrparticipant = Ordrparticipant.new(ordrparticipant_params)
    authorize @ordrparticipant

    respond_to do |format|
      if @ordrparticipant.save
        @tablesetting = Tablesetting.find_by(id: @ordrparticipant.ordr.tablesetting.id)
        broadcast_partials(@ordrparticipant.ordr, @tablesetting, @ordrparticipant)
        format.json do
          render :show, status: :ok,
                        location: restaurant_ordr_url(@ordrparticipant.ordr.restaurant, @ordrparticipant.ordr)
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ordrparticipant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ordrparticipants/1 or /ordrparticipants/1.json
  def update
    # Only authorize if user is authenticated (nested route)
    authorize @ordrparticipant if current_user

    respond_to do |format|
      if @ordrparticipant.update(ordrparticipant_params)
        # Keep the menuparticipant locale in sync for this session and
        # clear cached menu content so it will be regenerated with the
        # new locale.
        sync_menuparticipant_locale_for_session(@ordrparticipant)
        invalidate_menu_content_cache_for_ordr(@ordrparticipant)

        # Find all entries for participant with same sessionid and order_id and update the name.
        @tablesetting = Tablesetting.find_by(id: @ordrparticipant.ordr.tablesetting.id)
        Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)
        broadcast_partials(@ordrparticipant.ordr, @tablesetting, @ordrparticipant)
        format.json do
          render :show, status: :ok,
                        location: restaurant_ordr_url(@ordrparticipant.ordr.restaurant, @ordrparticipant.ordr)
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ordrparticipant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ordrparticipants/1 or /ordrparticipants/1.json
  def destroy
    authorize @ordrparticipant

    @ordrparticipant.destroy!
    respond_to do |format|
      format.html do
        redirect_to ordrparticipants_url,
                    notice: t('common.flash.deleted', resource: t('activerecord.models.ordrparticipant'))
      end
      format.json { head :no_content }
    end
  end

  private

  def broadcast_partials(ordr, tablesetting, ordrparticipant)
    # Eager load all associations needed by partials to prevent N+1 queries
    ordr = Ordr.includes(menu: %i[restaurant menusections menuavailabilities]).find(ordr.id)
    menu = ordr.menu
    restaurant = menu.restaurant
    menuparticipant = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)
    allergyns = Allergyn.where(restaurant_id: restaurant.id)
    restaurant_currency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
    full_refresh = ordr.status == 'closed'

    # Temporary workaround: force locale to the restaurant's default
    # locale (if active and allowed) for all smartmenu pages, ignoring
    # participant-specific preferred locales. This keeps behaviour
    # consistent while localization bugs are being addressed.
    allowed_locales = I18n.available_locales.map(&:to_s)

    participant_locale = nil

    if restaurant.defaultLocale&.locale.present?
      default_locale_str = restaurant.defaultLocale.locale.to_s.downcase
      participant_locale = default_locale_str.to_sym if allowed_locales.include?(default_locale_str)
    end

    participant_locale ||= I18n.default_locale

    partials = I18n.with_locale(participant_locale) do
      {
      context: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/showContext',
          locals: {
            order: ordr,
            menu: menu,
            ordrparticipant: ordrparticipant,
            tablesetting: tablesetting,
            menuparticipant: menuparticipant,
            current_employee: @current_employee,
          },
        ),
      ),
      modals: compress_string(
        Rails.cache.fetch([
          :show_modals,
          ordr.cache_key_with_version,
          menu.cache_key_with_version,
          tablesetting.try(:id),
          menuparticipant.try(:id),
          restaurant_currency.code,
          @current_employee.try(:id),
        ]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showModals',
            locals: {
              order: ordr,
              menu: menu,
              ordrparticipant: ordrparticipant,
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
          ordr.cache_key_with_version,
          menu.cache_key_with_version,
          allergyns.maximum(:updated_at),
          restaurant_currency.code,
          ordrparticipant.try(:id),
          menuparticipant.try(:id),
        ]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentStaff',
            locals: {
              order: ordr,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: ordrparticipant,
              menuparticipant: menuparticipant,
              tablesetting: tablesetting,
            },
          )
        end,
      ),
      menuContentCustomer: compress_string(
        Rails.cache.fetch([
          :menu_content_customer,
          ordr.cache_key_with_version,
          menu.cache_key_with_version,
          allergyns.maximum(:updated_at),
          restaurant_currency.code,
          ordrparticipant.try(:id),
          menuparticipant.try(:id),
        ]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentCustomer',
            locals: {
              order: ordr,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: ordrparticipant,
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
            order: ordr,
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: ordrparticipant,
          },
        ),
      ),
      orderStaff: compress_string(
        ApplicationController.renderer.render(
          partial: 'smartmenus/orderStaff',
          locals: {
            order: ordr,
            menu: menu,
            restaurant: restaurant,
            tablesetting: tablesetting,
            ordrparticipant: ordrparticipant,
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
            ordrparticipant: ordrparticipant,
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
            ordrparticipant: ordrparticipant,
            menuparticipant: menuparticipant,
          },
        ),
      ),
      fullPageRefresh: { refresh: full_refresh },
      }
    end
    ActionCable.server.broadcast("ordr_#{menuparticipant.smartmenu.slug}_channel", partials)
  end

  def compress_string(str)
    require 'zlib'
    require 'base64'
    Base64.strict_encode64(Zlib::Deflate.deflate(str))
  end

  # Ensure there is a single source of truth for the participant's
  # preferred locale for a given session by keeping the menuparticipant
  # in sync with the ordrparticipant.
  def sync_menuparticipant_locale_for_session(ordrparticipant)
    return unless ordrparticipant.sessionid.present? && ordrparticipant.preferredlocale.present?

    Menuparticipant.where(sessionid: ordrparticipant.sessionid).find_each do |menuparticipant|
      next if menuparticipant.preferredlocale == ordrparticipant.preferredlocale

      menuparticipant.update(preferredlocale: ordrparticipant.preferredlocale)
    end
  end

  # Clear cached menu content for staff and customer views for the
  # order context so that subsequent broadcasts will render with the
  # updated locale.
  def invalidate_menu_content_cache_for_ordr(ordrparticipant)
    ordr       = ordrparticipant.ordr
    menu       = ordr.menu
    restaurant = menu.restaurant
    menuparticipant = Menuparticipant.includes(:smartmenu).find_by(sessionid: session.id.to_s)

    return unless menuparticipant

    restaurant_currency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
    allergyns = Allergyn.where(restaurant_id: restaurant.id)

    staff_key = [
      :menu_content_staff,
      ordr.cache_key_with_version,
      menu.cache_key_with_version,
      allergyns.maximum(:updated_at),
      restaurant_currency.code,
      ordrparticipant.try(:id),
      menuparticipant.try(:id),
    ]

    customer_key = [
      :menu_content_customer,
      ordr.cache_key_with_version,
      menu.cache_key_with_version,
      allergyns.maximum(:updated_at),
      restaurant_currency.code,
      ordrparticipant.try(:id),
      menuparticipant.try(:id),
    ]

    Rails.cache.delete(staff_key)
    Rails.cache.delete(customer_key)
  rescue StandardError => e
    Rails.logger.error("Failed to invalidate menu content cache for ordrparticipant ##{ordrparticipant.id}: #{e.message}")
  end

  # Set restaurant from nested route parameter
  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id]) if params[:restaurant_id]
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_ordrparticipant
    @ordrparticipant = Ordrparticipant.find(params[:id])
    if current_user && (@ordrparticipant.nil? || (@ordrparticipant.ordr.restaurant.user != current_user))
      redirect_to root_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  # Set ordrparticipant for direct updates (unauthenticated smart menu interface)
  def set_ordrparticipant_for_direct_update
    @ordrparticipant = Ordrparticipant.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Ordrparticipant not found' }, status: :not_found
  end

  # Only allow a list of trusted parameters through.
  def ordrparticipant_params
    # Remove dangerous mass assignment parameters (employee_id, ordr_id, ordritem_id, role)
    # These should be set explicitly in controller actions, not via mass assignment
    params.require(:ordrparticipant).permit(:sessionid, :action, :name,
                                            :preferredlocale, allergyn_ids: [],)
  end
end
