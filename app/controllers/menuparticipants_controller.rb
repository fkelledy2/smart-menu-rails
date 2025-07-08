class MenuparticipantsController < ApplicationController
  before_action :set_menuparticipant, only: %i[ show edit update destroy ]

  # GET /menuparticipants or /menuparticipants.json
  def index
    @menuparticipants = Menuparticipant.all
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
        format.html { redirect_to @menuparticipant, notice: "Menuparticipant was successfully updated." }
        format.json { render :show, status: :ok, location: @menuparticipant }
      else
        @smartmenus = Smartmenu.all
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
        menuparticipant = Menuparticipant.where( sessionid: session.id.to_s ).first
        if menuparticipant.smartmenu.restaurant.currency
            restaurantCurrency = ISO4217::Currency.from_code(ordr.menu.restaurant.currency)
        else
            restaurantCurrency = ISO4217::Currency.from_code('USD')
        end
        allergyns = Allergyn.where( restaurant_id: menuparticipant.smartmenu.restaurant.id )
        fullRefresh = false
        partials = {
            context: ApplicationController.renderer.render(
                partial: 'smartmenus/showContext',
                locals: { order: nil, menu: menuparticipant.smartmenu.menu, ordrparticipant: nil, tablesetting: menuparticipant.smartmenu.tablesetting, menuparticipant: menuparticipant, current_employee: @current_employee }
            ),
            modals: ApplicationController.renderer.render(
                partial: 'smartmenus/showModals',
                locals: { order: nil, menu: menuparticipant.smartmenu.menu, ordrparticipant: nil, tablesetting: menuparticipant.smartmenu.tablesetting, menuparticipant: menuparticipant, restaurantCurrency: restaurantCurrency, current_employee: @current_employee }
            ),
            menuContentStaff: ApplicationController.renderer.render(
                partial: 'smartmenus/showMenuContentStaff',
                locals: { order: nil, menu: menuparticipant.smartmenu.menu, allergyns: allergyns, restaurantCurrency: restaurantCurrency, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
            ),
            menuContentCustomer: ApplicationController.renderer.render(
                partial: 'smartmenus/showMenuContentCustomer',
                locals: { order: nil, menu: menuparticipant.smartmenu.menu, allergyns: allergyns, restaurantCurrency: restaurantCurrency, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant }
            ),
            orderCustomer: ApplicationController.renderer.render(
                partial: 'smartmenus/orderCustomer',
                locals: { order: nil, menu: menuparticipant.smartmenu.menu, restaurant: menuparticipant.smartmenu.restaurant, tablesetting: menuparticipant.smartmenu.tablesetting, ordrparticipant: nil }
            ),
            orderStaff: ApplicationController.renderer.render(
                partial: 'smartmenus/orderStaff',
                locals: { order: nil, menu: menuparticipant.smartmenu.menu, restaurant: menuparticipant.smartmenu.restaurant, tablesetting: menuparticipant.smartmenu.tablesetting, ordrparticipant: nil }
            ),
            tableLocaleSelectorStaff: ApplicationController.renderer.render(
                partial: 'smartmenus/showTableLocaleSelectorStaff',
                locals: { menu: menuparticipant.smartmenu.menu, restaurant: menuparticipant.smartmenu.restaurant, tablesetting: menuparticipant.smartmenu.tablesetting, ordrparticipant: nil, menuparticipant: menuparticipant }
            ),
            tableLocaleSelectorCustomer: ApplicationController.renderer.render(
                partial: 'smartmenus/showTableLocaleSelectorCustomer',
                locals: { menu: menuparticipant.smartmenu.menu, restaurant: menuparticipant.smartmenu.restaurant, tablesetting: menuparticipant.smartmenu.tablesetting, ordrparticipant: nil, menuparticipant: menuparticipant }
            ),
            fullPageRefresh: { refresh: fullRefresh }
        }
        ActionCable.server.broadcast("ordr_"+menuparticipant.smartmenu.slug+"_channel", partials)
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
