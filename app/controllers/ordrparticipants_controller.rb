class OrdrparticipantsController < ApplicationController
  before_action :set_ordrparticipant, only: %i[ show edit update destroy ]

  # GET /ordrparticipants or /ordrparticipants.json
  def index
    @ordrparticipants = Ordrparticipant.all
  end

  # GET /ordrparticipants/1 or /ordrparticipants/1.json
  def show
  end

  # GET /ordrparticipants/new
  def new
    @ordrparticipant = Ordrparticipant.new
  end

  # GET /ordrparticipants/1/edit
  def edit
  end

  # POST /ordrparticipants or /ordrparticipants.json
  def create
    @ordrparticipant = Ordrparticipant.new(ordrparticipant_params)

    respond_to do |format|
      if @ordrparticipant.save
        format.html { redirect_to ordrparticipant_url(@ordrparticipant), notice: "Ordrparticipant was successfully created." }
        format.json { render :show, status: :created, location: @ordrparticipant }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ordrparticipant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ordrparticipants/1 or /ordrparticipants/1.json
  def update
    respond_to do |format|
      if @ordrparticipant.update(ordrparticipant_params)
        format.html { redirect_to ordrparticipant_url(@ordrparticipant), notice: "Ordrparticipant was successfully updated." }
        format.json { render :show, status: :ok, location: @ordrparticipant }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ordrparticipant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ordrparticipants/1 or /ordrparticipants/1.json
  def destroy
    @ordrparticipant.destroy!

    respond_to do |format|
      format.html { redirect_to ordrparticipants_url, notice: "Ordrparticipant was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ordrparticipant
      @ordrparticipant = Ordrparticipant.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ordrparticipant_params
      params.require(:ordrparticipant).permit(:sessionid, :action, :role, :employee_id, :ordr_id, :ordritem_id)
    end
end
