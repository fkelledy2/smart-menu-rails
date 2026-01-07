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
    ordrparticipant.preferredlocale = menuparticipant.preferredlocale if menuparticipant

    # Prefer the customer's ordrparticipant (role 0) when determining locale,
    # so staff actions do not override the customer's chosen language.
    customer_ordrparticipant = ordr.ordrparticipants.where(role: 0).first

    # Determine a safe locale for rendering smartmenu partials
    available = I18n.available_locales.map(&:to_s)
    raw_locale = nil

    if customer_ordrparticipant&.preferredlocale.present? && available.include?(customer_ordrparticipant.preferredlocale.downcase)
      raw_locale = customer_ordrparticipant.preferredlocale.downcase
    elsif ordrparticipant&.preferredlocale.present? && available.include?(ordrparticipant.preferredlocale.downcase)
      raw_locale = ordrparticipant.preferredlocale.downcase
    elsif menuparticipant&.preferredlocale.present? && available.include?(menuparticipant.preferredlocale.downcase)
      raw_locale = menuparticipant.preferredlocale.downcase
    elsif restaurant.defaultLocale&.locale.present? && available.include?(restaurant.defaultLocale.locale.to_s.downcase)
      raw_locale = restaurant.defaultLocale.locale.to_s.downcase
    elsif available.include?(I18n.default_locale.to_s)
      raw_locale = I18n.default_locale.to_s
    end

    render_locale = (raw_locale || I18n.default_locale.to_s).to_sym

    Rails.logger.warn(
      "[SmartmenuLocaleDebug] ordr_id=#{ordr.id} " \
      "customer_ordrparticipant_id=#{customer_ordrparticipant&.id} " \
      "customer_locale=#{customer_ordrparticipant&.preferredlocale.inspect} " \
      "staff_ordrparticipant_id=#{ordrparticipant&.id} " \
      "staff_locale=#{ordrparticipant&.preferredlocale.inspect} " \
      "menuparticipant_id=#{menuparticipant&.id} " \
      "menuparticipant_locale=#{menuparticipant&.preferredlocale.inspect} " \
      "restaurant_default_locale=#{restaurant.defaultLocale&.locale.inspect} " \
      "render_locale=#{render_locale.inspect}"
    )

    partials = I18n.with_locale(render_locale) do
      {
        context: compress_string(
          ApplicationController.renderer.render(
            partial: 'smartmenus/showContext',
            locals: {
              order: ordr,
              menu: menu,
              restaurant: restaurant,
              ordrparticipant: ordrparticipant,
              tablesetting: tablesetting,
              menuparticipant: menuparticipant,
              current_employee: @current_employee,
            },
          ),
        ),
        modals: compress_string(
          ApplicationController.renderer.render(
            partial: 'smartmenus/showModals',
            locals: {
              order: ordr,
              menu: menu,
              restaurant: restaurant,
              ordrparticipant: ordrparticipant,
              tablesetting: tablesetting,
              menuparticipant: menuparticipant,
              restaurantCurrency: restaurant_currency,
              current_employee: @current_employee,
            },
          ),
        ),
        menuContentStaff: compress_string(
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
          ),
        ),
        menuContentCustomer: compress_string(
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentCustomer',
            locals: {
              order: ordr,
              menu: menu,
              allergyns: allergyns,
              restaurantCurrency: restaurant_currency,
              ordrparticipant: customer_ordrparticipant,
              menuparticipant: menuparticipant,
              tablesetting: tablesetting,
            },
          ),
        ),
        orderCustomer: compress_string(
          ApplicationController.renderer.render(
            partial: 'smartmenus/orderCustomer',
            locals: {
              order: ordr,
              menu: menu,
              restaurant: restaurant,
              tablesetting: tablesetting,
              ordrparticipant: customer_ordrparticipant,
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
              ordrparticipant: customer_ordrparticipant,
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
