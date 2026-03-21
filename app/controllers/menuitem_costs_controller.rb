class MenuitemCostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_menu
  before_action :set_menuitem
  before_action :set_menuitem_cost, only: %i[edit update destroy]

  def new
    @menuitem_cost = @menuitem.menuitem_costs.new(effective_date: Date.current)
  end

  def edit; end

  def create
    @menuitem_cost = @menuitem.menuitem_costs.new(menuitem_cost_params)
    @menuitem_cost.created_by_user = current_user
    @menuitem_cost.is_active = true

    if @menuitem_cost.save
      redirect_to edit_restaurant_path(@restaurant, section: 'profitability_margins'),
                  notice: 'Cost data saved.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @menuitem_cost.update(menuitem_cost_params)
      redirect_to edit_restaurant_path(@restaurant, section: 'profitability_margins'),
                  notice: 'Cost data updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @menuitem_cost.update(is_active: false)
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability_margins'),
                notice: 'Cost data deactivated.'
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_menu
    @menu = @restaurant.menus.find(params[:menu_id])
  end

  def set_menuitem
    @menuitem = Menuitem.joins(:menusection)
      .where(menusections: { menu_id: @menu.id })
      .find(params[:menuitem_id])
  end

  def set_menuitem_cost
    @menuitem_cost = @menuitem.menuitem_costs.find(params[:id])
  end

  def menuitem_cost_params
    params.require(:menuitem_cost).permit(
      :ingredient_cost, :labor_cost, :packaging_cost, :overhead_cost,
      :cost_source, :effective_date, :notes,
    )
  end
end
