require 'securerandom'

class TablesettingsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show] # Allow public viewing for customers
  before_action :set_tablesetting, only: %i[show edit update destroy]

  skip_around_action :switch_locale, only: %i[reorder bulk_update bulk_create new_bulk_create]

  # Pundit authorization
  after_action :verify_authorized, except: %i[index show reorder bulk_update bulk_create new_bulk_create]
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
            turbo_stream.replace('restaurant_content', partial: 'restaurants/sections/tables_2025', locals: { restaurant: @tablesetting.restaurant, filter: 'all' }),
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
        format.turbo_stream { render :new, status: :unprocessable_content }
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @tablesetting.errors, status: :unprocessable_content }
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
              locals: { restaurant: @tablesetting.restaurant, filter: 'all' },
            ),
          ]
        end
        format.html do
          redirect_to edit_restaurant_path(id: @tablesetting.restaurant.id),
                      notice: t('common.flash.updated', resource: t('activerecord.models.tablesetting'))
        end
        format.json { render :show, status: :ok, location: restaurant_tablesetting_url(@restaurant, @tablesetting) }
      else
        format.turbo_stream { render :edit, status: :unprocessable_content }
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @tablesetting.errors, status: :unprocessable_content }
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

  # GET /restaurants/:restaurant_id/tablesettings/new_bulk_create
  def new_bulk_create
    @restaurant = Restaurant.find(params[:restaurant_id])
    authorize @restaurant, :update?, policy_class: RestaurantPolicy

    render inline: '<%= turbo_frame_tag "tables_bulk_create" do %><%= render partial: "tablesettings/bulk_create_form", locals: { restaurant: @restaurant } %><% end %>',
           layout: false
  end

  # POST /restaurants/:restaurant_id/tablesettings/bulk_create
  def bulk_create
    restaurant = Restaurant.find(params[:restaurant_id])
    authorize restaurant, :update?, policy_class: RestaurantPolicy

    prefix = (params[:prefix].presence || 'T')[0, 1]
    count  = params[:count].to_i.clamp(1, 200)
    tabletype = %w[indoor outdoor].include?(params[:tabletype]) ? params[:tabletype] : 'indoor'
    capacity  = [params[:capacity].to_i, 1].max

    # Auto-detect next start number by scanning existing tables with the same prefix
    existing_numbers = restaurant.tablesettings
      .where(archived: false)
      .where('name LIKE ?', "#{Tablesetting.sanitize_sql_like(prefix)}%")
      .pluck(:name)
      .filter_map { |n| n.delete_prefix(prefix).to_i if n.start_with?(prefix) && n.delete_prefix(prefix).match?(/\A\d+\z/) }

    start_number = (existing_numbers.max || 0) + 1
    max_sequence = restaurant.tablesettings.maximum(:sequence).to_i

    created_count = 0
    Tablesetting.transaction do
      count.times do |i|
        num = start_number + i
        table = restaurant.tablesettings.create!(
          name: "#{prefix}#{num}",
          status: :free,
          tabletype: tabletype,
          capacity: capacity,
          sequence: max_sequence + i + 1,
        )
        ensure_smartmenus_for_new_table!(table)
        created_count += 1
      end
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace('tables_bulk_create', ''),
          turbo_stream.replace('restaurant_content',
            partial: 'restaurants/sections/tables_2025',
            locals: { restaurant: restaurant, filter: 'all' }),
        ]
      end
      format.html do
        redirect_to edit_restaurant_path(restaurant, section: 'tables'),
                    notice: "#{created_count} tables created (#{prefix}#{start_number}–#{prefix}#{start_number + count - 1})"
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace('tables_bulk_create',
          partial: 'tablesettings/bulk_create_form',
          locals: { restaurant: restaurant, error: e.message })
      end
      format.html do
        redirect_to edit_restaurant_path(restaurant, section: 'tables'),
                    alert: "Bulk create failed: #{e.message}"
      end
    end
  end

  # PATCH /restaurants/:restaurant_id/tablesettings/bulk_update
  def bulk_update
    restaurant = Restaurant.find(params[:restaurant_id])
    tables = policy_scope(Tablesetting).where(restaurant_id: restaurant.id, archived: false)

    ids = Array(params[:tablesetting_ids]).map(&:to_s).compact_blank
    status = params[:status].to_s

    if ids.empty? || status.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/tables_2025',
            locals: { restaurant: restaurant, filter: 'all' },
          )
        end
        format.html do
          redirect_to edit_restaurant_path(restaurant, section: 'tables')
        end
      end
      return
    end

    to_update = tables.where(id: ids)
    to_update.find_each do |t|
      authorize t, :update?
      t.update(status: status)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/tables_2025',
          locals: { restaurant: restaurant, filter: 'all' },
        )
      end
      format.html do
        redirect_to edit_restaurant_path(restaurant, section: 'tables')
      end
    end
  end

  # PATCH /restaurants/:restaurant_id/tablesettings/reorder
  def reorder
    restaurant = Restaurant.find(params[:restaurant_id])
    tables = policy_scope(Tablesetting).where(restaurant_id: restaurant.id, archived: false)

    order = params[:order]
    unless order.is_a?(Array)
      return render json: { status: 'error', message: 'Invalid order payload' }, status: :unprocessable_content
    end

    Tablesetting.transaction do
      order.each do |item|
        item_hash = if item.is_a?(ActionController::Parameters)
                      item.to_unsafe_h
                    elsif item.is_a?(Hash)
                      item
                    else
                      next
                    end

        id = item_hash[:id] || item_hash['id']
        seq = item_hash[:sequence] || item_hash['sequence']
        next if id.blank? || seq.nil?

        t = tables.find(id)
        authorize t, :update?
        t.update_column(:sequence, seq.to_i)
      end
    end

    render json: { status: 'success', message: 'Tables reordered successfully' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Table not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("Tablesettings reorder error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: { status: 'error', message: e.message }, status: :unprocessable_content
  end

  private

  def ensure_smartmenus_for_new_table!(tablesetting)
    restaurant = tablesetting.restaurant

    Menu.where(restaurant_id: restaurant.id).find_each do |menu|
      Smartmenu.find_or_create_by!(
        restaurant_id: restaurant.id,
        menu_id: menu.id,
        tablesetting_id: tablesetting.id,
      ) do |sm|
        sm.slug = SecureRandom.uuid
      end
    end

    Smartmenu.find_or_create_by!(
      restaurant_id: restaurant.id,
      menu_id: nil,
      tablesetting_id: tablesetting.id,
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
