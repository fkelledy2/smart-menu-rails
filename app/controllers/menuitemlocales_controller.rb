class MenuitemlocalesController < ApplicationController
  before_action :set_menuitemlocale, only: %i[ show edit update destroy ]

  # GET /menuitemlocales or /menuitemlocales.json
  def index
    @menuitemlocales = Menuitemlocale.all
  end

  # GET /menuitemlocales/1 or /menuitemlocales/1.json
  def show
  end

  # GET /menuitemlocales/new
  def new
    @menuitemlocale = Menuitemlocale.new
  end

  # GET /menuitemlocales/1/edit
  def edit
  end

  # POST /menuitemlocales or /menuitemlocales.json
  def create
    @menuitemlocale = Menuitemlocale.new(menuitemlocale_params)

    respond_to do |format|
      if @menuitemlocale.save
        format.html { redirect_to @menuitemlocale, notice: "Menuitemlocale was successfully created." }
        format.json { render :show, status: :created, location: @menuitemlocale }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menuitemlocale.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menuitemlocales/1 or /menuitemlocales/1.json
  def update
    respond_to do |format|
      if @menuitemlocale.update(menuitemlocale_params)
        format.html { redirect_to @menuitemlocale, notice: "Menuitemlocale was successfully updated." }
        format.json { render :show, status: :ok, location: @menuitemlocale }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menuitemlocale.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menuitemlocales/1 or /menuitemlocales/1.json
  def destroy
    @menuitemlocale.destroy!

    respond_to do |format|
      format.html { redirect_to menuitemlocales_path, status: :see_other, notice: "Menuitemlocale was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menuitemlocale
      @menuitemlocale = Menuitemlocale.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def menuitemlocale_params
      params.require(:menuitemlocale).permit(:locale, :status, :name, :description, :menuitem_id)
    end
end
