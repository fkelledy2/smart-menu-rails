class TipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_tip, only: %i[show edit update destroy]
  before_action :return_url

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /tips or /tips.json
  def index
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @tips = policy_scope(Tip).where(restaurant: @futureParentRestaurant, archived: false).where.not(status: :archived)
    else
      @tips = policy_scope(Tip).where(archived: false).where.not(status: :archived)
    end
  end

  # GET /tips/1 or /tips/1.json
  def show
    authorize @tip
  end

  # GET /tips/new
  def new
    @tip = Tip.new
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @tip.restaurant = @futureParentRestaurant
    end
    authorize @tip
  end

  # GET /tips/1/edit
  def edit
    authorize @tip
  end

  # POST /tips or /tips.json
  def create
    @tip = Tip.new(tip_params)
    authorize @tip
    respond_to do |format|
      if @tip.save
        format.html do
          redirect_to edit_restaurant_path(id: @tip.restaurant.id), notice: t('tips.controller.created')
        end
        format.json { render :show, status: :created, location: restaurant_tip_url(@tip.restaurant, @tip) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tip.errors, status: :unprocessable_entity }
      end
    end
  rescue ArgumentError => e
    # Handle invalid enum values
    @tip = Tip.new
    @tip.errors.add(:status, e.message)
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @tip.errors, status: :unprocessable_entity }
    end
  end

  # PATCH/PUT /tips/1 or /tips/1.json
  def update
    authorize @tip

    respond_to do |format|
      if @tip.update(tip_params)
        format.html do
          redirect_to edit_restaurant_path(id: @tip.restaurant.id), notice: t('tips.controller.updated')
        end
        format.json { render :show, status: :ok, location: restaurant_tip_url(@tip.restaurant, @tip) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tip.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tips/1 or /tips/1.json
  def destroy
    authorize @tip

    @tip.update(archived: true)
    respond_to do |format|
      format.html { redirect_to edit_restaurant_path(id: @tip.restaurant.id), notice: t('tips.controller.deleted') }
      format.json { head :no_content }
    end
  end

  private

  def return_url
    @return_url = url_from(params[:return_to]) || @tip
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_restaurant
    @restaurant = current_user.restaurants.find(params[:restaurant_id])
    authorize @restaurant, :show?
  end

  def set_tip
    @tip = Tip.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def tip_params
    params.require(:tip).permit(:percentage, :restaurant_id, :sequence, :status)
  end
end
