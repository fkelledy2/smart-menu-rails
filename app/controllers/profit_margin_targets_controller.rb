class ProfitMarginTargetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_target, only: %i[edit update destroy]

  def index
    @targets = ProfitMarginTarget.where(restaurant_id: @restaurant.id).or(
      ProfitMarginTarget.where(menusection_id: @restaurant.menus.joins(:menusections).select('menusections.id')),
    ).active.order(effective_from: :desc)
  end

  def new
    @target = ProfitMarginTarget.new
  end

  def create
    @target = ProfitMarginTarget.new(target_params)
    if @target.save
      redirect_to restaurant_profit_margin_targets_path(@restaurant), notice: 'Target created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @target.update(target_params)
      redirect_to restaurant_profit_margin_targets_path(@restaurant), notice: 'Target updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @target.destroy
    redirect_to restaurant_profit_margin_targets_path(@restaurant), notice: 'Target deleted.'
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_target
    @target = ProfitMarginTarget.find(params[:id])
  end

  def target_params
    params.require(:profit_margin_target).permit(
      :restaurant_id, :menusection_id, :menuitem_id,
      :target_margin_percentage, :minimum_margin_percentage,
      :effective_from, :effective_to,
    )
  end
end
