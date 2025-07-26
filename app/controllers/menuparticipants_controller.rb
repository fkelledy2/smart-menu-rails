class MenuparticipantsController < ApplicationController
  before_action :set_menuparticipant, only: %i[ show edit update destroy ]

  # GET /menuparticipants or /menuparticipants.json
  def index
    @menuparticipants = Menuparticipant.limit(100) # Use limit for memory safety, since pagination gem is not installed
  end

  # GET /menuparticipants/1 or /menuparticipants/1.json
  def show
  end

  # GET /menuparticipants/new
  def new
    @menuparticipant = Menuparticipant.new
  end

  # GET /menuparticipants/1/edit
  def edit
  end

  # POST /menuparticipants or /menuparticipants.json
  def create
    @menuparticipant = Menuparticipant.new(menuparticipant_params)

    respond_to do |format|
      if @menuparticipant.save
        broadcastPartials()
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
    respond_to do |format|
      if @menuparticipant.update(menuparticipant_params)
        @menuparticipant.smartmenu = Smartmenu.find(params[:menuparticipant][:smartmenu_id]) if params[:menuparticipant][:smartmenu_id]
        @menuparticipant.save
        broadcastPartials()
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
      format.html { redirect_to menuparticipants_path, status: :see_other, notice: "Menuparticipant was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def broadcastPartials()
      menuparticipant = Menuparticipant.includes(smartmenu: [:menu, { restaurant: [:menusections, :menuavailabilities] }, :tablesetting]).find_by(sessionid: session.id.to_s)
      smartmenu = menuparticipant.smartmenu
      menu = smartmenu.menu
      restaurant = smartmenu.restaurant
      tablesetting = smartmenu.tablesetting
      restaurantCurrency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')
      allergyns = Allergyn.where(restaurant_id: restaurant.id)
      fullRefresh = false

      require 'zlib'
      require 'base64'
      
      def compress_string(str)
        Base64.strict_encode64(Zlib::Deflate.deflate(str))
      end
      
      partials = {
        context: compress_string(ApplicationController.renderer.render(
          partial: 'smartmenus/showContext',
          locals: { order: nil, menu: menu, ordrparticipant: nil, tablesetting: tablesetting, menuparticipant: menuparticipant, current_employee: @current_employee }
        )),
        modals: compress_string(Rails.cache.fetch([:show_modals, menu.try(:cache_key_with_version), tablesetting.try(:id), menuparticipant.try(:id), restaurantCurrency.code, @current_employee.try(:id)]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showModals',
            locals: { order: nil, menu: menu, ordrparticipant: nil, tablesetting: tablesetting, menuparticipant: menuparticipant, restaurantCurrency: restaurantCurrency, current_employee: @current_employee }
          )
        end),
        menuContentStaff: compress_string(Rails.cache.fetch([:menu_content_staff, menu.try(:cache_key_with_version), allergyns.maximum(:updated_at), restaurantCurrency.code, menuparticipant.try(:id)]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentStaff',
            locals: { order: nil, menu: menu, allergyns: allergyns, restaurantCurrency: restaurantCurrency, ordrparticipant: nil, menuparticipant: menuparticipant }
          )
        end),
        menuContentCustomer: compress_string(Rails.cache.fetch([:menu_content_customer, menu.try(:cache_key_with_version), allergyns.maximum(:updated_at), restaurantCurrency.code, menuparticipant.try(:id)]) do
          ApplicationController.renderer.render(
            partial: 'smartmenus/showMenuContentCustomer',
            locals: { order: nil, menu: menu, allergyns: allergyns, restaurantCurrency: restaurantCurrency, ordrparticipant: nil, menuparticipant: menuparticipant }
          )
        end),
        orderCustomer: compress_string(ApplicationController.renderer.render(
          partial: 'smartmenus/orderCustomer',
          locals: { order: nil, menu: menu, restaurant: restaurant, tablesetting: tablesetting, ordrparticipant: nil }
        )),
        orderStaff: compress_string(ApplicationController.renderer.render(
          partial: 'smartmenus/orderStaff',
          locals: { order: nil, menu: menu, restaurant: restaurant, tablesetting: tablesetting, ordrparticipant: nil }
        )),
        tableLocaleSelectorStaff: compress_string(ApplicationController.renderer.render(
          partial: 'smartmenus/showTableLocaleSelectorStaff',
          locals: { menu: menu, restaurant: restaurant, tablesetting: tablesetting, ordrparticipant: nil, menuparticipant: menuparticipant }
        )),
        tableLocaleSelectorCustomer: compress_string(ApplicationController.renderer.render(
          partial: 'smartmenus/showTableLocaleSelectorCustomer',
          locals: { menu: menu, restaurant: restaurant, tablesetting: tablesetting, ordrparticipant: nil, menuparticipant: menuparticipant }
        )),
        fullPageRefresh: { refresh: fullRefresh }
      }
      ActionCable.server.broadcast("ordr_#{smartmenu.slug}_channel", partials)
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
