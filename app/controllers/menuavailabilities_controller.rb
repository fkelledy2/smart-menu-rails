class MenuavailabilitiesController < ApplicationController
  before_action :set_menuavailability, only: %i[ show edit update destroy ]

  # GET /menuavailabilities or /menuavailabilities.json
  def index
    @menuavailabilities = Menuavailability.all
  end

  # GET /menuavailabilities/1 or /menuavailabilities/1.json
  def show
  end

  # GET /menuavailabilities/new
  def new
    @menuavailability = Menuavailability.new
  end

  # GET /menuavailabilities/1/edit
  def edit
  end

  # POST /menuavailabilities or /menuavailabilities.json
  def create
    @menuavailability = Menuavailability.new(menuavailability_params)

    respond_to do |format|
      if @menuavailability.save
        format.html { redirect_to menuavailability_url(@menuavailability), notice: "Menuavailability was successfully created." }
        format.json { render :show, status: :created, location: @menuavailability }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menuavailability.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menuavailabilities/1 or /menuavailabilities/1.json
  def update
    respond_to do |format|
      if @menuavailability.update(menuavailability_params)
        format.html { redirect_to menuavailability_url(@menuavailability), notice: "Menuavailability was successfully updated." }
        format.json { render :show, status: :ok, location: @menuavailability }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menuavailability.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menuavailabilities/1 or /menuavailabilities/1.json
  def destroy
    @menuavailability.destroy!

    respond_to do |format|
      format.html { redirect_to menuavailabilities_url, notice: "Menuavailability was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menuavailability
      @menuavailability = Menuavailability.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def menuavailability_params
      params.require(:menuavailability).permit(:dayofweek, :starthour, :startmin, :endhour, :endmin, :menu_id)
    end
end
