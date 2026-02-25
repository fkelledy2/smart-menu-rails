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
        broadcastState
        format.json do
          render :show, status: :created,
                        location: restaurant_menu_menuparticipant_url(@restaurant, @menu, @menuparticipant)
        end
      else
        @smartmenus = Smartmenu.all
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @menuparticipant.errors, status: :unprocessable_content }
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
        broadcastState
        #         format.html { redirect_to @menuparticipant, notice: "Menuparticipant was successfully updated." }
        format.json do
          render :show, status: :ok, location: restaurant_menu_menuparticipant_url(@restaurant, @menu, @menuparticipant)
        end
      else
        #         @smartmenus = Smartmenu.all
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @menuparticipant.errors, status: :unprocessable_content }
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

  def broadcastState
    menuparticipant = Menuparticipant.includes(smartmenu: %i[menu restaurant tablesetting]).find_by(sessionid: session.id.to_s)
    return unless menuparticipant&.smartmenu

    smartmenu = menuparticipant.smartmenu
    menu = smartmenu.menu
    restaurant = smartmenu.restaurant
    tablesetting = smartmenu.tablesetting

    # Find any open order for this table (locale changes may happen mid-order)
    open_order = if tablesetting
                   Ordr.where(
                     menu_id: menu.id,
                     tablesetting_id: tablesetting.id,
                     restaurant_id: restaurant.id,
                     status: [0, 20, 22, 24, 25, 30],
                   ).first
                 end

    ordrparticipant = if open_order
                        Ordrparticipant.find_by(ordr: open_order, sessionid: session.id.to_s)
                      end

    payload = SmartmenuState.for_context(
      menu: menu,
      restaurant: restaurant,
      tablesetting: tablesetting,
      open_order: open_order,
      ordrparticipant: ordrparticipant,
      menuparticipant: menuparticipant,
      session_id: session.id.to_s,
    )

    ActionCable.server.broadcast("ordr_#{smartmenu.slug}_channel", { state: payload })
  rescue StandardError => e
    Rails.logger.warn("[BroadcastState][Menuparticipants] Broadcast failed: #{e.class}: #{e.message}")
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
