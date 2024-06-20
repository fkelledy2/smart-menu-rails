class SizesController < ApplicationController
  before_action :set_size, only: %i[ show edit update destroy ]

  # GET /sizes or /sizes.json
  def index
    if current_user
        @sizes = Size.where(archived: false).all
    else
        redirect_to root_url
    end
  end

  # GET /sizes/1 or /sizes/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /sizes/new
  def new
    if current_user
      @size = Size.new
      if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @size.restaurant = @futureParentRestaurant
      end
    else
        redirect_to root_url
    end
  end

  # GET /sizes/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /sizes or /sizes.json
  def create
    if current_user
        @size = Size.new(size_params)
        respond_to do |format|
          if @size.save
            format.html { redirect_to edit_restaurant_path(@size.restaurant_id), notice: "Size was successfully created." }
            format.json { render :show, status: :created, location: @size }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @size.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /sizes/1 or /sizes/1.json
  def update
    if current_user
        respond_to do |format|
          if @size.update(size_params)
            format.html { redirect_to edit_restaurant_path(@size.restaurant_id), notice: "Size was successfully updated." }
            format.json { render :show, status: :ok, location: @size }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @size.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /sizes/1 or /sizes/1.json
  def destroy
    if current_user
        @size.update( archived: true )
        respond_to do |format|
          format.html { redirect_to edit_restaurant_path(@size.restaurant_id), notice: "Size was successfully deleted." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_size
      @size = Size.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def size_params
      params.require(:size).permit(:size, :name, :description, :status, :sequence, :restaurant_id)
    end
end
