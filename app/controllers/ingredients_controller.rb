class IngredientsController < ApplicationController
  before_action :set_ingredient, only: %i[ show edit update destroy ]

  # GET /ingredients or /ingredients.json
  def index
    if current_user
        @ingredients = Ingredient.where( archived: false).all
    else
        redirect_to root_url
    end
  end

  # GET /ingredients/1 or /ingredients/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /ingredients/new
  def new
    if current_user
        @ingredient = Ingredient.new
    else
        redirect_to root_url
    end
  end

  # GET /ingredients/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /ingredients or /ingredients.json
  def create
    if current_user
        @ingredient = Ingredient.new(ingredient_params)
        respond_to do |format|
          if @ingredient.save
            format.html { redirect_to ingredient_url(@ingredient), notice: "Ingredient was successfully created." }
            format.json { render :show, status: :created, location: @ingredient }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @ingredient.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /ingredients/1 or /ingredients/1.json
  def update
    if current_user
        respond_to do |format|
          if @ingredient.update(ingredient_params)
            format.html { redirect_to ingredient_url(@ingredient), notice: "Ingredient was successfully updated." }
            format.json { render :show, status: :ok, location: @ingredient }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @ingredient.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /ingredients/1 or /ingredients/1.json
  def destroy
    if current_user
        @ingredient.update( archived: true )
        respond_to do |format|
          format.html { redirect_to ingredients_url, notice: "Ingredient was successfully destroyed." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ingredient
      @ingredient = Ingredient.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ingredient_params
      params.require(:ingredient).permit(:name, :description)
    end
end
