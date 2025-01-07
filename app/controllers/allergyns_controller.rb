class AllergynsController < ApplicationController
  before_action :set_allergyn, only: %i[ show edit update destroy ]

  # GET /allergyns or /allergyns.json
  def index
    if current_user
        if params[:restaurant_id]
            @restaurant = Restaurant.find_by_id(params[:restaurant_id])
            @allergyns = Allergyn.where( restaurant: @restaurant).all
        end
        Analytics.track(
            user_id: current_user.id,
            event: 'allergyns.index',
            properties: {
              restaurant_id: @restaurant.id,
            }
        )
    else
        if params[:restaurant_id]
            @restaurant = Restaurant.find_by_id(params[:restaurant_id])
            @allergyns = Allergyn.where( restaurant: @restaurant).all
            Analytics.track(
                event: 'allergyns.index',
                properties: {
                  restaurant_id: @restaurant.id,
                }
            )
        end
    end
  end

  # GET /allergyns/1 or /allergyns/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /allergyns/new
  def new
    if current_user
        @allergyn = Allergyn.new
        if params[:restaurant_id]
          @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
          @allergyn.restaurant = @futureParentRestaurant
        end
    else
        redirect_to root_url
    end
  end

  # GET /allergyns/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /allergyns or /allergyns.json
  def create
    if current_user
        puts 'create.allergyn.1'
        @allergyn = Allergyn.new(allergyn_params)
        puts 'create.allergyn.2'
        respond_to do |format|
        puts 'create.allergyn.3'
          if @allergyn.save
        puts 'create.allergyn.4'
            format.html { redirect_to edit_restaurant_path(id: @allergyn.restaurant.id), notice: "Allergyn was successfully created." }
            format.json { render :show, status: :created, location: @allergyn }
          else
        puts 'create.allergyn.5'
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @allergyn.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /allergyns/1 or /allergyns/1.json
  def update
    if current_user
        respond_to do |format|
          if @allergyn.update(allergyn_params)
            format.html { redirect_to edit_restaurant_path(id: @allergyn.restaurant.id), notice: "Allergyn was successfully updated." }
            format.json { render :show, status: :ok, location: @allergyn }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @allergyn.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /allergyns/1 or /allergyns/1.json
  def destroy
    if current_user
        @allergyn.update( archived: true )
        respond_to do |format|
          format.html { redirect_to edit_restaurant_path(id: @allergyn.restaurant.id), notice: "Allergyn was successfully destroyed." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_allergyn
      @allergyn = Allergyn.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def allergyn_params
      params.require(:allergyn).permit(:name, :description, :symbol, :status, :sequence, :restaurant_id)
    end
end
