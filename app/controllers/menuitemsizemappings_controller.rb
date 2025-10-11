class MenuitemsizemappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_menuitemsizemapping, only: %i[update]

  # Pundit authorization
  after_action :verify_authorized

  # PATCH/PUT /menuitems/1 or /menuitems/1.json
  def update
    authorize @menuItemSizeMapping

    respond_to do |format|
      if @menuItemSizeMapping.update(menuitemsizemapping_params)
        format.html do
          if params[:menu_id]
            redirect_to edit_menu_menuitem_url(@menuItemSizeMapping.menuitem.menusection.menu, @menuItemSizeMapping.menuitem),
                        notice: t('common.flash.updated', resource: t('activerecord.models.menuitem'))
          else
            redirect_to edit_menuitem_url(@menuItemSizeMapping.menuitem),
                        notice: t('common.flash.updated', resource: t('activerecord.models.menuitem'))
          end
        end
        format.json { render :show, status: :ok, location: @menuItemSizeMapping }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menuItemSizeMapping.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_menuitemsizemapping
    @menuItemSizeMapping = MenuitemSizeMapping.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def menuitemsizemapping_params
    params.require(:menuitem_size_mapping).permit(:size_id, :menuitem_id, :price)
  end
end
