class RestaurantsController < ApplicationController
  before_action :set_restaurant, only: %i[ show edit update destroy ]
  before_action :set_currency, only: %i[ show index ]

  # GET /restaurants or /restaurants.json
  def index
    if current_user
        @restaurants = Restaurant.where( user: current_user, archived: false)
    else
        redirect_to root_url
    end
  end

  # GET /restaurants/1 or /restaurants/1.json
  def show
    if current_user
        if params[:restaurant_id] && params[:id]
        end
    else
        redirect_to root_url
    end
  end

  # GET /restaurants/new
  def new
    if current_user
        @restaurant = Restaurant.new
    else
        redirect_to root_url
    end
  end

  # GET /restaurants/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /restaurants or /restaurants.json
  def create
    if current_user
        @restaurant = Restaurant.new(restaurant_params)
        respond_to do |format|
          if @restaurant.save
            format.html { redirect_to restaurants_path, notice: "Restaurant was successfully updated." }
            format.json { render :show, status: :created, location: @restaurant }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @restaurant.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /restaurants/1 or /restaurants/1.json
  def update
    puts 'xxx'
    puts params[:image]
    puts params[:image_data]
    if current_user
        respond_to do |format|

          if @restaurant.update(restaurant_params)
            format.html { redirect_to restaurants_path(@restaurant), notice: "Restaurant was successfully updated." }
            format.json { render :show, status: :ok, location: @restaurant }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @restaurant.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /restaurants/1 or /restaurants/1.json
  def destroy
    if current_user
        @restaurant.update( archived: true )
        respond_to do |format|
          format.html { redirect_to restaurants_url, notice: "Restaurant was successfully destroyed." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
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

    def set_currency
      if params[:id]
          @restaurant = Restaurant.find(params[:id])
          if @restaurant.currency
            @restaurantCurrency = ISO4217::Currency.from_code(@restaurant.currency)
          else
            @restaurantCurrency = ISO4217::Currency.from_code('USD')
          end
      else
        @restaurantCurrency = ISO4217::Currency.from_code('USD')
      end
    end

    # Only allow a list of trusted parameters through.
    def restaurant_params
      params.require(:restaurant).permit(:name, :description, :address1, :address2, :state, :city, :postcode, :country, :image_data, :image, :status, :sequence, :capacity, :user_id, :displayImages, :allowOrdering, :inventoryTracking, :currency, :genid, :latitude, :longitude)
    end
end
