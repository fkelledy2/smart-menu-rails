class SmartmenusController < ApplicationController
  layout "smartmenu", :only => [ :show ]
  before_action :set_smartmenu, only: %i[ show edit update destroy ]

  # GET /smartmenus or /smartmenus.json
  def index
    @smartmenus = Smartmenu
        .includes(:menu, :restaurant, :tablesetting)
        .joins(:menu)
        .where(tablesetting_id: nil, menus: { status: 'active' })
        .limit(100)
  end

  # GET /smartmenus/1 or /smartmenus/1.json
  def show
    if @menu.restaurant != @restaurant
      redirect_to root_url and return
    end

    # Eager load associations if used in view (add more as needed)
    @menu = Menu.includes(:menusections, :menuavailabilities).find(@menu.id) if @menu && !@menu.association(:menusections).loaded?

    @allergyns = Allergyn.where(restaurant_id: @menu.restaurant_id)

    if @tablesetting
      @openOrder = Ordr.where(
        menu_id: @menu.id,
        tablesetting_id: @tablesetting.id,
        restaurant_id: @tablesetting.restaurant_id,
        status: [0, 20, 30]
      ).first

      if @openOrder
        if current_user
          @ordrparticipant = Ordrparticipant.find_or_create_by(
            ordr: @openOrder,
            employee: @current_employee,
            role: 1,
            sessionid: session.id.to_s
          )
        else
          @ordrparticipant = Ordrparticipant.find_or_create_by(
            ordr_id: @openOrder.id,
            role: 0,
            sessionid: session.id.to_s
          )
          @menuparticipant = Menuparticipant.find_by(sessionid: session.id.to_s)
          if @menuparticipant
            @ordrparticipant.update(preferredlocale: @menuparticipant.preferredlocale)
          end
          Ordraction.create(ordrparticipant: @ordrparticipant, ordr: @openOrder, action: 0)
        end
      end
    end

    @menuparticipant = Menuparticipant.find_or_create_by(sessionid: session.id.to_s) do |mp|
      mp.smartmenu = @smartmenu
    end
    @menuparticipant.update(smartmenu: @smartmenu) unless @menuparticipant.smartmenu == @smartmenu
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
          @smartmenu = Smartmenu.where(slug: params[:id]).includes(
            :restaurant,
            :tablesetting,
            menu: [
              :menusections,
              { menuitems: [:menuitemlocales, :tags, :sizes, :ingredients, :allergyns, :genimage, :inventory] },
            ]
          ).first                     
          if @smartmenu
              @restaurant = @smartmenu.restaurant
              @menu = @smartmenu.menu
              @tablesetting = @smartmenu.tablesetting
              if current_user
                    if( @menu == nil or @menu.restaurant.user != current_user )
                        redirect_to root_url
                    end
              end
              if @restaurant.currency
                    @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency)
              else
                    @restaurantCurrency = ISO4217::Currency.from_code('USD')
              end
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
