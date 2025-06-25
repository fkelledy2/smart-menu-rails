class MenuparticipantsController < ApplicationController
  before_action :set_menuparticipant, only: %i[ show edit update destroy ]

  # GET /menuparticipants or /menuparticipants.json
  def index
    @menuparticipants = Menuparticipant.all
  end

  # GET /menuparticipants/1 or /menuparticipants/1.json
  def show
  end

  # GET /menuparticipants/new
  def new
    @menuparticipant = Menuparticipant.new
  end

  # GET /menuparticipants/1/edit
  def edit
  end

  # POST /menuparticipants or /menuparticipants.json
  def create
    @menuparticipant = Menuparticipant.new(menuparticipant_params)

    respond_to do |format|
      if @menuparticipant.save
        format.html { redirect_to @menuparticipant, notice: "Menuparticipant was successfully created." }
        format.json { render :show, status: :created, location: @menuparticipant }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menuparticipant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menuparticipants/1 or /menuparticipants/1.json
  def update
    respond_to do |format|
      if @menuparticipant.update(menuparticipant_params)
        format.json { render :show, status: :ok, location: @menuparticipant }
        broadcastPartials()
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menuparticipant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menuparticipants/1 or /menuparticipants/1.json
  def destroy
    @menuparticipant.destroy!

    respond_to do |format|
      format.html { redirect_to menuparticipants_path, status: :see_other, notice: "Menuparticipant was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def broadcastPartials()
        @menuparticipant = Menuparticipant.where( sessionid: session.id.to_s ).first
        if @menuparticipant
            @ordrparticipant.preferredlocale = @menuparticipant.preferredlocale
        end
        partials = {
            fullPageRefresh: { refresh: true }
        }
        ActionCable.server.broadcast("ordr_"+@menuparticipant.smartmenu.slug+"_channel", partials)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_menuparticipant
      @menuparticipant = Menuparticipant.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def menuparticipant_params
      params.require(:menuparticipant).permit(:sessionid, :preferredlocale, :smartmenu_id)
    end
end
