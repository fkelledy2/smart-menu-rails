class OrdrparticipantsController < ApplicationController
  before_action :authenticate_user!, except: [:update]  # Allow unauthenticated updates for smart menu
  before_action :set_restaurant, except: [:update]  # Allow direct updates without restaurant context
  before_action :set_ordrparticipant, only: %i[show edit update destroy]
  before_action :set_ordrparticipant_for_direct_update, only: [:update], if: -> { params[:restaurant_id].blank? }
  
  # Pundit authorization
  after_action :verify_authorized, except: [:index, :update]  # Skip authorization for direct updates
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
        format.json { render :show, status: :ok, location: @ordrparticipant.ordr }
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
        format.json { render :show, status: :ok, location: @ordrparticipant.ordr }
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

    partials = {
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
    ActionCable.server.broadcast("ordr_#{menuparticipant.smartmenu.slug}_channel", partials)
  end

  def compress_string(str)
    require 'zlib'
    require 'base64'
    Base64.strict_encode64(Zlib::Deflate.deflate(str))
  end

  private

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
    params.require(:ordrparticipant).permit(:sessionid, :action, :role, :employee_id, :ordr_id, :ordritem_id, :name,
                                            :preferredlocale, allergyn_ids: [],)
  end
end
