class AllergynsController < ApplicationController
  before_action :authenticate_user!, except: [:index] # Allow public viewing of allergens
  before_action :set_allergyn, only: %i[show edit update destroy]

  skip_around_action :switch_locale, only: %i[reorder bulk_update]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index reorder bulk_update]
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
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('allergens_edit_allergyn', ''),
            turbo_stream.replace(
              'restaurant_content',
              partial: 'restaurants/sections/allergens_2025',
              locals: { restaurant: @allergyn.restaurant, filter: 'all' }
            )
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(id: @allergyn.restaurant.id),
                      notice: t('common.flash.updated', resource: t('activerecord.models.allergyn'))
        end
        format.json { render :show, status: :ok, location: restaurant_allergyn_url(@allergyn.restaurant, @allergyn) }
      else
        format.turbo_stream { render :edit, status: :unprocessable_entity }
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

  # PATCH /restaurants/:restaurant_id/allergyns/bulk_update
  def bulk_update
    @restaurant = Restaurant.find(params[:restaurant_id])
    allergyns = policy_scope(Allergyn).where(restaurant_id: @restaurant.id, archived: false)

    ids = Array(params[:allergyn_ids]).map(&:to_s).reject(&:blank?)
    status = params[:status].to_s

    if ids.empty? || status.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/allergens_2025',
            locals: { restaurant: @restaurant, filter: 'all' }
          )
        end
        format.html do
          redirect_to edit_restaurant_path(@restaurant, section: 'allergens')
        end
      end
      return
    end

    to_update = allergyns.where(id: ids)
    to_update.find_each do |allergyn|
      authorize allergyn, :update?
      allergyn.update(status: status)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/allergens_2025',
          locals: { restaurant: @restaurant, filter: 'all' }
        )
      end
      format.html do
        redirect_to edit_restaurant_path(@restaurant, section: 'allergens')
      end
    end
  end

  # PATCH /restaurants/:restaurant_id/allergyns/reorder
  def reorder
    @restaurant = Restaurant.find(params[:restaurant_id])
    allergyns = policy_scope(Allergyn).where(restaurant_id: @restaurant.id, archived: false)

    order = params[:order]
    unless order.is_a?(Array)
      return render json: { status: 'error', message: 'Invalid order payload' }, status: :unprocessable_entity
    end

    Allergyn.transaction do
      order.each do |item|
        item_hash = if item.is_a?(ActionController::Parameters)
          item.to_unsafe_h
        elsif item.is_a?(Hash)
          item
        else
          next
        end

        id = item_hash[:id] || item_hash['id']
        seq = item_hash[:sequence] || item_hash['sequence']
        next if id.blank? || seq.nil?

        allergyn = allergyns.find(id)
        authorize allergyn, :update?
        allergyn.update_column(:sequence, seq.to_i)
      end
    end

    render json: { status: 'success', message: 'Allergens reordered successfully' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Allergen not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("Allergyns reorder error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: { status: 'error', message: e.message }, status: :unprocessable_entity
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
