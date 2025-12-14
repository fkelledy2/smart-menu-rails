class TaxesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tax, only: %i[show edit update destroy]
  before_action :return_url

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /taxes or /taxes.json
  def index
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @taxes = policy_scope(Tax).where(restaurant: @futureParentRestaurant, archived: false).where.not(status: :archived)
    else
      @taxes = policy_scope(Tax).where(archived: false).where.not(status: :archived)
    end
  end

  # GET /taxes/1 or /taxes/1.json
  def show
    authorize @tax
  end

  # GET /taxes/new
  def new
    if current_user
      @tax = Tax.new
      if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @tax.restaurant = @futureParentRestaurant
      end
      authorize @tax
    else
      redirect_to root_url
    end
  end

  # GET /taxes/1/edit
  def edit
    unless current_user
      redirect_to root_url
    end
  end

  # POST /taxes or /taxes.json
  def create
    if current_user
      @tax = Tax.new(tax_params)
      authorize @tax
      respond_to do |format|
        if @tax.save
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace('taxes_new_tax', ''),
              turbo_stream.replace(
                'restaurant_content',
                partial: 'restaurants/sections/catalog_2025',
                locals: { restaurant: @tax.restaurant, filter: 'all' }
              )
            ]
          end
          format.html do
            redirect_to edit_restaurant_path(id: @tax.restaurant.id), notice: t('taxes.controller.created')
          end
          # format.html { redirect_to @return_url, notice: "Tax was successfully created." }
          format.json { render :show, status: :created, location: @tax }
        else
          format.turbo_stream { render :new, status: :unprocessable_entity }
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @tax.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to root_url
    end
  end

  # PATCH/PUT /taxes/1 or /taxes/1.json
  def update
    if current_user
      respond_to do |format|
        if @tax.update(tax_params)
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace('taxes_edit_tax', ''),
              turbo_stream.replace(
                'restaurant_content',
                partial: 'restaurants/sections/catalog_2025',
                locals: { restaurant: @tax.restaurant, filter: 'all' }
              )
            ]
          end
          format.html do
            redirect_to edit_restaurant_path(id: @tax.restaurant.id), notice: t('taxes.controller.updated')
          end
          # format.html { redirect_to tax_url(@tax), notice: "Tax was successfully updated." }
          format.json { render :show, status: :ok, location: @tax }
        else
          format.turbo_stream { render :edit, status: :unprocessable_entity }
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @tax.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to root_url
    end
  end

  # DELETE /taxes/1 or /taxes/1.json
  def destroy
    authorize @tax

    @tax.update(archived: true)
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_path(id: @tax.restaurant.id), notice: t('taxes.controller.deleted')
      end
      format.json { head :no_content }
    end
  end

  private

  def return_url
    @return_url = url_from(params[:return_to]) || @tax
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_tax
    @tax = Tax.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def tax_params
    params.require(:tax).permit(:name, :taxtype, :taxpercentage, :sequence, :status, :restaurant_id)
  end
end
