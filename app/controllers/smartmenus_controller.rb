class SmartmenusController < ApplicationController
  before_action :set_smartmenu, only: %i[ show edit update destroy ]

  # GET /smartmenus or /smartmenus.json
  def index
    @smartmenus = Smartmenu.all
  end

  # GET /smartmenus/1 or /smartmenus/1.json
  def show
    @allergyns = Allergyn.where( restaurant_id: @restaurant.id )
    if @menu.restaurant != @restaurant
        redirect_to root_url
    end
#     Analytics.track(
#         event: 'menus.show',
#         properties: {
#             restaurant_id: @menu.restaurant.id,
#             menu_id: @menu.id,
#         }
#     )
    if @tablesetting != nil
        @openOrder = Ordr.where( menu_id: @menu.id, tablesetting_id: @tablesetting.id, restaurant_id: @tablesetting.restaurant.id, status: 0)
                 .or(Ordr.where( menu_id: @menu.id, tablesetting_id: @tablesetting.id, restaurant_id: @tablesetting.restaurant.id, status: 20))
                 .or(Ordr.where( menu_id: @menu.id, tablesetting_id: @tablesetting.id, restaurant_id: @tablesetting.restaurant.id, status: 30)).first
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

  # GET /smartmenus/new
  def new
    @smartmenu = Smartmenu.new
  end

  # GET /smartmenus/1/edit
  def edit
  end

  # POST /smartmenus or /smartmenus.json
  def create
    @smartmenu = Smartmenu.new(smartmenu_params)

    respond_to do |format|
      if @smartmenu.save
        format.html { redirect_to @smartmenu, notice: "Smartmenu was successfully created." }
        format.json { render :show, status: :created, location: @smartmenu }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @smartmenu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /smartmenus/1 or /smartmenus/1.json
  def update
    respond_to do |format|
      if @smartmenu.update(smartmenu_params)
        format.html { redirect_to @smartmenu, notice: "Smartmenu was successfully updated." }
        format.json { render :show, status: :ok, location: @smartmenu }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @smartmenu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /smartmenus/1 or /smartmenus/1.json
  def destroy
    @smartmenu.destroy!

    respond_to do |format|
      format.html { redirect_to smartmenus_path, status: :see_other, notice: "Smartmenu was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_smartmenu
      begin
          @smartmenu = Smartmenu.where( slug: params[:id]).first
          @restaurant = @smartmenu.restaurant
          @menu = @smartmenu.menu
          @tablesetting = @smartmenu.tablesetting

          puts @restaurant.name
          if @menu
          puts @menu.name
          end
          if @tablesetting
          puts @tablesetting.name
          end

          if current_user
                if( @menu == nil or @menu.restaurant.user != current_user )
                    redirect_to root_url
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
    def smartmenu_params
      params.require(:smartmenu).permit(:slug, :restaurant_id, :menu_id, :tablesetting_id)
    end
end
