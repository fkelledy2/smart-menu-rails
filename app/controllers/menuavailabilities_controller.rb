class MenuavailabilitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_menuavailability, only: %i[show edit update destroy]
  before_action :ensure_owner_restaurant_context_for_menu!, only: %i[new edit create update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /menuavailabilities or /menuavailabilities.json
  def index
    if params[:menu_id]
      @menu = Menu.find_by(id: params[:menu_id])
      @menuavailabilities = policy_scope(Menuavailability).where(menu: @menu)
    else
      @menuavailabilities = policy_scope(Menuavailability)
    end
  end

  # GET /menuavailabilities/1 or /menuavailabilities/1.json
  def show
    authorize @menuavailability
  end

  # GET /menuavailabilities/new
  def new
    @menuavailability = Menuavailability.new
    if params[:menu_id]
      @futureParentMenu = Menu.find(params[:menu_id])
      @menuavailability.menu = @futureParentMenu
    end
    authorize @menuavailability
  end

  # GET /menuavailabilities/1/edit
  def edit
    authorize @menuavailability
  end

  # POST /menuavailabilities or /menuavailabilities.json
  def create
    @menuavailability = Menuavailability.new(menuavailability_params)
    authorize @menuavailability

    respond_to do |format|
      if @menuavailability.save
        format.html do
          redirect_to edit_restaurant_menu_url(@menuavailability.menu.restaurant, @menuavailability.menu),
                      notice: t('common.flash.created', resource: t('activerecord.models.menuavailability'))
        end
        format.json do
          render :show, status: :created,
                        location: restaurant_menu_menuavailability_url(@menuavailability.menu.restaurant, @menuavailability.menu, @menuavailability)
        end
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @menuavailability.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /menuavailabilities/1 or /menuavailabilities/1.json
  def update
    authorize @menuavailability

    respond_to do |format|
      if @menuavailability.update(menuavailability_params)
        format.html do
          redirect_to edit_restaurant_menu_url(@menuavailability.menu.restaurant, @menuavailability.menu),
                      notice: t('common.flash.updated', resource: t('activerecord.models.menuavailability'))
        end
        format.json do
          render :show, status: :ok,
                        location: restaurant_menu_menuavailability_url(@menuavailability.menu.restaurant, @menuavailability.menu, @menuavailability)
        end
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @menuavailability.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /menuavailabilities/1 or /menuavailabilities/1.json
  def destroy
    authorize @menuavailability

    @menuavailability.update(archived: true)
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_menu_url(@menuavailability.menu.restaurant, @menuavailability.menu),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.menuavailability'))
      end
      format.json { head :no_content }
    end
  end

  private

  def ensure_owner_restaurant_context_for_menu!
    return if params[:restaurant_id].blank?

    menu = if defined?(@menuavailability) && @menuavailability&.menu
             @menuavailability.menu
           elsif defined?(@futureParentMenu) && @futureParentMenu
             @futureParentMenu
           elsif params[:menu_id]
             Menu.find_by(id: params[:menu_id])
           elsif params.dig(:menuavailability, :menu_id)
             Menu.find_by(id: params.dig(:menuavailability, :menu_id))
           end

    return unless menu

    owner_restaurant_id = menu.owner_restaurant_id.presence || menu.restaurant_id
    return if owner_restaurant_id.blank?
    return if params[:restaurant_id].to_i == owner_restaurant_id

    redirect_to edit_restaurant_path(params[:restaurant_id], section: 'menus'), alert: 'This menu is read-only for this restaurant'
  end

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
