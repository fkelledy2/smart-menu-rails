class MenuavailabilitiesController < ApplicationController
  before_action :set_menuavailability, only: %i[show edit update destroy]

  # GET /menuavailabilities or /menuavailabilities.json
  def index
    if current_user
      @menuavailabilities = []
      if params[:menu_id]
        @menu = Menu.find_by(id: params[:menu_id])
        @menuavailabilities += @menu.menuavailabilities
      end
    else
      redirect_to root_url
    end
  end

  # GET /menuavailabilities/1 or /menuavailabilities/1.json
  def show
    unless current_user
      redirect_to root_url
    end
  end

  # GET /menuavailabilities/new
  def new
    if current_user
      @menuavailability = Menuavailability.new
      if params[:menu_id]
        @futureParentMenu = Menu.find(params[:menu_id])
        @menuavailability.menu = @futureParentMenu
      end
    else
      redirect_to root_url
    end
  end

  # GET /menuavailabilities/1/edit
  def edit
    unless current_user
      redirect_to root_url
    end
  end

  # POST /menuavailabilities or /menuavailabilities.json
  def create
    if current_user
      @menuavailability = Menuavailability.new(menuavailability_params)
      respond_to do |format|
        if @menuavailability.save
          format.html do
            redirect_to edit_menu_url(@menuavailability.menu),
                        notice: t('common.flash.created', resource: t('activerecord.models.menuavailability'))
          end
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
          format.html do
            redirect_to edit_menu_url(@menuavailability.menu),
                        notice: t('common.flash.updated', resource: t('activerecord.models.menuavailability'))
          end
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
      @menuavailability.update(archived: true)
      respond_to do |format|
        format.html do
          redirect_to edit_menu_url(@menuavailability.menu),
                      notice: t('common.flash.deleted', resource: t('activerecord.models.menuavailability'))
        end
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
    params.require(:menuavailability).permit(:dayofweek, :starthour, :startmin, :endhour, :endmin, :status,
                                             :sequence, :menu_id,)
  end
end
