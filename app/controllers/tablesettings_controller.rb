class TablesettingsController < ApplicationController
  before_action :set_tablesetting, only: %i[ show edit update destroy ]

  # GET /tablesettings or /tablesettings.json
  def index
    @tablesettings = Tablesetting.all
  end

  # GET /tablesettings/1 or /tablesettings/1.json
  def show
    @qr = RQRCode::QRCode.new(@tablesetting.status)
  end

  # GET /tablesettings/new
  def new
    @tablesetting = Tablesetting.new
  end

  # GET /tablesettings/1/edit
  def edit
  end

  # POST /tablesettings or /tablesettings.json
  def create
    @tablesetting = Tablesetting.new(tablesetting_params)

    respond_to do |format|
      if @tablesetting.save
        format.html { redirect_to tablesetting_url(@tablesetting), notice: "Tablesetting was successfully created." }
        format.json { render :show, status: :created, location: @tablesetting }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tablesetting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tablesettings/1 or /tablesettings/1.json
  def update
    respond_to do |format|
      if @tablesetting.update(tablesetting_params)
        format.html { redirect_to tablesetting_url(@tablesetting), notice: "Tablesetting was successfully updated." }
        format.json { render :show, status: :ok, location: @tablesetting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tablesetting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tablesettings/1 or /tablesettings/1.json
  def destroy
    @tablesetting.destroy!

    respond_to do |format|
      format.html { redirect_to tablesettings_url, notice: "Tablesetting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tablesetting
      @tablesetting = Tablesetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tablesetting_params
      params.require(:tablesetting).permit(:name, :description, :status, :tabletype, :capacity, :restaurant_id)
    end
end
