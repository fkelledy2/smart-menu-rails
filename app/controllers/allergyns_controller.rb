class AllergynsController < ApplicationController
  before_action :set_allergyn, only: %i[ show edit update destroy ]

  # GET /allergyns or /allergyns.json
  def index
    @allergyns = Allergyn.all
  end

  # GET /allergyns/1 or /allergyns/1.json
  def show
  end

  # GET /allergyns/new
  def new
    @allergyn = Allergyn.new
  end

  # GET /allergyns/1/edit
  def edit
  end

  # POST /allergyns or /allergyns.json
  def create
    @allergyn = Allergyn.new(allergyn_params)

    respond_to do |format|
      if @allergyn.save
        format.html { redirect_to allergyn_url(@allergyn), notice: "Allergyn was successfully created." }
        format.json { render :show, status: :created, location: @allergyn }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @allergyn.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /allergyns/1 or /allergyns/1.json
  def update
    respond_to do |format|
      if @allergyn.update(allergyn_params)
        format.html { redirect_to allergyn_url(@allergyn), notice: "Allergyn was successfully updated." }
        format.json { render :show, status: :ok, location: @allergyn }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @allergyn.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /allergyns/1 or /allergyns/1.json
  def destroy
    @allergyn.destroy!

    respond_to do |format|
      format.html { redirect_to allergyns_url, notice: "Allergyn was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_allergyn
      @allergyn = Allergyn.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def allergyn_params
      params.require(:allergyn).permit(:name, :description, :symbol, :menuitem_id)
    end
end
