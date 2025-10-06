class RestaurantavailabilitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurantavailability, only: %i[show edit update destroy]
  
  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /restaurantavailabilities or /restaurantavailabilities.json
  def index
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @restaurantavailabilities = policy_scope(Restaurantavailability).where(restaurant: @futureParentRestaurant)
    else
      @restaurantavailabilities = policy_scope(Restaurantavailability)
    end
  end

  # GET /restaurantavailabilities/1 or /restaurantavailabilities/1.json
  def show
    authorize @restaurantavailability
  end

  # GET /restaurantavailabilities/new
  def new
    @restaurantavailability = Restaurantavailability.new
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @restaurantavailability.restaurant = @futureParentRestaurant
    end
    authorize @restaurantavailability
  end

  # GET /restaurantavailabilities/1/edit
  def edit
    authorize @restaurantavailability
  end

  # POST /restaurantavailabilities or /restaurantavailabilities.json
  def create
    @restaurantavailability = Restaurantavailability.new(restaurantavailability_params)
    authorize @restaurantavailability
    
    respond_to do |format|
      if @restaurantavailability.save
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantavailability.restaurant.id),
                      notice: t('common.flash.created', resource: t('activerecord.models.restaurantavailability'))
        end
        format.json { render :show, status: :created, location: @restaurantavailability }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @restaurantavailability.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /restaurantavailabilities/1 or /restaurantavailabilities/1.json
  def update
    authorize @restaurantavailability
    
    respond_to do |format|
      if @restaurantavailability.update(restaurantavailability_params)
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantavailability.restaurant.id),
                      notice: t('common.flash.updated', resource: t('activerecord.models.restaurantavailability'))
        end
        format.json { render :show, status: :ok, location: @restaurantavailability }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @restaurantavailability.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /restaurantavailabilities/1 or /restaurantavailabilities/1.json
  def destroy
    authorize @restaurantavailability
    
    @restaurantavailability.update(archived: true)
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_path(id: @restaurantavailability.restaurant.id),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.restaurantavailability'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_restaurantavailability
    @restaurantavailability = Restaurantavailability.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def restaurantavailability_params
    params.require(:restaurantavailability).permit(:dayofweek, :starthour, :startmin, :endhour, :endmin, :status,
                                                   :sequence, :restaurant_id,)
  end
end
