class InventoriesController < ApplicationController
  before_action :set_inventory, only: %i[ show edit update destroy ]

  # GET /inventories or /inventories.json
  def index
    if current_user
        @inventories = []
        Restaurant.where( user: current_user, archived: false).each do |restaurant|
            Menu.where( restaurant: restaurant, archived: false).each do |menu|
                Menusection.where( menu: menu, archived: false).each do |menusection|
                    Menuitem.where( menusection: menusection, archived: false).each do |menuitem|
                        @inventories += Inventory.where( menuitem: menuitem, archived: false).all
                    end
                end
            end
        end
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
            format.html { redirect_to inventory_url(@inventory), notice: "Inventory was successfully created." }
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
            format.html { redirect_to edit_menusection_path(@inventory.menuitem.menusection), notice: "Inventory was successfully updated." }
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
          format.html { redirect_to edit_menusection_path(@inventory.menuitem.menusection), notice: "Inventory was successfully deleted." }
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
