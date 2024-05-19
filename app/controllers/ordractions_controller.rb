class OrdractionsController < ApplicationController
  before_action :set_ordraction, only: %i[ show edit update destroy ]

  # GET /ordractions or /ordractions.json
  def index
    if current_user
        @ordractions = Ordraction.all
    else
        redirect_to root_url
    end
  end

  # GET /ordractions/1 or /ordractions/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /ordractions/new
  def new
    if current_user
        @ordraction = Ordraction.new
    else
        redirect_to root_url
    end
  end

  # GET /ordractions/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /ordractions or /ordractions.json
  def create
    if current_user
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
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /ordractions/1 or /ordractions/1.json
  def update
    if current_user
        respond_to do |format|
          if @ordraction.update(ordraction_params)
            format.html { redirect_to ordraction_url(@ordraction), notice: "Ordraction was successfully updated." }
            format.json { render :show, status: :ok, location: @ordraction }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @ordraction.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /ordractions/1 or /ordractions/1.json
  def destroy
    if current_user
        @ordraction.destroy!
        respond_to do |format|
          format.html { redirect_to ordractions_url, notice: "Ordraction was successfully destroyed." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
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
