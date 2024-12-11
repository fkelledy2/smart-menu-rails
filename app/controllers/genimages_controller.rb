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

#         response = chatGPTclient.chat([
#           { role: "user", content: "Create an image of a sunset over mountains" }
#         ])
#         puts response.dig("choices", 0, "message", "content")

          @genimage.updated_at = DateTime.current
          if @genimage.update(genimage_params)
            if( @genimage.menuitem != nil )
                response = generate_image(@genimage.menuitem.description,'512x512')
                puts response
                if response.success?
                  seed = response['created']
                  puts seed
                  image_url = response['data'][0]['url']
                    downloaded_image = URI.parse(image_url).open
                    @genimage.menuitem.image = downloaded_image
                    @genimage.menuitem.save
                else
                    puts 'error'
                end
                format.html { redirect_to edit_menuitem_path(@genimage.menuitem), notice: "MenuItem: Image Refreshed." }
            else
                if( @genimage.menusection != nil )
                    response = generate_image(@genimage.menusection.description, '1024x256')
                    if response.success?
                      image_url = response['data'][0]['url']
                        downloaded_image = URI.parse(image_url).open
                        @genimage.menusection.image = downloaded_image
                        @genimage.menusection.save
                    else
                        puts 'error'
                    end
                    format.html { redirect_to edit_menusection_path(@genimage.menusection), notice: "MenuSection: Image Refreshed." }
                else
                    if( @genimage.menu != nil )
                        response = generate_image(@genimage.menu.description, '1024x256')
                        if response.success?
                          image_url = response['data'][0]['url']
                            downloaded_image = URI.parse(image_url).open
                            @genimage.menu.image = downloaded_image
                            @genimage.menu.save
                        else
                            puts 'error'
                        end
                        format.html { redirect_to edit_menu_path(@genimage.menu), notice: "Menu: Image Refreshed." }
                    else
                        response = generate_image(@genimage.restaurant.description, '1024x256')
                        if response.success?
                          image_url = response['data'][0]['url']
                            downloaded_image = URI.parse(image_url).open
                            @genimage.restaurant.image = downloaded_image
                            @genimage.restaurant.save
                        else
                            puts 'error'
                        end
                        format.html { redirect_to edit_restaurant_path(@genimage.restaurant), notice: "Restaurant: Image Refreshed." }
                    end
                end
            end
            format.json { render :edit, status: :ok, location: @genimage }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @genimage.errors, status: :unprocessable_entity }
          end
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
