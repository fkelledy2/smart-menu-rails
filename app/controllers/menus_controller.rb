class MenusController < ApplicationController
  before_action :set_menu, only: %i[ show edit update destroy ]

  # GET	/restaurants/:restaurant_id/menus
  # GET /menus or /menus.json
  def index
    @today = Date.today.wday
    if current_user
        if params[:restaurant_id]
            puts 'aaa'
            puts params[:restaurant_id]
            @restaurant = Restaurant.find_by_id(params[:restaurant_id])
            @menus = Menu.joins(:restaurant).where(restaurant: {user: current_user}, restaurant_id: @restaurant.id).order('sequence ASC').all
        else
            puts 'bbb'
            @menus = Menu.joins(:restaurant).where(restaurant: {user: current_user}).order('sequence ASC').all
        end
    else
        if params[:restaurant_id]
            puts 'ccc'
            puts params[:restaurant_id]
            @restaurant = Restaurant.find_by_id(params[:restaurant_id])
            @menus = Menu.where( restaurant: @restaurant).all
        else
            puts 'ddd'
            @menus = Menu.all
        end
    end
  end

  # GET	/restaurants/:restaurant_id/menus/:menu_id/tablesettings/:id(.:format)	menus#show
  # GET	/restaurants/:restaurant_id/menus/:id(.:format)	 menus#show
  # GET /menus/1 or /menus/1.json
  def show
    if params[:menu_id] && params[:id]
        if params[:restaurant_id]
            @restaurant = Restaurant.find_by_id(params[:restaurant_id])
            @menu = Menu.find_by_id(params[:menu_id])
            if @menu.restaurant != @restaurant
                redirect_to home_url
            end
        end

        @participantsFirstTime = false
        @tablesetting = Tablesetting.find_by_id(params[:id])
        @openOrder = Ordr.where( menu_id: params[:menu_id], tablesetting_id: params[:id], restaurant_id: @tablesetting.restaurant_id, status: 0).first
        if @openOrder
            @openOrder.nett = @openOrder.runningTotal
            taxes = Tax.where(restaurant_id: @openOrder.restaurant.id).order(sequence: :asc)
            totalTax = 0
            totalService = 0
            for tax in taxes do
                if tax.taxtype == 'service'
                    totalService += ((tax.taxpercentage * @openOrder.nett)/100)
                else
                    totalTax += ((tax.taxpercentage * @openOrder.nett)/100)
                end
            end
            @openOrder.tax = totalTax
            @openOrder.service = totalService
            @openOrder.gross = @openOrder.nett + @openOrder.tip + @openOrder.service + @openOrder.tax
            if current_user
                @ordrparticipant = Ordrparticipant.new( ordr_id: @openOrder.id, employee: @current_employee, role: 1, sessionid: session.id.to_s, action: 0 );
                @ordrparticipant.save
            else
                @existingParticipant = Ordrparticipant.where( ordr_id: @openOrder.id, role: 0, sessionid: session.id.to_s ).first
                if @existingParticipant == nil
                    cookies["existingParticipant"] = false
                    @existingParticipant = cookies["existingParticipant"]
                    @ordrparticipant = Ordrparticipant.new( ordr_id: @openOrder.id, role: 0, sessionid: session.id.to_s, action: 0);
                else
                    @existingParticipantName = @existingParticipant.name
                    cookies["existingParticipant"] = true
                    @existingParticipant = cookies["existingParticipant"]
                    @ordrparticipant = Ordrparticipant.new( ordr_id: @openOrder.id, role: 0, sessionid: session.id.to_s, action: 0, name: @existingParticipantName);
                end
                @ordrparticipant.save
            end
        end
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
        begin
            if current_user
                if params[:menu_id]
                    @menu = Menu.find(params[:menu_id])
                else
                    @menu = Menu.find(params[:id])
                end
                if( @menu == nil or @menu.restaurant.user != current_user )
                    redirect_to home_url
                end
            else
                if params[:menu_id]
                    @menu = Menu.find(params[:menu_id])
                else
                    @menu = Menu.find(params[:id])
                end
            end
        rescue ActiveRecord::RecordNotFound => e
            redirect_to root_url
        end
    end

    # Only allow a list of trusted parameters through.
    def menu_params
      params.require(:menu).permit(:name, :description, :image, :status, :sequence, :restaurant_id)
    end
end
