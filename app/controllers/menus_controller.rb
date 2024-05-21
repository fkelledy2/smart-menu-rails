class MenusController < ApplicationController
  before_action :set_menu, only: %i[ show edit update destroy ]

  # GET	/restaurants/:restaurant_id/menus
  # GET /menus or /menus.json
  def index
    @today = Date.today.strftime('%A').downcase!
    @currentHour = Time.now.strftime("%H").to_i
    @currentMin = Time.now.strftime("%M").to_i

    if current_user
        if params[:restaurant_id]
            @restaurant = Restaurant.find_by_id(params[:restaurant_id])
            @menus = Menu.joins(:restaurant).where(restaurant: {user: current_user}, restaurant_id: @restaurant.id).order('sequence ASC').all
        else
            @menus = Menu.joins(:restaurant).where(restaurant: {user: current_user}).order('sequence ASC').all
        end
    else
        if params[:restaurant_id]
            puts params[:restaurant_id]
            @restaurant = Restaurant.find_by_id(params[:restaurant_id])
            @menus = Menu.where( restaurant: @restaurant).all
            @tablesettings = @restaurant.tablesettings
        end
    end
  end

  # GET	/restaurants/:restaurant_id/menus/:menu_id/tablesettings/:id(.:format)	menus#show
  # GET	/restaurants/:restaurant_id/menus/:id(.:format)	 menus#show
  # GET /menus/1 or /menus/1.json
  def show
    @allergyns = Allergyn.all
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
        @openOrder = Ordr.where( menu_id: params[:menu_id], tablesetting_id: params[:id], restaurant_id: @tablesetting.restaurant_id, status: 0)
                     .or(Ordr.where( menu_id: params[:menu_id], tablesetting_id: params[:id], restaurant_id: @tablesetting.restaurant_id, status: 20))
                     .or(Ordr.where( menu_id: params[:menu_id], tablesetting_id: params[:id], restaurant_id: @tablesetting.restaurant_id, status: 30)).first
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
                @ep = Ordrparticipant.where( ordr: @openOrder, employee: @current_employee, role: 1, sessionid: session.id.to_s ).first
                if @ep == nil
                    @ordrparticipant = Ordrparticipant.new( ordr: @openOrder, employee: @current_employee, role: 1, sessionid: session.id.to_s);
                    @ordrparticipant.save
                else
                end
            else
                @ep = Ordrparticipant.where( ordr_id: @openOrder.id, role: 0, sessionid: session.id.to_s ).first
                if @ep == nil
                    @ordrparticipant = Ordrparticipant.new( ordr_id: @openOrder.id, role: 0, sessionid: session.id.to_s);
                    @ordrparticipant.save
                    @ordraction = Ordraction.new( ordrparticipant_id: @ordrparticipant.id, ordr: @openOrder, action: 0)
                    @ordraction.save
                else
                    @ordrparticipant = @ep
                    @ordraction = Ordraction.new( ordrparticipant: @ep, ordr: @openOrder, action: 0)
                    @ordraction.save
                end
            end
        end
    end
  end

  # GET /menus/new
  def new
    if current_user
        @menu = Menu.new
        if params[:restaurant_id]
            @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
            @menu.restaurant = @futureParentRestaurant
        end
    else
        redirect_to root_url
    end
  end

  # GET /menus/1/edit
  def edit
  end

  # POST /menus or /menus.json
  def create
    @menu = Menu.new(menu_params)
    respond_to do |format|
      if @menu.save
        format.html { redirect_to edit_restaurant_path(id: @menu.restaurant.id), notice: "Menu was successfully created." }
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
        format.html { redirect_to edit_restaurant_path(id: @menu.restaurant.id), notice: "Menu was successfully deleted." }
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
      format.html { redirect_to edit_restaurant_path(id: @menu.restaurant.id), notice: "Menu was successfully deleted." }
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
            if @menu.restaurant.currency
                @restaurantCurrency = ISO4217::Currency.from_code(@menu.restaurant.currency)
            else
                @restaurantCurrency = ISO4217::Currency.from_code('USD')
            end
        rescue ActiveRecord::RecordNotFound => e
            redirect_to root_url
        end
    end

    # Only allow a list of trusted parameters through.
    def menu_params
      params.require(:menu).permit(:name, :description, :image, :status, :sequence, :restaurant_id, :displayImages, :allowOrdering, :inventoryTracking)
    end
end
