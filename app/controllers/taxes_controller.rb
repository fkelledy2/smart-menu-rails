class TaxesController < ApplicationController
  before_action :set_tax, only: %i[ show edit update destroy ]
  before_action :return_url

  # GET /taxes or /taxes.json
  def index
    if current_user
        @taxes = Tax.joins(:restaurant).where(restaurant: {user: current_user}).all
        if params[:restaurant_id]
            @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
            @taxes = Tax.joins(:restaurant).where(restaurant: @futureParentRestaurant).all
        else
            @taxes = Tax.joins(:restaurant).where(restaurant: {user: current_user}).all
        end
    else
        redirect_to root_url
    end
  end

  # GET /taxes/1 or /taxes/1.json
  def show
  end

  # GET /taxes/new
  def new
    @tax = Tax.new
    if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @tax.restaurant = @futureParentRestaurant
    end
  end

  # GET /taxes/1/edit
  def edit
  end

  # POST /taxes or /taxes.json
  def create
    @tax = Tax.new(tax_params)

    respond_to do |format|
      if @tax.save
        format.html { redirect_to edit_restaurant_path(id: @tax.restaurant.id), notice: "Tax was successfully created." }
        # format.html { redirect_to @return_url, notice: "Tax was successfully created." }
        format.json { render :show, status: :created, location: @tax }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tax.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /taxes/1 or /taxes/1.json
  def update
    respond_to do |format|
      if @tax.update(tax_params)
        format.html { redirect_to edit_restaurant_path(id: @tax.restaurant.id), notice: "Tax was successfully updated." }
        # format.html { redirect_to tax_url(@tax), notice: "Tax was successfully updated." }
        format.json { render :show, status: :ok, location: @tax }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tax.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /taxes/1 or /taxes/1.json
  def destroy
    @tax.destroy!

    respond_to do |format|
      format.html { redirect_to taxes_url, notice: "Tax was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def return_url
      @return_url = url_from(params[:return_to]) || @tax
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_tax
        begin
            if current_user
                @tax = Tax.find(params[:id])
                if( @tax == nil or @tax.restaurant.user != current_user )
                    redirect_to home_url
                end
            else
                redirect_to root_url
            end
        rescue ActiveRecord::RecordNotFound => e
            redirect_to root_url
        end
    end

    # Only allow a list of trusted parameters through.
    def tax_params
      params.require(:tax).permit(:name, :taxtype, :taxpercentage, :sequence, :restaurant_id)
    end
end
