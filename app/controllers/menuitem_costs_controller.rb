class MenuitemCostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_menu
  before_action :set_menuitem
  before_action :set_menuitem_cost, only: %i[edit update destroy]

  def new
    @menuitem_cost = @menuitem.menuitem_costs.new(effective_date: Date.current)
  end

  def create
    @menuitem_cost = @menuitem.menuitem_costs.new(menuitem_cost_params)
    @menuitem_cost.created_by_user = current_user
    @menuitem_cost.is_active = true

    if @menuitem_cost.save
      redirect_to edit_restaurant_menu_path(@restaurant, @menu), 
                  notice: 'Cost data saved successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @menuitem_cost.update(menuitem_cost_params)
      redirect_to edit_restaurant_menu_path(@restaurant, @menu), 
                  notice: 'Cost data updated successfully.'
    else
      ren    :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @menuitem_cost.update(is_active: false)
    redirect_to edit_restaurant_menu_path(@restaurant, @menu), 
                notice: 'Cost data deactivated successfully.'
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_menu
    @menu = @restaurant.menus.find(params[:menu_id])
  end

  def set_menuitem
    @menuitem = @menu.menusections.flat_map(&:menuitems).find(params[:menuitem_id])
  end

  def set_menuitem_cost
    @menuitem_cost = @menuitem.menuitem_costs.find(params[:id])
  end

  def menuitem_cost_params
    params.require(:menuitem_cost).permit(
      :ingredient_cost, :labor_cost, :packaging_cost, :overhead_cost,
      :cost_source, :effective_date, :notes
    )
  end
end
