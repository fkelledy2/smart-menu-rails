class RestaurantsController < ApplicationController
  before_action :set_restaurant, only: %i[ show edit update destroy ]

  # GET /restaurants or /restaurants.json
  def index
    if current_user
        @restaurants = Restaurant.where( user: current_user)
    else
        redirect_to root_url
    end
  end

  # GET /restaurants/1 or /restaurants/1.json
  def show
    if params[:restaurant_id] && params[:id]
    end
  end

  # GET /restaurants/new
  def new
    @restaurant = Restaurant.new
  end

  # GET /restaurants/1/edit
  def edit
  end

  # POST /restaurants or /restaurants.json
  def create
    @restaurant = Restaurant.new(restaurant_params)

    respond_to do |format|
      if @restaurant.save
        format.html { redirect_to restaurant_url(@restaurant), notice: "Restaurant was successfully created." }
        format.json { render :show, status: :created, location: @restaurant }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @restaurant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /restaurants/1 or /restaurants/1.json
  def update
    respond_to do |format|
      if @restaurant.update(restaurant_params)
        format.html { redirect_to restaurant_url(@restaurant), notice: "Restaurant was successfully updated." }
        format.json { render :show, status: :ok, location: @restaurant }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @restaurant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /restaurants/1 or /restaurants/1.json
  def destroy
    @restaurant.destroy!

    respond_to do |format|
      format.html { redirect_to restaurants_url, notice: "Restaurant was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_restaurant
        begin
            if current_user
                if params[:restaurant_id]
                    @restaurant = Restaurant.find(params[:restaurant_id])
                else
                    @restaurant = Restaurant.find(params[:id])
                end
                if( @restaurant == nil or @restaurant.user != current_user )
                    redirect_to home_url
                end
            else
                if params[:restaurant_id]
                    @restaurant = Restaurant.find(params[:restaurant_id])
                else
                    @restaurant = Restaurant.find(params[:id])
                end
            end
        rescue ActiveRecord::RecordNotFound => e
            redirect_to root_url
        end
    end

    # Only allow a list of trusted parameters through.
    def restaurant_params
      params.require(:restaurant).permit(:name, :description, :address1, :address2, :state, :city, :postcode, :country, :image, :status, :capacity, :user_id, :displayImages, :allowOrdering, :inventoryTracking)
    end
end
