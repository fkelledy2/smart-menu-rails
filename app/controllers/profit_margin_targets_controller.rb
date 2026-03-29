class ProfitMarginTargetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_target, only: %i[edit update destroy]

  after_action :verify_authorized

  def index
    authorize ProfitMarginTarget
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability_targets')
  end

  def new
    @target = ProfitMarginTarget.new
    authorize @target
  end

  def edit
    authorize @target
  end

  def create
    @target = ProfitMarginTarget.new(target_params)
    authorize @target
    if @target.save
      redirect_to edit_restaurant_path(@restaurant, section: 'profitability_targets'), notice: 'Target created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @target
    if @target.update(target_params)
      redirect_to edit_restaurant_path(@restaurant, section: 'profitability_targets'), notice: 'Target updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @target
    @target.destroy
    redirect_to edit_restaurant_path(@restaurant, section: 'profitability_targets'), notice: 'Target deleted.'
  end

  private

  def set_restaurant
    @restaurant = current_user.restaurants.find(params[:restaurant_id])
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
