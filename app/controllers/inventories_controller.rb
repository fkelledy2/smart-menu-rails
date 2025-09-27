class InventoriesController < ApplicationController
  before_action :set_inventory, only: %i[ show edit update destroy ]

  # GET /inventories or /inventories.json
  def index
    if current_user
      @inventories = Inventory.joins(menuitem: { menusection: { menu: :restaurant } })
        .where(
          restaurants: { user_id: current_user.id, archived: false },
          menus: { archived: false },
          menusections: { archived: false },
          menuitems: { archived: false },
          inventories: { archived: false }
        )
        .includes(menuitem: { menusection: { menu: :restaurant } })
    else
      redirect_to root_url
    end
  end

  # GET /inventories/1 or /inventories/1.json
  def show
    if current_user
    else
        redirect_to root_url
    end
  end

  # GET /inventories/new
  def new
    if current_user
        @inventory = Inventory.new
    else
        redirect_to root_url
    end
  end

  # GET /inventories/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /inventories or /inventories.json
  def create
    if current_user
        @inventory = Inventory.new(inventory_params)
        respond_to do |format|
          if @inventory.save
            format.html { redirect_to edit_menusection_path(@inventory.menuitem.menusection), notice: t('inventories.controller.created') }
            format.json { render :show, status: :created, location: @inventory }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @inventory.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /inventories/1 or /inventories/1.json
  def update
    if current_user
        respond_to do |format|
          if @inventory.update(inventory_params)
            if @inventory.currentinventory > @inventory.startinginventory
                @inventory.currentinventory = @inventory.startinginventory
                @inventory.save
            end
            format.html { redirect_to edit_menusection_path(@inventory.menuitem.menusection), notice: t('inventories.controller.updated') }
            format.json { render :show, status: :ok, location: @inventory }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @inventory.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /inventories/1 or /inventories/1.json
  def destroy
    if current_user
        @inventory.update( archived: true )
        respond_to do |format|
          format.html { redirect_to edit_menusection_path(@inventory.menuitem.menusection), notice: t('inventories.controller.deleted') }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inventory
      @inventory = Inventory.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def inventory_params
      params.require(:inventory).permit(:startinginventory, :currentinventory, :resethour, :menuitem_id, :status, :sequence)
    end
end
