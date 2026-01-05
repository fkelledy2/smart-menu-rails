class TipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_tip, only: %i[show edit update destroy]
  before_action :return_url

  skip_around_action :switch_locale, only: %i[reorder bulk_update]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index reorder bulk_update]
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
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('tips_new_tip', ''),
            turbo_stream.replace(
              'restaurant_content',
              partial: 'restaurants/sections/catalog_2025',
              locals: { restaurant: @tip.restaurant, filter: 'all' }
            )
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(id: @tip.restaurant.id), notice: t('tips.controller.created')
        end
        format.json { render :show, status: :created, location: restaurant_tip_url(@tip.restaurant, @tip) }
      else
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tip.errors, status: :unprocessable_entity }
      end
    end
  rescue ArgumentError => e
    # Handle invalid enum values
    @tip = Tip.new
    @tip.errors.add(:status, e.message)
    respond_to do |format|
      format.turbo_stream { render :new, status: :unprocessable_entity }
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @tip.errors, status: :unprocessable_entity }
    end
  end

  # PATCH/PUT /tips/1 or /tips/1.json
  def update
    authorize @tip

    respond_to do |format|
      if @tip.update(tip_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('tips_edit_tip', ''),
            turbo_stream.replace(
              'restaurant_content',
              partial: 'restaurants/sections/catalog_2025',
              locals: { restaurant: @tip.restaurant, filter: 'all' }
            )
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(id: @tip.restaurant.id), notice: t('tips.controller.updated')
        end
        format.json { render :show, status: :ok, location: restaurant_tip_url(@tip.restaurant, @tip) }
      else
        format.turbo_stream { render :edit, status: :unprocessable_entity }
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

  # PATCH /restaurants/:restaurant_id/tips/bulk_update
  def bulk_update
    restaurant = Restaurant.find(params[:restaurant_id])
    tips = policy_scope(Tip).where(restaurant_id: restaurant.id, archived: false)

    ids = Array(params[:tip_ids]).map(&:to_s).reject(&:blank?)
    status = params[:status].to_s

    if ids.empty? || status.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/catalog_2025',
            locals: { restaurant: restaurant, filter: 'all' }
          )
        end
        format.html do
          redirect_to edit_restaurant_path(restaurant, section: 'taxes_and_tips')
        end
      end
      return
    end

    to_update = tips.where(id: ids)
    to_update.find_each do |tip|
      authorize tip, :update?
      tip.update(status: status)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/catalog_2025',
          locals: { restaurant: restaurant, filter: 'all' }
        )
      end
      format.html do
        redirect_to edit_restaurant_path(restaurant, section: 'taxes_and_tips')
      end
    end
  end

  # PATCH /restaurants/:restaurant_id/tips/reorder
  def reorder
    restaurant = Restaurant.find(params[:restaurant_id])
    tips = policy_scope(Tip).where(restaurant_id: restaurant.id, archived: false)

    order = params[:order]
    unless order.is_a?(Array)
      return render json: { status: 'error', message: 'Invalid order payload' }, status: :unprocessable_entity
    end

    Tip.transaction do
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

        tip = tips.find(id)
        authorize tip, :update?
        tip.update_column(:sequence, seq.to_i)
      end
    end

    render json: { status: 'success', message: 'Tips reordered successfully' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Tip not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("Tips reorder error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: { status: 'error', message: e.message }, status: :unprocessable_entity
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
