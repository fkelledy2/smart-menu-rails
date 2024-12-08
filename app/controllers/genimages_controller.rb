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
          @genimage.updated_at = DateTime.current
          if @genimage.update(genimage_params)
            if( @genimage.menuitem != nil )
                format.html { redirect_to edit_menuitem_path(@genimage.menuitem), notice: "MenuItem: Image Refreshed." }
            else
                if( @genimage.menusection != nil )
                    format.html { redirect_to edit_menusection_path(@genimage.menusection), notice: "MenuSection: Image Refreshed." }
                else
                    if( @genimage.menu != nil )
                        format.html { redirect_to edit_menu_path(@genimage.menu), notice: "Menu: Image Refreshed." }
                    else
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
end
