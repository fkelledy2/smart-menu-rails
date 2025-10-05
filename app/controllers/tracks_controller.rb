class TracksController < ApplicationController
  layout 'playlist', only: [:index]
  before_action :authenticate_user!
  before_action :set_restaurant, only: [:index, :new, :create]
  before_action :set_track, only: %i[show edit update destroy]
  
  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /tracks or /tracks.json
  def index
    @tracks = if @restaurant
                # Restaurant-specific tracks
                policy_scope(Track).where(restaurant: @restaurant).order(sequence: :asc)
              else
                # All user's tracks across restaurants
                policy_scope(Track).order(sequence: :asc)
              end
  end

  # GET /tracks/1 or /tracks/1.json
  def show
    authorize @track
  end

  # GET /tracks/new
  def new
    @track = Track.new
    @track.restaurant = @restaurant if @restaurant
    authorize @track
  end

  # GET /tracks/1/edit
  def edit
    authorize @track
  end

  # POST /tracks or /tracks.json
  def create
    @track = Track.new(track_params)
    authorize @track
    
    respond_to do |format|
      if @track.save
        format.html do
          redirect_to restaurant_tracks_path(@track.restaurant),
                      notice: t('common.flash.created', resource: t('activerecord.models.track'))
        end
        format.json { render :show, status: :created, location: @track }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @track.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tracks/1 or /tracks/1.json
  def update
    authorize @track
    
    respond_to do |format|
      if @track.update(track_params)
        format.html do
          redirect_to restaurant_tracks_path(@track.restaurant),
                      notice: t('common.flash.updated', resource: t('activerecord.models.track'))
        end
        format.json { render :show, status: :ok, location: @track }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @track.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tracks/1 or /tracks/1.json
  def destroy
    authorize @track
    @track.destroy!
    
    respond_to do |format|
      format.html do
        redirect_to restaurant_tracks_path(@track.restaurant),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.track'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_track
    @track = Track.find(params[:id])
  end
  
  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id]) if params[:restaurant_id]
  end

  # Only allow a list of trusted parameters through.
  def track_params
    params.require(:track).permit(:externalid, :name, :description, :image, :sequence, :restaurant_id, :srtist,
                                  :is_playable, :explicit, :status,)
  end
end
