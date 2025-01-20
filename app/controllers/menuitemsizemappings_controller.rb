class MenuitemsizemappingsController < ApplicationController
  before_action :set_menuitemsizemapping, only: %i[update]


  # PATCH/PUT /menuitems/1 or /menuitems/1.json
  def update
    if current_user
        respond_to do |format|
          @menuItemSizeMapping = MenuitemSizeMapping.find(params[:id])
          if @menuItemSizeMapping.update(params.require(:menuitem_size_mapping).permit(:size_id, :menuitem_id, :price))
            format.html { redirect_to edit_menuitem_url(@menuItemSizeMapping.menuitem), notice: "Menuitem was successfully created." }
            format.json { render :show, status: :ok, location: @menuitem }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @menuitem.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menuitemsizemapping
        begin
            if current_user
                @menuItemSizeMapping = MenuitemSizeMapping.find(params[:id])
            else
                redirect_to root_url
            end
        rescue ActiveRecord::RecordNotFound => e
            redirect_to root_url
        end
    end
    # Only allow a list of trusted parameters through.
    def menuitemsizemapping_params
      params.require(:menuitem_size_mapping).permit(:size_id, :menuitem_id, :price)
    end
end
