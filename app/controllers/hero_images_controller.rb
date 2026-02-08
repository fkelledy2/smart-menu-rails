class HeroImagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_hero_image, only: %i[show edit update destroy]
  skip_before_action :redirect_to_onboarding_if_needed

  # Pundit authorization
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: [:index]

  # GET /hero_images or /hero_images.json
  def index
    authorize HeroImage
    @hero_images = policy_scope(HeroImage).ordered
  end

  # POST /hero_images/clear_cache
  def clear_cache
    authorize HeroImage, :clear_cache?
    ClearCacheJob.perform_async
    respond_to do |format|
      format.html { redirect_to hero_images_path, notice: 'Cache clear enqueued' }
      format.json { render json: { status: 'enqueued' } }
    end
  end

  # GET /hero_images/1 or /hero_images/1.json
  def show
    authorize @hero_image
  end

  # GET /hero_images/new
  def new
    @hero_image = HeroImage.new
    authorize @hero_image
  end

  # GET /hero_images/1/edit
  def edit
    authorize @hero_image
  end

  # POST /hero_images or /hero_images.json
  def create
    @hero_image = HeroImage.new(hero_image_params)
    authorize @hero_image

    respond_to do |format|
      if @hero_image.save
        format.html do
          redirect_to @hero_image, notice: t('common.flash.created', resource: 'Hero Image')
        end
        format.json { render :show, status: :created, location: @hero_image }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @hero_image.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /hero_images/1 or /hero_images/1.json
  def update
    authorize @hero_image

    respond_to do |format|
      if @hero_image.update(hero_image_params)
        format.html do
          redirect_to @hero_image, notice: t('common.flash.updated', resource: 'Hero Image')
        end
        format.json { render :show, status: :ok, location: @hero_image }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @hero_image.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /hero_images/1 or /hero_images/1.json
  def destroy
    authorize @hero_image
    @hero_image.destroy!

    respond_to do |format|
      format.html do
        redirect_to hero_images_path, status: :see_other,
                                      notice: t('common.flash.deleted', resource: 'Hero Image')
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_hero_image
    @hero_image = HeroImage.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def hero_image_params
    params.require(:hero_image).permit(:image_url, :alt_text, :sequence, :status, :source_url)
  end
end
