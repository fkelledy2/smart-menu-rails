class MenusController < ApplicationController
  before_action :set_menu, only: %i[ show edit update destroy ]

  # GET /menus or /menus.json
  def index
    @menus = Menu.order('sequence ASC').all
  end

  # GET /menus/1 or /menus/1.json
  def show
    if params[:menu_id] && params[:id]
        # This means we are coming from QR code scan.
        @tablesetting = Tablesetting.find_by_id(params[:id])
        @openOrder = Ordr.where( menu_id: params[:menu_id], tablesetting_id: params[:id], restaurant_id: @tablesetting.restaurant_id, status: 0).first
        # IF we have an openOrder then start tracking session interactions with that open order.
            @ordrparticipant = Ordrparticipant.new
            @ordrparticipant.ordr = @openOrder
            @ordrparticipant.sessionid = session.id
            if current_user
                @ordrparticipant.employee = @current_employee
                @ordrparticipant.role = 1
            else
                @ordrparticipant.role = 0
            end
            @ordrparticipant.action = 0
            @ordrparticipant.save
        cookies["test_cookie2"] = {
            :value => session.id,
            :expires => 1.year.from_now,
            :domain => 'smartmenu.com'
        }
        @cookie_value = cookies["test_cookie2"]
    end
  end

  # GET /menus/new
  def new
    @menu = Menu.new
  end

  # GET /menus/1/edit
  def edit
  end

  # POST /menus or /menus.json
  def create
    @menu = Menu.new(menu_params)

    respond_to do |format|
      if @menu.save
        format.html { redirect_to menu_url(@menu), notice: "Menu was successfully created." }
        format.json { render :show, status: :created, location: @menu }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menus/1 or /menus/1.json
  def update
    respond_to do |format|
      if @menu.update(menu_params)
        format.html { redirect_to menu_url(@menu), notice: "Menu was successfully updated." }
        format.json { render :show, status: :ok, location: @menu }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menus/1 or /menus/1.json
  def destroy
    @menu.destroy!

    respond_to do |format|
      format.html { redirect_to menus_url, notice: "Menu was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menu
    if params[:menu_id]
        @menu = Menu.find(params[:menu_id])
    else
        @menu = Menu.find(params[:id])
    end
    end

    # Only allow a list of trusted parameters through.
    def menu_params
      params.require(:menu).permit(:name, :description, :image, :status, :sequence, :restaurant_id)
    end
end
