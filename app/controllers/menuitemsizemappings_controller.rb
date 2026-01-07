class MenuitemsizemappingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_menuitemsizemapping, only: %i[update]
  before_action :ensure_owner_restaurant_context_for_menu!, only: %i[update]

  # Pundit authorization
  after_action :verify_authorized

  # PATCH/PUT /menuitems/1 or /menuitems/1.json
  def update
    authorize @menuItemSizeMapping

    respond_to do |format|
      if @menuItemSizeMapping.update(menuitemsizemapping_params)
        format.html do
          menuitem = @menuItemSizeMapping.menuitem
          menusection = menuitem.menusection
          menu = menusection.menu
          restaurant = menu.owner_restaurant || menu.restaurant
          
          redirect_to edit_restaurant_menu_menusection_menuitem_path(restaurant, menu, menusection, menuitem),
                      notice: t('common.flash.updated', resource: t('activerecord.models.menuitem'))
        end
        format.json { render :show, status: :ok, location: @menuItemSizeMapping }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menuItemSizeMapping.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def ensure_owner_restaurant_context_for_menu!
    return if params[:restaurant_id].blank?

    menu = @menuItemSizeMapping&.menuitem&.menusection&.menu
    return unless menu

    owner_restaurant_id = menu.owner_restaurant_id.presence || menu.restaurant_id
    return if owner_restaurant_id.blank?
    return if params[:restaurant_id].to_i == owner_restaurant_id

    redirect_to edit_restaurant_path(params[:restaurant_id], section: 'menus'), alert: 'This menu is read-only for this restaurant'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_menuitemsizemapping
    @menuItemSizeMapping = MenuitemSizeMapping.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def menuitemsizemapping_params
    params.require(:menuitem_size_mapping).permit(:size_id, :menuitem_id, :price)
  end
end
