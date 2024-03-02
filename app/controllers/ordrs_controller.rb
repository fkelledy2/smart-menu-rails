class OrdrsController < ApplicationController
  before_action :set_ordr, only: %i[ show edit update destroy ]

  # GET /ordrs or /ordrs.json
  def index
    @ordrs = Ordr.all
  end

  # GET /ordrs/1 or /ordrs/1.json
  def show
  end

  # GET /ordrs/new
  def new
    @ordr = Ordr.new
  end

  # GET /ordrs/1/edit
  def edit
  end

  # POST /ordrs or /ordrs.json
  def create
    @ordr = Ordr.new(ordr_params)

    respond_to do |format|
      if @ordr.save
        format.html { redirect_to ordr_url(@ordr), notice: "Ordr was successfully created." }
        format.json { render :show, status: :created, location: @ordr }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ordr.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ordrs/1 or /ordrs/1.json
  def update
    respond_to do |format|
      if @ordr.update(ordr_params)
        format.html { redirect_to ordr_url(@ordr), notice: "Ordr was successfully updated." }
        format.json { render :show, status: :ok, location: @ordr }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ordr.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ordrs/1 or /ordrs/1.json
  def destroy
    @ordr.destroy!

    respond_to do |format|
      format.html { redirect_to ordrs_url, notice: "Ordr was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ordr
      @ordr = Ordr.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ordr_params
      params.require(:ordr).permit(:orderedAt, :deliveredAt, :paidAt, :nett, :tip, :service, :tax, :gross, :employee_id, :tablesetting_id, :menu_id, :restaurant_id)
    end
end
