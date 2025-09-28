class TracksController < ApplicationController
  layout 'playlist', only: [:index]
  before_action :set_track, only: %i[show edit update destroy]

  # GET /tracks or /tracks.json
  def index
    if current_user
      if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @tracks = Track.joins(:restaurant).where(restaurant: @futureParentRestaurant).order(sequence: :asc).all
      else
        @tracks = Track.joins(:restaurant).where(restaurant: { user: current_user }).order(sequence: :asc).all
      end
      @restaurant = @futureParentRestaurant
    else
      redirect_to root_url
    end
  end

  # GET /tracks/1 or /tracks/1.json
  def show
    unless current_user
      redirect_to root_url
    end
  end

  # GET /tracks/new
  def new
    if current_user
      @track = Track.new
      if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @track.restaurant = @futureParentRestaurant
      end
    else
      redirect_to root_url
    end
  end

  # GET /tracks/1/edit
  def edit
    unless current_user
      redirect_to root_url
    end
  end

  # POST /tracks or /tracks.json
  def create
    if current_user
      @track = Track.new(track_params)
      respond_to do |format|
        if @track.save
          format.html do
            redirect_to edit_restaurant_path(id: @track.restaurant.id),
                        notice: t('common.flash.created', resource: t('activerecord.models.track'))
          end
          format.json { render :show, status: :created, location: @track }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @track.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to root_url
    end
  end

  # PATCH/PUT /tracks/1 or /tracks/1.json
  def update
    if current_user
      respond_to do |format|
        if @track.update(track_params)
          format.html do
            redirect_to edit_restaurant_path(id: @track.restaurant.id),
                        notice: t('common.flash.updated', resource: t('activerecord.models.track'))
          end
          format.json { render :show, status: :ok, location: @track }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @track.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to root_url
    end
  end

  # DELETE /tracks/1 or /tracks/1.json
  def destroy
    if current_user
      @track.destroy!
      respond_to do |format|
        format.html do
          redirect_to edit_restaurant_path(id: @track.restaurant.id),
                      notice: t('common.flash.deleted', resource: t('activerecord.models.track'))
        end
        format.json { head :no_content }
      end
    else
      redirect_to root_url
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_track
    if current_user
      @track = Track.find(params[:id])
      if @track.nil? || (@track.restaurant.user != current_user)
        redirect_to root_url
      end
    else
      redirect_to root_url
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_url
  end

  # Only allow a list of trusted parameters through.
  def track_params
    params.require(:track).permit(:externalid, :name, :description, :image, :sequence, :restaurant_id, :srtist,
                                  :is_playable, :explicit, :status,)
  end
end
