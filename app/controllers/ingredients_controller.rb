class IngredientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ingredient, only: %i[ show edit update destroy ]
  
  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /ingredients or /ingredients.json
  def index
    @ingredients = policy_scope(Ingredient).where(archived: false)
  end

  # GET /ingredients/1 or /ingredients/1.json
  def show
    authorize @ingredient
  end

  # GET /ingredients/new
  def new
    @ingredient = Ingredient.new
    authorize @ingredient
  end

  # GET /ingredients/1/edit
  def edit
    authorize @ingredient
  end

  # POST /ingredients or /ingredients.json
  def create
    @ingredient = Ingredient.new(ingredient_params)
    authorize @ingredient
    
    respond_to do |format|
          if @ingredient.save
            format.html { redirect_to ingredient_url(@ingredient), notice: t('common.flash.created', resource: t('activerecord.models.ingredient')) }
            format.json { render :show, status: :created, location: @ingredient }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @ingredient.errors, status: :unprocessable_entity }
          end
        end
  end

  # PATCH/PUT /ingredients/1 or /ingredients/1.json
  def update
    authorize @ingredient
    
    respond_to do |format|
          if @ingredient.update(ingredient_params)
            format.html { redirect_to ingredient_url(@ingredient), notice: t('common.flash.updated', resource: t('activerecord.models.ingredient')) }
            format.json { render :show, status: :ok, location: @ingredient }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @ingredient.errors, status: :unprocessable_entity }
          end
        end
  end

  # DELETE /ingredients/1 or /ingredients/1.json
  def destroy
    authorize @ingredient
    
    @ingredient.update( archived: true )
    respond_to do |format|
      format.html { redirect_to ingredients_url, notice: t('common.flash.deleted', resource: t('activerecord.models.ingredient')) }
      format.json { head :no_content }
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
