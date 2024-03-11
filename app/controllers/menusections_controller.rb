class MenusectionsController < ApplicationController
  before_action :set_menusection, only: %i[ show edit update destroy ]

  # GET /menusections or /menusections.json
  def index
    @menusections = Menusection.order('sequence ASC').all
  end

  # GET /menusections/1 or /menusections/1.json
  def show
  end

  # GET /menusections/new
  def new
    @menusection = Menusection.new
  end

  # GET /menusections/1/edit
  def edit
  end

  # POST /menusections or /menusections.json
  def create
    @menusection = Menusection.new(menusection_params)

    respond_to do |format|
      if @menusection.save
        format.html { redirect_to menusection_url(@menusection), notice: "Menusection was successfully created." }
        format.json { render :show, status: :created, location: @menusection }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menusection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menusections/1 or /menusections/1.json
  def update
    respond_to do |format|
      if @menusection.update(menusection_params)
        format.html { redirect_to menusection_url(@menusection), notice: "Menusection was successfully updated." }
        format.json { render :show, status: :ok, location: @menusection }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menusection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menusections/1 or /menusections/1.json
  def destroy
    @menusection.destroy!

    respond_to do |format|
      format.html { redirect_to menusections_url, notice: "Menusection was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menusection
      @menusection = Menusection.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def menusection_params
      params.require(:menusection).permit(:name, :description, :image, :status, :sequence, :menu_id)
    end
end
