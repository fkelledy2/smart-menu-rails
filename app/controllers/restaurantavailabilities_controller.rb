class RestaurantavailabilitiesController < ApplicationController
  before_action :set_restaurantavailability, only: %i[ show edit update destroy ]

  # GET /restaurantavailabilities or /restaurantavailabilities.json
  def index
    @restaurantavailabilities = Restaurantavailability.joins(:restaurant).where(restaurant: {user: current_user}).all
  end

  # GET /restaurantavailabilities/1 or /restaurantavailabilities/1.json
  def show
  end

  # GET /restaurantavailabilities/new
  def new
    @restaurantavailability = Restaurantavailability.new
  end

  # GET /restaurantavailabilities/1/edit
  def edit
  end

  # POST /restaurantavailabilities or /restaurantavailabilities.json
  def create
    @restaurantavailability = Restaurantavailability.new(restaurantavailability_params)

    respond_to do |format|
      if @restaurantavailability.save
        format.html { redirect_to restaurantavailability_url(@restaurantavailability), notice: "Restaurantavailability was successfully created." }
        format.json { render :show, status: :created, location: @restaurantavailability }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @restaurantavailability.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /restaurantavailabilities/1 or /restaurantavailabilities/1.json
  def update
    respond_to do |format|
      if @restaurantavailability.update(restaurantavailability_params)
        format.html { redirect_to restaurantavailability_url(@restaurantavailability), notice: "Restaurantavailability was successfully updated." }
        format.json { render :show, status: :ok, location: @restaurantavailability }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @restaurantavailability.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /restaurantavailabilities/1 or /restaurantavailabilities/1.json
  def destroy
    @restaurantavailability.destroy!

    respond_to do |format|
      format.html { redirect_to restaurantavailabilities_url, notice: "Restaurantavailability was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_restaurantavailability
        begin
            if current_user
                @restaurantavailability = Restaurantavailability.find(params[:id])
                if( @restaurantavailability == nil or @restaurantavailability.restaurant.user != current_user )
                    redirect_to home_url
                end
            else
                redirect_to root_url
            end
        rescue ActiveRecord::RecordNotFound => e
            redirect_to root_url
        end
    end

    # Only allow a list of trusted parameters through.
    def restaurantavailability_params
      params.require(:restaurantavailability).permit(:dayofweek, :starthour, :startmin, :endhour, :endmin, :status, :sequence, :restaurant_id)
    end
end
