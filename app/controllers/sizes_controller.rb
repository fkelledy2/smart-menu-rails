class SizesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_size, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /sizes or /sizes.json
  def index
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @sizes = policy_scope(Size).where(restaurant: @futureParentRestaurant, archived: false).where.not(status: :archived)
    else
      @sizes = policy_scope(Size).where(archived: false).where.not(status: :archived)
    end
  end

  # GET /sizes/1 or /sizes/1.json
  def show
    authorize @size
  end

  # GET /sizes/new
  def new
    @size = Size.new
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @size.restaurant = @futureParentRestaurant
    end
    authorize @size
  end

  # GET /sizes/1/edit
  def edit
    authorize @size
  end

  # POST /sizes or /sizes.json
  def create
    @size = Size.new(size_params)
    authorize @size

    respond_to do |format|
      if @size.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('sizes_new_size', ''),
            turbo_stream.replace('restaurant_content', partial: 'restaurants/sections/sizes_2025', locals: { restaurant: @size.restaurant, filter: 'all' })
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(@size.restaurant_id),
                      notice: t('common.flash.created', resource: t('activerecord.models.size'))
        end
        format.json { render :show, status: :created, location: restaurant_size_url(@restaurant, @size) }
      else
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @size.errors, status: :unprocessable_entity }
      end
    end
  rescue ArgumentError => e
    # Handle invalid enum values
    @size = Size.new
    @size.errors.add(:size, e.message)
    respond_to do |format|
      format.turbo_stream { render :new, status: :unprocessable_entity }
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @size.errors, status: :unprocessable_entity }
    end
  end

  # PATCH/PUT /sizes/1 or /sizes/1.json
  def update
    authorize @size

    respond_to do |format|
      if @size.update(size_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('sizes_edit_size', ''),
            turbo_stream.replace(
              'restaurant_content',
              partial: 'restaurants/sections/sizes_2025',
              locals: { restaurant: @size.restaurant, filter: 'all' }
            )
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(@size.restaurant),
                      notice: t('common.flash.updated', resource: t('activerecord.models.size'))
        end
        format.json { render :show, status: :ok, location: restaurant_size_url(@restaurant, @size) }
      else
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @size.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sizes/1 or /sizes/1.json
  def destroy
    authorize @size

    @size.update(archived: true)
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_path(@size.restaurant),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.size'))
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

  def set_size
    @size = Size.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def size_params
    params.require(:size).permit(:size, :name, :description, :status, :sequence, :restaurant_id)
  end
end
