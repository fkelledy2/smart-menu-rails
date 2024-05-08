class TipsController < ApplicationController
  before_action :set_tip, only: %i[ show edit update destroy ]
  before_action :return_url

  # GET /tips or /tips.json
  def index
    if current_user
        @tips = Tip.joins(:restaurant).where(restaurant: {user: current_user}).all
        if params[:restaurant_id]
            @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
            @tips = Tip.joins(:restaurant).where(restaurant: @futureParentRestaurant).all
        else
            @tips = Tip.joins(:restaurant).where(restaurant: {user: current_user}).all
        end
    else
        redirect_to root_url
    end
  end

  # GET /tips/1 or /tips/1.json
  def show
  end

  # GET /tips/new
  def new
    @tip = Tip.new
    if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @tip.restaurant = @futureParentRestaurant
    end
  end

  # GET /tips/1/edit
  def edit
  end

  # POST /tips or /tips.json
  def create
    @tip = Tip.new(tip_params)

    respond_to do |format|
      if @tip.save
        format.html { redirect_to edit_restaurant_path(id: @tip.restaurant.id), notice: "Tip was successfully created." }
        # format.html { redirect_to @return_url, notice: "Tip was successfully created." }
        format.json { render :show, status: :created, location: @tip }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tip.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tips/1 or /tips/1.json
  def update
    respond_to do |format|
      if @tip.update(tip_params)
        format.html { redirect_to edit_restaurant_path(id: @tip.restaurant.id), notice: "Tip was successfully updated." }
        # format.html { redirect_to tip_url(@tip), notice: "Tip was successfully updated." }
        format.json { render :show, status: :ok, location: @tip }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tip.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tips/1 or /tips/1.json
  def destroy
    @tip.destroy!

    respond_to do |format|
      format.html { redirect_to tips_url, notice: "Tip was successfully destroyed." }
      format.json { head :no_content }
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
    def tip_params
      params.require(:tip).permit(:percentage, :restaurant_id)
    end
end