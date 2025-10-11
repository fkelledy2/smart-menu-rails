class RestaurantlocalesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurantlocale, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET	/restaurants/:restaurant_id/menus
  # GET /menus or /menus.json
  def index
    if params[:restaurant_id]
      @restaurant = Restaurant.find_by(id: params[:restaurant_id])
      @restaurantlocales = policy_scope(Restaurantlocale).where(restaurant_id: @restaurant.id).order(:locale)
    else
      @restaurantlocales = policy_scope(Restaurantlocale).where(archived: false).order(:locale)
    end
  end

  # GET	/restaurants/:restaurant_id/restaurantlocales/:menu_id/tablesettings/:id(.:format)	restaurantlocales#show
  # GET	/restaurants/:restaurant_id/restaurantlocales/:id(.:format)	 restaurantlocales#show
  # GET /restaurantlocales/1 or /restaurantlocales/1.json
  def show
    authorize @restaurantlocale
  end

  # GET /menus/new
  def new
    @restaurantlocale = Restaurantlocale.new
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @restaurantlocale.restaurant = @futureParentRestaurant
    end
    authorize @restaurantlocale
  end

  # GET /restaurantlocales/1/edit
  def edit
    authorize @restaurantlocale
  end

  # POST /restaurantlocales or /restaurantlocales.json
  def create
    @restaurantlocale = Restaurantlocale.new(restaurantlocale_params)
    authorize @restaurantlocale
    respond_to do |format|
      if @restaurantlocale.save
        if @restaurantlocale.dfault == true
          Restaurantlocale.where(restaurant_id: @restaurantlocale.restaurant_id).find_each do |rl|
            if rl.id != @restaurantlocale.id
              rl.dfault = false
              rl.save
            end
          end
        end
        TranslateMenuJob.perform_async(@restaurantlocale.id)
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id),
                      notice: t('restaurantlocales.controller.created')
        end
        format.json { render :show, status: :created, location: @restaurantlocale }
      else
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /restaurantlocales/1 or / restaurantlocales/1.json
  def update
    authorize @restaurantlocale
    respond_to do |format|
      Restaurantlocale.where(restaurant_id: @restaurantlocale.restaurant_id).find_each do |rl|
        if rl.id != @restaurantlocale.id
          rl.dfault = false
          rl.save
        end
      end
      if @restaurantlocale.update(restaurantlocale_params)
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id),
                      notice: t('restaurantlocales.controller.updated')
        end
        format.json { render :show, status: :ok, location: @restaurantlocale }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /restaurantlocales/1 or /restaurantlocales/1.json
  def destroy
    authorize @restaurantlocale

    if @restaurantlocale.inactive?
      @restaurantlocale.destroy!
      respond_to do |format|
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id),
                      notice: t('restaurantlocales.controller.deleted')
        end
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantlocale.restaurant.id),
                      notice: t('restaurantlocales.controller.active_not_deleted')
        end
        format.json { head :no_content }
      end
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
