class RestaurantMenusController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant

  skip_around_action :switch_locale, only: %i[reorder bulk_update bulk_availability availability]

  # Pundit authorization
  after_action :verify_authorized, except: %i[reorder bulk_update bulk_availability availability]
  after_action :verify_policy_scoped, unless: -> { true }

  # PATCH /restaurants/:restaurant_id/restaurant_menus/reorder
  def reorder
    order = params[:order]
    unless order.is_a?(Array)
      return render json: { status: 'error', message: 'Invalid order payload' }, status: :unprocessable_entity
    end

    scope = policy_scope(RestaurantMenu).where(restaurant_id: @restaurant.id)

    RestaurantMenu.transaction do
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

        rm = scope.find(id)
        authorize rm, :update?
        rm.update_column(:sequence, seq.to_i)
      end
    end

    render json: { status: 'success', message: 'Menus reordered successfully' }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Menu attachment not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("RestaurantMenus reorder error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: { status: 'error', message: e.message }, status: :unprocessable_entity
  end

  # PATCH /restaurants/:restaurant_id/restaurant_menus/bulk_update
  def bulk_update
    scope = policy_scope(RestaurantMenu).where(restaurant_id: @restaurant.id)

    ids = Array(params[:restaurant_menu_ids]).map(&:to_s).reject(&:blank?)
    status = params[:status].to_s

    if ids.empty? || status.blank?
      return respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/menus_2025',
            locals: { restaurant: @restaurant, filter: 'all' }
          )
        end
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'menus') }
      end
    end

    scope.where(id: ids).find_each do |rm|
      authorize rm, :update?
      rm.update(status: status)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/menus_2025',
          locals: { restaurant: @restaurant, filter: 'all' }
        )
      end
      format.html { redirect_to edit_restaurant_path(@restaurant, section: 'menus') }
    end
  end

  # PATCH /restaurants/:restaurant_id/restaurant_menus/bulk_availability
  def bulk_availability
    scope = policy_scope(RestaurantMenu).where(restaurant_id: @restaurant.id)

    ids = Array(params[:restaurant_menu_ids]).map(&:to_s).reject(&:blank?)
    enabled = ActiveModel::Type::Boolean.new.cast(params[:availability_override_enabled])
    state = params[:availability_state].to_s

    if ids.empty? || state.blank?
      return respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/menus_2025',
            locals: { restaurant: @restaurant, filter: 'all' }
          )
        end
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'menus') }
      end
    end

    scope.where(id: ids).find_each do |rm|
      authorize rm, :update?
      rm.update(availability_override_enabled: enabled, availability_state: state)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/menus_2025',
          locals: { restaurant: @restaurant, filter: 'all' }
        )
      end
      format.html { redirect_to edit_restaurant_path(@restaurant, section: 'menus') }
    end
  end

  # PATCH /restaurants/:restaurant_id/restaurant_menus/:id/availability
  def availability
    rm = policy_scope(RestaurantMenu).where(restaurant_id: @restaurant.id).find(params[:id])
    authorize rm, :update?

    enabled = ActiveModel::Type::Boolean.new.cast(params[:availability_override_enabled])
    state = params[:availability_state].to_s

    rm.update(availability_override_enabled: enabled, availability_state: state)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'restaurant_content',
          partial: 'restaurants/sections/menus_2025',
          locals: { restaurant: @restaurant, filter: 'all' }
        )
      end
      format.html { redirect_to edit_restaurant_path(@restaurant, section: 'menus') }
      format.json { render json: { status: 'success' } }
    end
  end

  private

  def set_restaurant
    @restaurant = current_user.restaurants.find(params[:restaurant_id])
  end
end
