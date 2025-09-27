class RestaurantlocalesController < ApplicationController
  before_action :set_restaurantlocale, only: %i[ show edit update destroy ]

  # GET	/restaurants/:restaurant_id/menus
  # GET /menus or /menus.json
  def index
    if current_user
        if params[:restaurant_id]
            @restaurant = Restaurant.find_by_id(params[:restaurant_id])
            @restaurantlocales = Restaurantlocale.joins(:restaurant).where(restaurant: {user: current_user}, restaurant_id: @restaurant.id)
            .order('locale ASC').all
        else
            @restaurantlocales = Restaurantlocale.joins(:restaurant).where(restaurant: {user: current_user}, archived: false).order('locale ASC')
            .all
        end
    end
  end

  # GET	/restaurants/:restaurant_id/restaurantlocales/:menu_id/tablesettings/:id(.:format)	restaurantlocales#show
  # GET	/restaurants/:restaurant_id/restaurantlocales/:id(.:format)	 restaurantlocales#show
  # GET /restaurantlocales/1 or /restaurantlocales/1.json
  def show
    if params[:id]
        if params[:restaurant_id]
            @restaurant = Restaurant.find_by_id(params[:restaurant_id])
            @restaurantlocale = Restaurantlocale.find_by_id(params[:id])
            if @restaurantlocale.restaurant != @restaurant
                redirect_to root_url
            end
        end
    else
        @restaurantlocale = Restaurantlocale.find_by_id(params[:id])
    end
  end

  # GET /menus/new
  def new
    if current_user
        @restaurantlocale = Restaurantlocale.new
        if params[:restaurant_id]
            @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
            @restaurantlocale.restaurant = @futureParentRestaurant
        end
    else
        redirect_to root_url
    end
  end

  # GET /restaurantlocales/1/edit
  def edit
    if current_user
        if params[:id]
            if params[:restaurant_id]
                @restaurant = Restaurant.find_by_id(params[:restaurant_id])
                @restaurantlocale = Restaurantlocale.find_by_id(params[:id])
                if @restaurantlocale.restaurant != @restaurant
                    redirect_to root_url
                end
            end
        end
    else
        redirect_to root_url
    end
  end

  # POST /restaurantlocales or /restaurantlocales.json
  def create
    @restaurantlocale = Restaurantlocale.new(restaurantlocale_params)
    respond_to do |format|
      if @restaurantlocale.save
        if @restaurantlocale.dfault == true
          Restaurantlocale.where(restaurant_id: @restaurantlocale.restaurant_id).each do |rl|
              if rl.id != @restaurantlocale.id
                  rl.dfault = false
                  rl.save
              end
          end
        end
        TranslateMenuJob.perform_async(@restaurantlocale.id)
        format.html { redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id), notice: t('restaurantlocales.controller.created') }
        format.json { render :show, status: :created, location: @restaurantlocale }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /restaurantlocale/1 or /restaurantlocale/1.json
  def update
    respond_to do |format|
      Restaurantlocale.where(restaurant_id: @restaurantlocale.restaurant_id).each do |rl|
          if rl.id != @restaurantlocale.id
              rl.dfault = false
              rl.save
          end
      end
      if @restaurantlocale.update(restaurantlocale_params)
        format.html { redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id), notice: t('restaurantlocales.controller.updated') }
        format.json { render :show, status: :ok, location: @restaurantlocale }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /restaurantlocales/1 or /restaurantlocales/1.json
  def destroy
    if current_user
        if @restaurantlocale.inactive?
            @restaurantlocale.destroy!
            respond_to do |format|
              format.html { redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id), notice: t('restaurantlocales.controller.deleted') }
              format.json { head :no_content }
            end
        else
            respond_to do |format|
              format.html { redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id), notice: t('restaurantlocales.controller.active_not_deleted') }
              format.json { head :no_content }
            end
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_restaurantlocale
      @restaurantlocale = Restaurantlocale.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def restaurantlocale_params
      params.require(:restaurantlocale).permit(:locale, :status, :dfault, :restaurant_id)
    end
end
