class InventoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inventory, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /inventories or /inventories.json
  def index
    @inventories = policy_scope(Inventory)
      .where(archived: false)
      .includes(menuitem: { menusection: { menu: :restaurant } })
  end

  # GET /inventories/1 or /inventories/1.json
  def show
    authorize @inventory
  end

  # GET /restaurants/:restaurant_id/inventories/new
  def new
    @inventory = Inventory.new
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
    end
    authorize @inventory
  end

  # GET /inventories/1/edit
  def edit
    authorize @inventory
  end

  # POST /inventories or /inventories.json
  def create
    @inventory = Inventory.new(inventory_params)
    authorize @inventory

    respond_to do |format|
      if @inventory.save
        format.html do
          redirect_to edit_menusection_path(@inventory.menuitem.menusection),
                      notice: t('common.flash.created', resource: t('activerecord.models.inventory'))
        end
        format.json { render :show, status: :created, location: @inventory }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @inventory.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventories/1 or /inventories/1.json
  def update
    authorize @inventory

    respond_to do |format|
      if @inventory.update(inventory_params)
        if @inventory.currentinventory > @inventory.startinginventory
          @inventory.currentinventory = @inventory.startinginventory
          @inventory.save
        end
        format.html do
          redirect_to edit_menusection_path(@inventory.menuitem.menusection),
                      notice: t('common.flash.updated', resource: t('activerecord.models.inventory'))
        end
        format.json { render :show, status: :ok, location: @inventory }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @inventory.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventories/1 or /inventories/1.json
  def destroy
    authorize @inventory

    @inventory.update(archived: true)
    respond_to do |format|
      format.html do
        redirect_to edit_menusection_path(@inventory.menuitem.menusection),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.inventory'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_inventory
    @inventory = Inventory.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def inventory_params
    params.require(:inventory).permit(:startinginventory, :currentinventory, :resethour, :menuitem_id, :status,
                                      :sequence,)
  end
end
