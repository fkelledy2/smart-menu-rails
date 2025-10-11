class TablesettingsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show] # Allow public viewing for customers
  before_action :set_tablesetting, only: %i[show edit update destroy]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index show]
  after_action :verify_policy_scoped, only: [:index]

  # GET /tablesettings or /tablesettings.json
  def index
    @today = Time.zone.today.strftime('%A').downcase!
    @currentHour = Time.now.strftime('%H').to_i
    @currentMin = Time.now.strftime('%M').to_i
    @currentDay = Time.now.wday.to_i

    if current_user
      if params[:restaurant_id]
        @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
        @tablesettings = policy_scope(Tablesetting).where(restaurant: @futureParentRestaurant, archived: false)
      else
        @tablesettings = policy_scope(Tablesetting).where(archived: false)
      end
    else
      @restaurant = Restaurant.find_by(id: params[:restaurant_id])
      @tablesettings = Tablesetting.where(restaurant: @restaurant, archived: false)
      @menus = Menu.where(restaurant: @restaurant, archived: false)
    end
  end

  # GET /tablesettings/1 or /tablesettings/1.json
  def show
    @restaurant = Restaurant.find_by(id: params[:restaurant_id])
    # Sanitize the status input to prevent XSS in QR code generation
    sanitized_status = ActionController::Base.helpers.sanitize(@tablesetting.status.to_s)
    @qr = RQRCode::QRCode.new(sanitized_status)
    @menus = Menu.joins(:restaurant).all
  end

  # GET /tablesettings/new
  def new
    @tablesetting = Tablesetting.new
    if params[:restaurant_id]
      @futureParentRestaurant = Restaurant.find(params[:restaurant_id])
      @tablesetting.restaurant = @futureParentRestaurant
    end
    authorize @tablesetting
  end

  # GET /tablesettings/1/edit
  def edit
    authorize @tablesetting
  end

  # POST /tablesettings or /tablesettings.json
  def create
    @tablesetting = Tablesetting.new(tablesetting_params)
    authorize @tablesetting

    respond_to do |format|
      if @tablesetting.save
        format.html do
          redirect_to edit_restaurant_path(id: @tablesetting.restaurant.id),
                      notice: t('common.flash.created', resource: t('activerecord.models.tablesetting'))
        end
        # format.html { redirect_to tablesetting_url(@tablesetting), notice: "Tablesetting was successfully created." }
        format.json { render :show, status: :created, location: @tablesetting }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tablesetting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tablesettings/1 or /tablesettings/1.json
  def update
    authorize @tablesetting

    respond_to do |format|
      if @tablesetting.update(tablesetting_params)
        format.html do
          redirect_to edit_restaurant_path(id: @tablesetting.restaurant.id),
                      notice: t('common.flash.updated', resource: t('activerecord.models.tablesetting'))
        end
        format.json { render :show, status: :ok, location: @tablesetting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tablesetting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tablesettings/1 or /tablesettings/1.json
  def destroy
    authorize @tablesetting

    @tablesetting.update(archived: true)
    respond_to do |format|
      format.html do
        redirect_to edit_restaurant_path(id: @tablesetting.restaurant.id),
                    notice: t('common.flash.deleted', resource: t('activerecord.models.tablesetting'))
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tablesetting
    @today = Time.zone.today.strftime('%A').downcase!
    @currentHour = Time.now.strftime('%H').to_i
    @currentMin = Time.now.strftime('%M').to_i
    @currentDay = Time.now.wday.to_i
    @tablesetting = Tablesetting.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def tablesetting_params
    params.require(:tablesetting).permit(:name, :description, :status, :sequence, :tabletype, :capacity,
                                         :restaurant_id,)
  end
end
