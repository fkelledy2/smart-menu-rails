class MenuitemsController < ApplicationController
  before_action :set_menuitem, only: %i[ show edit update destroy ]
  before_action :set_currency

  # GET /menuitems or /menuitems.json
  def index
    if current_user
      @menuitems = []
      if params[:menusection_id]
        menusection = Menusection.find_by_id(params[:menusection_id])
        @menuitems += Menuitem.where( menusection: menusection, archived: false).all
      end
    else
      redirect_to root_url
    end
  end

  # GET /menuitems/1 or /menuitems/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /menuitems/new
  def new
    if current_user
        @menuitem = Menuitem.new
    else
        redirect_to root_url
    end
  end

  # GET /menuitems/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /menuitems or /menuitems.json
  def create
    if current_user
        @menuitem = Menuitem.new(params.require(:menuitem).permit(:name, :description, :image, :status, :calories, :sequence, :price, :menusection_id, :preptime, allergyn_ids: [], tag_ids: [], size_ids: [], ingredient_ids: []))
        respond_to do |format|
          if @menuitem.save
            if( @menuitem.genimage == nil)
                @genimage = Genimage.new
                @genimage.restaurant = @menuitem.menusection.menu.restaurant
                @genimage.menu = @menuitem.menusection.menu
                @genimage.menusection = @menuitem.menusection
                @genimage.menuitem = @menuitem
                @genimage.created_at = DateTime.current
                @genimage.updated_at = DateTime.current
                @genimage.save
            end
            format.html { redirect_to edit_menusection_url(@menuitem.menusection), notice: "Menuitem was successfully created." }
            format.json { render :show, status: :created, location: @menuitem }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @menuitem.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /menuitems/1 or /menuitems/1.json
  def update
    if current_user
        respond_to do |format|
          @menuitem = Menuitem.find(params[:id])
          if @menuitem.update(params.require(:menuitem).permit(:name, :description, :image, :status, :calories, :sequence, :price, :menusection_id, :preptime, allergyn_ids: [], tag_ids: [], size_ids: [], ingredient_ids: []))
            if( @menuitem.genimage == nil)
                @genimage = Genimage.new
                @genimage.restaurant = @menuitem.menusection.menu.restaurant
                @genimage.menu = @menuitem.menusection.menu
                @genimage.menusection = @menuitem.menusection
                @genimage.menuitem = @menuitem
                @genimage.created_at = DateTime.current
                @genimage.updated_at = DateTime.current
                @genimage.save
            end
            format.html { redirect_to edit_menusection_path(@menuitem.menusection), notice: "Menuitem was successfully updated." }
            format.json { render :show, status: :ok, location: @menuitem }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @menuitem.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /menuitems/1 or /menuitems/1.json
  def destroy
    if current_user
        @menuitem.update( archived: true )
        respond_to do |format|
          format.html { redirect_to edit_menusection_path(@menuitem.menusection), notice: "Menuitem was successfully deleted." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menuitem
        begin
            if current_user
                @menuitem = Menuitem.find(params[:id])
                if( @menuitem == nil or @menuitem.menusection.menu.restaurant.user != current_user )
                    redirect_to root_url
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
          if @menuitem.menusection.menu.restaurant.currency
            @restaurantCurrency = ISO4217::Currency.from_code(@menuitem.menusection.menu.restaurant.currency)
          else
            @restaurantCurrency = ISO4217::Currency.from_code('USD')
          end
      else
        @restaurantCurrency = ISO4217::Currency.from_code('USD')
      end
    end

    # Only allow a list of trusted parameters through.
    def menuitem_params
      params.require(:menuitem).permit(:name, :description, :image, :remove_image, :status, :sequence, :calories, :price, :menusection_id, :preptime)
    end
end
