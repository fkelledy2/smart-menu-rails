# OpenAI integration is handled elsewhere; legacy chatgpt-ruby removed

class GenimagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_genimage, only: %i[ show edit update destroy ]
  
  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /genimages or /genimages.json
  def index
    @genimages = policy_scope(Genimage)
  end

  # GET /genimages/1 or /genimages/1.json
  def show
    authorize @genimage
    redirect_to root_url
  end

  # GET /genimages/new
  def new
    @genimage = Genimage.new
    authorize @genimage
  end

  # GET /genimages/1/edit
  def edit
    authorize @genimage
    redirect_to root_url
  end

  # POST /genimages or /genimages.json
  def create
    @genimage = Genimage.new
    authorize @genimage
  end

  # PATCH/PUT /genimages/1 or /genimages/1.json
  def update
    authorize @genimage
    
    respond_to do |format|
          if @genimage.menuitem.itemtype != 'wine'
              GenerateImageJob.perform_sync(@genimage.id)
          end
          format.html { redirect_to edit_menuitem_path(@genimage.menuitem), notice: t('common.flash.updated', resource: t('activerecord.models.genimage')) }
          format.json { render :show, status: :ok, location: @genimage }
        end
  end

  # DELETE /genimages/1 or /genimages/1.json
  def destroy
    authorize @genimage
    
    @genimage.destroy!
    respond_to do |format|
      format.html { redirect_to genimages_path, status: :see_other, notice: t('common.flash.deleted', resource: t('activerecord.models.genimage')) }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_genimage
      @genimage = Genimage.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def genimage_params
      params.require(:genimage).permit(:id, :image_data, :name, :description, :restaurant_id, :menu_id, :menusection_id, :menuitem_id)
    end

    def generate_image(prompt, size)
        api_key = Rails.application.credentials.openai_api_key
        headers = { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
        body = { prompt: prompt, n: 1, size: size }.to_json

        HTTParty.post(
          'https://api.openai.com/v1/images/generations',
          headers: headers,
          body: body
        )
    end

end
