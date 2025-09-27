class TipsController < ApplicationController
  before_action :set_tip, only: %i[ show edit update destroy ]
  before_action :return_url

  # GET /tips or /tips.json
  def index
    if current_user
        if params[:restaurant_id]
            @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
            @tips = Tip.joins(:restaurant).where(restaurant: @futureParentRestaurant, archived: false).all
        else
            @tips = Tip.joins(:restaurant).where(restaurant: {user: current_user}, archived: false).all
        end
    else
        redirect_to root_url
    end
  end

  # GET /tips/1 or /tips/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /tips/new
  def new
    if current_user
        @tip = Tip.new
        if params[:restaurant_id]
            @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
            @tip.restaurant = @futureParentRestaurant
        end
    else
        redirect_to root_url
    end
  end

  # GET /tips/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /tips or /tips.json
  def create
    if current_user
        @tip = Tip.new(tip_params)
        respond_to do |format|
          if @tip.save
            format.html { redirect_to edit_restaurant_path(id: @tip.restaurant.id), notice: t('tips.controller.created') }
            format.json { render :show, status: :created, location: @tip }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @tip.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /tips/1 or /tips/1.json
  def update
    if current_user
        respond_to do |format|
          if @tip.update(tip_params)
            format.html { redirect_to edit_restaurant_path(id: @tip.restaurant.id), notice: t('tips.controller.updated') }
            # format.html { redirect_to tip_url(@tip), notice: "Tip was successfully updated." }
            format.json { render :show, status: :ok, location: @tip }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @tip.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /tips/1 or /tips/1.json
  def destroy
    if current_user
        @tip.update( archived: true )
        respond_to do |format|
          format.html { redirect_to edit_restaurant_path(id: @tip.restaurant.id), notice: t('tips.controller.deleted') }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private
    def return_url
      @return_url = url_from(params[:return_to]) || @tip
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_tip
        begin
            if current_user
                @tip = Tip.find(params[:id])
                if( @tip == nil or @tip.restaurant.user != current_user )
                    redirect_to root_url
                end
            else
                redirect_to root_url
            end
        rescue ActiveRecord::RecordNotFound => e
            redirect_to root_url
        end
    end

    # Only allow a list of trusted parameters through.
    def tip_params
      params.require(:tip).permit(:percentage, :restaurant_id, :sequence, :status)
    end
end