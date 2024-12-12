require 'chatgpt/client'

class GenimagesController < ApplicationController
  before_action :set_genimage, only: %i[ show edit update destroy ]

  # GET /genimages or /genimages.json
  def index
    if current_user
        @genimages = Genimage.all
    else
        redirect_to root_url
    end
  end

  # GET /genimages/1 or /genimages/1.json
  def show
    redirect_to root_url
  end

  # GET /genimages/new
  def new
    if current_user
        @genimage = Genimage.new
    else
        redirect_to root_url
    end
  end

  # GET /genimages/1/edit
  def edit
    redirect_to root_url
  end

  # POST /genimages or /genimages.json
  def create
    if current_user
        @genimage = Genimage.new
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /genimages/1 or /genimages/1.json
  def update
    if current_user
        respond_to do |format|
          chatGPTclient = ChatGPT::Client.new(Rails.application.credentials.openai_api_key)
          GenerateImageJob.perform_async(@genimage.id)
          format.html { redirect_to edit_menusection_path(@menuitem.menusection), notice: "Menuitem was successfully updated." }
          format.json { render :show, status: :ok, location: @menuitem }
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /genimages/1 or /genimages/1.json
  def destroy
    if current_user
        @genimage.destroy!
        respond_to do |format|
          format.html { redirect_to genimages_path, status: :see_other, notice: "Genimage was successfully destroyed." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
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
