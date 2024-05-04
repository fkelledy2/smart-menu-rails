class MenuitemsController < ApplicationController
  before_action :set_menuitem, only: %i[ show edit update destroy ]
  before_action :set_currency

  # GET /menuitems or /menuitems.json
  def index
    if current_user
        @menuitems = []
        Restaurant.where( user: current_user).each do |restaurant|
            Menu.where( restaurant: restaurant).each do |menu|
                Menusection.where( menu: menu).each do |menusection|
                    @menuitems += Menuitem.where( menusection: menusection).all
                end
            end
        end
    else
        redirect_to root_url
    end
  end

  # GET /menuitems/1 or /menuitems/1.json
  def show
  end

  # GET /menuitems/new
  def new
    @menuitem = Menuitem.new
  end

  # GET /menuitems/1/edit
  def edit
  end

  # POST /menuitems or /menuitems.json
  def create
    @menuitem = Menuitem.new(params.require(:menuitem).permit(:name, :description, :image, :status, :calories, :sequence, :price, :menusection_id, allergyn_ids: [], tag_ids: [], size_ids: [], ingredient_ids: []))

    respond_to do |format|
      if @menuitem.save
        format.html { redirect_to menuitem_url(@menuitem), notice: "Menuitem was successfully created." }
        format.json { render :show, status: :created, location: @menuitem }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menuitem.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menuitems/1 or /menuitems/1.json
  def update
    respond_to do |format|
      @menuitem = Menuitem.find(params[:id])
      if @menuitem.update(params.require(:menuitem).permit(:name, :description, :image, :status, :calories, :sequence, :price, :menusection_id, allergyn_ids: [], tag_ids: [], size_ids: [], ingredient_ids: []))
        format.html { redirect_to menuitem_url(@menuitem), notice: "Menuitem was successfully updated." }
        format.json { render :show, status: :ok, location: @menuitem }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menuitem.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menuitems/1 or /menuitems/1.json
  def destroy
    @menuitem.destroy!

    respond_to do |format|
      format.html { redirect_to menuitems_url, notice: "Menuitem was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menuitem
        begin
            if current_user
                @menuitem = Menuitem.find(params[:id])
                if( @menuitem == nil or @menuitem.menusection.menu.restaurant.user != current_user )
                    redirect_to home_url
                end
            else
                redirect_to root_url
            end
        rescue ActiveRecord::RecordNotFound => e
            redirect_to root_url
        end
    end
    def set_currency
      if params[:id]
          @menuitem = Menuitem.find(params[:id])
          if @menuitem.menu.restaurant.currency
            @restaurantCurrency = ISO4217::Currency.from_code(@menuitem.menu.restaurant.currency)
          else
            @restaurantCurrency = ISO4217::Currency.from_code('USD')
          end
      else
        @restaurantCurrency = ISO4217::Currency.from_code('USD')
      end
    end

    # Only allow a list of trusted parameters through.
    def menuitem_params
      params.require(:menuitem).permit(:name, :description, :image, :status, :sequence, :calories, :price, :menusection_id)
    end
end
