class MenuavailabilitiesController < ApplicationController
  before_action :set_menuavailability, only: %i[ show edit update destroy ]

  # GET /menuavailabilities or /menuavailabilities.json
  def index
    if current_user
      @menuavailabilities = []
      if params[:menu_id]
        @menu = Menu.find_by_id(params[:menu_id])
        @menuavailabilities += @menu.menuavailabilities
      end
    else
      redirect_to root_url
    end
  end

  # GET /menuavailabilities/1 or /menuavailabilities/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /menuavailabilities/new
  def new
    if current_user
        @menuavailability = Menuavailability.new
    else
        redirect_to root_url
    end
  end

  # GET /menuavailabilities/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /menuavailabilities or /menuavailabilities.json
  def create
    if current_user
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
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /menuavailabilities/1 or /menuavailabilities/1.json
  def update
    if current_user
        respond_to do |format|
          if @menuavailability.update(menuavailability_params)
            format.html { redirect_to menuavailability_url(@menuavailability), notice: "Menuavailability was successfully updated." }
            format.json { render :show, status: :ok, location: @menuavailability }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @menuavailability.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /menuavailabilities/1 or /menuavailabilities/1.json
  def destroy
    if current_user
        @menuavailability.update( archived: true )
        respond_to do |format|
          format.html { redirect_to menuavailabilities_url, notice: "Menuavailability was successfully destroyed." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menuavailability
      @menuavailability = Menuavailability.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def menuavailability_params
      params.require(:menuavailability).permit(:dayofweek, :starthour, :startmin, :endhour, :endmin, :status, :sequence, :menu_id)
    end
end
