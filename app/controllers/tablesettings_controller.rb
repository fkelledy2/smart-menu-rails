class TablesettingsController < ApplicationController
  before_action :set_tablesetting, only: %i[ show edit update destroy ]

  # GET /tablesettings or /tablesettings.json
  def index
    @today = Date.today.strftime('%A').downcase!
    @currentHour = Time.now.strftime("%H").to_i
    @currentMin = Time.now.strftime("%M").to_i
    @currentDay = Time.now.wday.to_i
    if current_user
        if params[:restaurant_id]
            @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
            @tablesettings = Tablesetting.joins(:restaurant).where(restaurant: @futureParentRestaurant, archived: false).all
        else
            @tablesettings = Tablesetting.joins(:restaurant).where(restaurant: {user: current_user}, archived: false).all
        end
    else
        @restaurant = Restaurant.find_by_id(params[:restaurant_id])
        @tablesettings = Tablesetting.joins(:restaurant).where(archived: false).all
        @menus = Menu.joins(:restaurant).where(archived: false).all
    end
  end

  # GET /tablesettings/1 or /tablesettings/1.json
  def show
    @restaurant = Restaurant.find_by_id(params[:restaurant_id])
    @qr = RQRCode::QRCode.new(@tablesetting.status)
    @menus = Menu.joins(:restaurant).all
  end

  # GET /tablesettings/new
  def new
    if current_user
        @tablesetting = Tablesetting.new
        if params[:restaurant_id]
            @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
            @tablesetting.restaurant = @futureParentRestaurant
        end
    else
        redirect_to root_url
    end
  end

  # GET /tablesettings/1/edit
  def edit
    if current_user
    else
        redirect_to root_url
    end
  end

  # POST /tablesettings or /tablesettings.json
  def create
    if current_user
        @tablesetting = Tablesetting.new(tablesetting_params)
        respond_to do |format|
          if @tablesetting.save
            format.html { redirect_to edit_restaurant_path(id: @tablesetting.restaurant.id), notice: "Tablesetting was successfully created." }
            # format.html { redirect_to tablesetting_url(@tablesetting), notice: "Tablesetting was successfully created." }
            format.json { render :show, status: :created, location: @tablesetting }
          else
            format.html { render :new, status: :unprocessable_entity }
          puts @tablesetting.errors.to_json
            format.json { render json: @tablesetting.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # PATCH/PUT /tablesettings/1 or /tablesettings/1.json
  def update
    if current_user
        respond_to do |format|
          if @tablesetting.update(tablesetting_params)
            format.html { redirect_to edit_restaurant_path(id: @tablesetting.restaurant.id), notice: "Tablesetting was successfully updated." }
            format.json { render :show, status: :ok, location: @tablesetting }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @tablesetting.errors, status: :unprocessable_entity }
          end
        end
    else
        redirect_to root_url
    end
  end

  # DELETE /tablesettings/1 or /tablesettings/1.json
  def destroy
    if current_user
        @tablesetting.update( archived: true )
        respond_to do |format|
          format.html { redirect_to edit_restaurant_path(id: @tablesetting.restaurant.id), notice: "Tablesetting was successfully deleted." }
          format.json { head :no_content }
        end
    else
        redirect_to root_url
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tablesetting
      @today = Date.today.strftime('%A').downcase!
      @currentHour = Time.now.strftime("%H").to_i
      @currentMin = Time.now.strftime("%M").to_i
      @currentDay = Time.now.wday.to_i
      @tablesetting = Tablesetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tablesetting_params
      params.require(:tablesetting).permit(:name, :description, :status, :sequence, :tabletype, :capacity, :restaurant_id)
    end
end
