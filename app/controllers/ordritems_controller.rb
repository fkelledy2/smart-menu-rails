class OrdritemsController < ApplicationController
  before_action :set_ordritem, only: %i[ show edit update destroy ]

  # GET /ordritems or /ordritems.json
  def index
    @ordritems = Ordritem.all
  end

  # GET /ordritems/1 or /ordritems/1.json
  def show
  end

  # GET /ordritems/new
  def new
    @ordritem = Ordritem.new
  end

  # GET /ordritems/1/edit
  def edit
  end

  # POST /ordritems or /ordritems.json
  def create
    @ordritem = Ordritem.new(ordritem_params)

    respond_to do |format|
      if @ordritem.save
        format.html { redirect_to ordritem_url(@ordritem), notice: "Ordritem was successfully created." }
        format.json { render :show, status: :created, location: @ordritem }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ordritem.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ordritems/1 or /ordritems/1.json
  def update
    respond_to do |format|
      if @ordritem.update(ordritem_params)
        format.html { redirect_to ordritem_url(@ordritem), notice: "Ordritem was successfully updated." }
        format.json { render :show, status: :ok, location: @ordritem }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ordritem.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ordritems/1 or /ordritems/1.json
  def destroy
    @ordritem.destroy!

    respond_to do |format|
      format.html { redirect_to ordritems_url, notice: "Ordritem was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ordritem
      @ordritem = Ordritem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ordritem_params
      params.require(:ordritem).permit(:ordr_id, :menuitem_id, :ordritemprice)
    end
end
