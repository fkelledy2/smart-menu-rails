class AllergynsController < ApplicationController
  before_action :authenticate_user!, except: [:index] # Allow public viewing of allergens
  before_action :set_allergyn, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /allergyns or /allergyns.json
  def index
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find_by(id: params[:restaurant_id])
      @restaurant = @futureParentRestaurant
      # Show all non-archived allergens (both active and inactive) scoped by restaurant
      @allergyns = if current_user
                     policy_scope(Allergyn).includes(:restaurant).where(restaurant: @restaurant, archived: false).order(:sequence)
                   else
                     Allergyn.includes(:restaurant).where(restaurant: @restaurant, archived: false).order(:sequence)
                   end
    end

    if current_user
      Analytics.track(
        user_id: current_user.id,
        event: 'allergyns.index',
        properties: {
          restaurant_id: @restaurant&.id,
        },
      )
    else
      Analytics.track(
        event: 'allergyns.index',
        properties: {
          restaurant_id: @restaurant&.id,
        },
      )
    end
  end

  # GET /allergyns/1 or /allergyns/1.json
  def show
    authorize @allergyn
  end

  # GET /allergyns/new
  def new
    @allergyn = Allergyn.new
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @allergyn.restaurant = @futureParentRestaurant
    end
    authorize @allergyn
  end

  # GET /allergyns/1/edit
  def edit
    authorize @allergyn
  end

  # POST /allergyns or /allergyns.json
  def create
    @allergyn = Allergyn.new(allergyn_params)
    authorize @allergyn

    respond_to do |format|
      if @allergyn.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('allergens_new_allergyn', ''),
            turbo_stream.replace('restaurant_content', partial: 'restaurants/sections/allergens_2025', locals: { restaurant: @allergyn.restaurant, filter: 'all' })
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(id: @allergyn.restaurant.id),
                      notice: t('common.flash.created', resource: t('activerecord.models.allergyn'))
        end
        format.json do
          render :show, status: :created, location: restaurant_allergyn_url(@allergyn.restaurant, @allergyn)
        end
      else
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @allergyn.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /allergyns/1 or /allergyns/1.json
  def update
    authorize @allergyn

    respond_to do |format|
      if @allergyn.update(allergyn_params)
        format.html do
          redirect_to edit_restaurant_path(id: @allergyn.restaurant.id),
                      notice: t('common.flash.updated', resource: t('activerecord.models.allergyn'))
        end
        format.json { render :show, status: :ok, location: restaurant_allergyn_url(@allergyn.restaurant, @allergyn) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @allergyn.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /allergyns/1 or /allergyns/1.json
  def destroy
    authorize @allergyn

    @allergyn.update(archived: true)
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_path(id: @allergyn.restaurant.id),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.allergyn'))
      end
      format.json { head :no_content }
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
