require 'securerandom'

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
        @restaurant = Restaurant.find(params[:restaurant_id])
        @tablesettings = policy_scope(Tablesetting).where(restaurant: @restaurant, archived: false)
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
    @restaurant = @tablesetting.restaurant
    # Sanitize the status input to prevent XSS in QR code generation
    sanitized_status = ActionController::Base.helpers.sanitize(@tablesetting.status.to_s)
    @qr = RQRCode::QRCode.new(sanitized_status)
    @menus = Menu.joins(:restaurant).all
  end

  # GET /tablesettings/new
  def new
    @tablesetting = Tablesetting.new
    if params[:restaurant_id]
      @restaurant = Restaurant.find(params[:restaurant_id])
      @tablesetting.restaurant = @restaurant
    end
    authorize @tablesetting
  end

  # GET /tablesettings/1/edit
  def edit
    @restaurant = @tablesetting.restaurant
    authorize @tablesetting
  end

  # POST /tablesettings or /tablesettings.json
  def create
    @tablesetting = Tablesetting.new(tablesetting_params)
    authorize @tablesetting

    respond_to do |format|
      if @tablesetting.save
        ensure_smartmenus_for_new_table!(@tablesetting)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('tables_new_tablesetting', ''),
            turbo_stream.replace('restaurant_content', partial: 'restaurants/sections/tables_2025', locals: { restaurant: @tablesetting.restaurant, filter: 'all' })
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(id: @tablesetting.restaurant.id),
                      notice: t('common.flash.created', resource: t('activerecord.models.tablesetting'))
        end
        # format.html { redirect_to tablesetting_url(@tablesetting), notice: "Tablesetting was successfully created." }
        format.json do
          render :show, status: :created, location: restaurant_tablesetting_url(@restaurant, @tablesetting)
        end
      else
        format.turbo_stream { render :new, status: :unprocessable_entity }
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
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('tables_edit_tablesetting', ''),
            turbo_stream.replace(
              'restaurant_content',
              partial: 'restaurants/sections/tables_2025',
              locals: { restaurant: @tablesetting.restaurant, filter: 'all' }
            )
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(id: @tablesetting.restaurant.id),
                      notice: t('common.flash.updated', resource: t('activerecord.models.tablesetting'))
        end
        format.json { render :show, status: :ok, location: restaurant_tablesetting_url(@restaurant, @tablesetting) }
      else
        format.turbo_stream { render :edit, status: :unprocessable_entity }
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

  def ensure_smartmenus_for_new_table!(tablesetting)
    restaurant = tablesetting.restaurant

    Menu.where(restaurant_id: restaurant.id).find_each do |menu|
      Smartmenu.find_or_create_by!(
        restaurant_id: restaurant.id,
        menu_id: menu.id,
        tablesetting_id: tablesetting.id
      ) do |sm|
        sm.slug = SecureRandom.uuid
      end
    end

    Smartmenu.find_or_create_by!(
      restaurant_id: restaurant.id,
      menu_id: nil,
      tablesetting_id: tablesetting.id
    ) do |sm|
      sm.slug = SecureRandom.uuid
    end
  end

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
