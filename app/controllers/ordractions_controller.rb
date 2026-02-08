class OrdractionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_ordraction, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /ordractions or /ordractions.json
  def index
    @ordractions = policy_scope(Ordraction)
  end

  # GET /ordractions/1 or /ordractions/1.json
  def show
    authorize @ordraction
  end

  # GET /ordractions/new
  def new
    @ordraction = Ordraction.new
    authorize @ordraction
  end

  # GET /ordractions/1/edit
  def edit
    authorize @ordraction
  end

  # POST /ordractions or /ordractions.json
  def create
    @ordraction = Ordraction.new(ordraction_params)
    authorize @ordraction

    respond_to do |format|
      if @ordraction.save
        format.html do
          redirect_to ordraction_url(@ordraction),
                      notice: t('common.flash.created', resource: t('activerecord.models.ordraction'))
        end
        format.json { render :show, status: :created, location: @ordraction }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @ordraction.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /ordractions/1 or /ordractions/1.json
  def update
    authorize @ordraction

    respond_to do |format|
      if @ordraction.update(ordraction_params)
        format.html do
          redirect_to ordraction_url(@ordraction),
                      notice: t('common.flash.updated', resource: t('activerecord.models.ordraction'))
        end
        format.json { render :show, status: :ok, location: @ordraction }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @ordraction.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /ordractions/1 or /ordractions/1.json
  def destroy
    authorize @ordraction

    @ordraction.destroy!
    respond_to do |format|
      format.html do
        redirect_to restaurant_ordractions_path(@restaurant),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.ordraction'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_restaurant
    @restaurant = current_user.restaurants.find(params[:restaurant_id])
    authorize @restaurant, :show?
  end

  def set_ordraction
    @ordraction = Ordraction.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def ordraction_params
    params.require(:ordraction).permit(:action, :employee_id, :ordrparticipant_id, :ordr_id, :ordritem_id)
  end
end
