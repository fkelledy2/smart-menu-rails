class OrdractionsController < ApplicationController
  before_action :set_ordraction, only: %i[ show edit update destroy ]

  # GET /ordractions or /ordractions.json
  def index
    @ordractions = Ordraction.all
  end

  # GET /ordractions/1 or /ordractions/1.json
  def show
  end

  # GET /ordractions/new
  def new
    @ordraction = Ordraction.new
  end

  # GET /ordractions/1/edit
  def edit
  end

  # POST /ordractions or /ordractions.json
  def create
    @ordraction = Ordraction.new(ordraction_params)

    respond_to do |format|
      if @ordraction.save
        format.html { redirect_to ordraction_url(@ordraction), notice: "Ordraction was successfully created." }
        format.json { render :show, status: :created, location: @ordraction }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ordraction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ordractions/1 or /ordractions/1.json
  def update
    respond_to do |format|
      if @ordraction.update(ordraction_params)
        format.html { redirect_to ordraction_url(@ordraction), notice: "Ordraction was successfully updated." }
        format.json { render :show, status: :ok, location: @ordraction }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ordraction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ordractions/1 or /ordractions/1.json
  def destroy
    @ordraction.destroy!

    respond_to do |format|
      format.html { redirect_to ordractions_url, notice: "Ordraction was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ordraction
      @ordraction = Ordraction.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ordraction_params
      params.require(:ordraction).permit(:sessionid, :action, :employee_id, :ordrparticipant_id, :ordr_id, :ordritem_id)
    end
end
