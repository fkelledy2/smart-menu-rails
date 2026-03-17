class IngredientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  before_action :set_ingredient, only: %i[show edit update destroy]

  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  def index
    @ingredients = policy_scope(Ingredient)
                     .where(restaurant_id: [@restaurant.id, nil])
                     .where(archived: false)
                     .order(:name)
  end

  def new
    @ingredient = @restaurant.ingredients.new
    authorize @ingredient
  end

  def edit
    authorize @ingredient
  end

  def create
    @ingredient = @restaurant.ingredients.new(ingredient_params)
    authorize @ingredient

    if @ingredient.save
      redirect_to restaurant_ingredients_path(@restaurant), 
                  notice: 'Ingredient created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @ingredient

    if @ingredient.update(ingredient_params)
      redirect_to restaurant_ingredients_path(@restaurant), 
                  notice: 'Ingredient updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @ingredient
    @ingredient.update(archived: true)
    redirect_to restaurant_ingredients_path(@restaurant), 
                notice: 'Ingredient archived successfully.'
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_ingredient
    @ingredient = Ingredient.find(params[:id])
  end

  def ingredient_params
    params.require(:ingredient).permit(
      :name, :description, :unit_of_measure, :current_cost_per_unit,
      :supplier_id, :category, :is_shared, :parent_ingredient_id
    )
  end
end
