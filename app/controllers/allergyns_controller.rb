class AllergynsController < ApplicationController
  before_action :authenticate_user!, except: [:index] # Allow public viewing of allergens
  before_action :set_allergyn, only: %i[ show edit update destroy ]
  
  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /allergyns or /allergyns.json
  def index
    if params[:restaurant_id]
        @restaurant = Restaurant.find_by_id(params[:restaurant_id])
        if current_user
            @allergyns = policy_scope(Allergyn).where(restaurant: @restaurant)
        else
            @allergyns = Allergyn.where(restaurant: @restaurant)
        end
    end
    
    if current_user
        Analytics.track(
            user_id: current_user.id,
            event: 'allergyns.index',
            properties: {
              restaurant_id: @restaurant&.id,
            }
        )
    else
        Analytics.track(
            event: 'allergyns.index',
            properties: {
              restaurant_id: @restaurant&.id,
            }
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
            format.html { redirect_to edit_restaurant_path(id: @allergyn.restaurant.id), notice: t('common.flash.created', resource: t('activerecord.models.allergyn')) }
            format.json { render :show, status: :created, location: @allergyn }
          else
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
            format.html { redirect_to edit_restaurant_path(id: @allergyn.restaurant.id), notice: t('common.flash.updated', resource: t('activerecord.models.allergyn')) }
            format.json { render :show, status: :ok, location: @allergyn }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @allergyn.errors, status: :unprocessable_entity }
          end
        end
  end

  # DELETE /allergyns/1 or /allergyns/1.json
  def destroy
    authorize @allergyn
    
    @allergyn.update( archived: true )
    respond_to do |format|
      format.html { redirect_to edit_restaurant_path(id: @allergyn.restaurant.id), notice: t('common.flash.deleted', resource: t('activerecord.models.allergyn')) }
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
