class RestaurantavailabilitiesController < ApplicationController
  before_action :set_restaurantavailability, only: %i[show edit update destroy]

  # GET /restaurantavailabilities or /restaurantavailabilities.json
  def index
    if current_user
      if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @restaurantavailabilities = Restaurantavailability.joins(:restaurant).where(restaurant: @futureParentRestaurant).all
      else
        @restaurantavailabilities = Restaurantavailability.joins(:restaurant).where(restaurant: { user: current_user }).all
      end
    else
      redirect_to root_url
    end
  end

  # GET /restaurantavailabilities/1 or /restaurantavailabilities/1.json
  def show
    unless current_user
      redirect_to root_url
    end
  end

  # GET /restaurantavailabilities/new
  def new
    if current_user
      @restaurantavailability = Restaurantavailability.new
      if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @restaurantavailability.restaurant = @futureParentRestaurant
      end
    else
      redirect_to root_url
    end
  end

  # GET /restaurantavailabilities/1/edit
  def edit
    unless current_user
      redirect_to root_url
    end
  end

  # POST /restaurantavailabilities or /restaurantavailabilities.json
  def create
    if current_user
      @restaurantavailability = Restaurantavailability.new(restaurantavailability_params)
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
    else
      redirect_to root_url
    end
  end

  # PATCH/PUT /restaurantavailabilities/1 or /restaurantavailabilities/1.json
  def update
    if current_user
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
    else
      redirect_to root_url
    end
  end

  # DELETE /restaurantavailabilities/1 or /restaurantavailabilities/1.json
  def destroy
    if current_user
      @restaurantavailability.update(archived: true)
      respond_to do |format|
        format.html do
          redirect_to edit_restaurant_path(id: @restaurantavailability.restaurant.id),
                      notice: t('common.flash.deleted', resource: t('activerecord.models.restaurantavailability'))
        end
        format.json { head :no_content }
      end
    else
      redirect_to root_url
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_restaurantavailability
    if current_user
      @restaurantavailability = Restaurantavailability.find(params[:id])
      if @restaurantavailability.nil? || (@restaurantavailability.restaurant.user != current_user)
        redirect_to root_url
      end
    else
      redirect_to root_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  # Only allow a list of trusted parameters through.
  def restaurantavailability_params
    params.require(:restaurantavailability).permit(:dayofweek, :starthour, :startmin, :endhour, :endmin, :status,
                                                   :sequence, :restaurant_id,)
  end
end
