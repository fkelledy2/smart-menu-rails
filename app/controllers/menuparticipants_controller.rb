class MenuparticipantsController < ApplicationController
  # Allow customers to interact with menus without authentication
  before_action :set_menuparticipant, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /menuparticipants or /menuparticipants.json
  def index
    @menuparticipants = if current_user
                          policy_scope(Menuparticipant).limit(100)
                        else
                          Menuparticipant.limit(100)
                        end
  end

  # GET /menuparticipants/1 or /menuparticipants/1.json
  def show
    authorize @menuparticipant if current_user
  end

  # GET /menuparticipants/new
  def new
    @menuparticipant = Menuparticipant.new
    authorize @menuparticipant if current_user
  end

  # GET /menuparticipants/1/edit
  def edit
    authorize @menuparticipant if current_user
  end

  # POST /menuparticipants or /menuparticipants.json
  def create
    @menuparticipant = Menuparticipant.new(menuparticipant_params)
    authorize @menuparticipant if current_user

    respond_to do |format|
      if @menuparticipant.save
        broadcastPartials
        format.json { render :show, status: :created, location: @menuparticipant }
      else
        @smartmenus = Smartmenu.all
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menuparticipant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menuparticipants/1 or /menuparticipants/1.json
  def update
    authorize @menuparticipant if current_user

    respond_to do |format|
      if @menuparticipant.update(menuparticipant_params)
        @menuparticipant.smartmenu = Smartmenu.find(params[:menuparticipant][:smartmenu_id]) if params[:menuparticipant][:smartmenu_id]
        @menuparticipant.save
        broadcastPartials
        #         format.html { redirect_to @menuparticipant, notice: "Menuparticipant was successfully updated." }
        format.json { render :show, status: :ok, location: @menuparticipant }
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
        redirect_to menuparticipants_path, status: :see_other, notice: 'Menuparticipant was successfully destroyed.'
      end
      format.json { head :no_content }
    end
  end

  private

  def broadcastPartials
    menuparticipant = Menuparticipant.includes(smartmenu: [:menu,
                                                           { restaurant: %i[menusections menuavailabilities] }, :tablesetting,]).find_by(sessionid: session.id.to_s)
    smartmenu = menuparticipant.smartmenu
    menu = smartmenu.menu
    restaurant = smartmenu.restaurant
    tablesetting = smartmenu.tablesetting
    restaurant_currency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
    allergyns = Allergyn.where(restaurant_id: restaurant.id)
    full_refresh = false

    partials = {
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
    ActionCable.server.broadcast("ordr_#{smartmenu.slug}_channel", partials)
  end

  # Helper for compressing partials
  def compress_string(str)
    require 'zlib'
    require 'base64'
    Base64.strict_encode64(Zlib::Deflate.deflate(str))
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_menuparticipant
    @menuparticipant = Menuparticipant.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def menuparticipant_params
    params.require(:menuparticipant).permit(:sessionid, :preferredlocale, :smartmenu_id)
  end
end
