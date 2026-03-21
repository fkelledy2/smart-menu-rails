# frozen_string_literal: true

module Menus
  class SharingController < BaseController
    before_action :authenticate_user!
    # set_menu is intentionally skipped: the menu being attached/shared/detached
    # is not yet linked to @restaurant at the time of the request.

    # POST /restaurants/:restaurant_id/menus/:id/attach
    def attach
      menu = Menu.find(params[:id])
      restaurant_menu = RestaurantMenu.new(restaurant: @restaurant, menu: menu)
      authorize restaurant_menu, :attach?

      restaurant_menu.sequence ||= (@restaurant.restaurant_menus.maximum(:sequence).to_i + 1)
      restaurant_menu.status ||= :active
      restaurant_menu.availability_override_enabled = false if restaurant_menu.availability_override_enabled.nil?
      restaurant_menu.availability_state ||= :available
      restaurant_menu.save!

      ensure_smartmenus_for_restaurant_menu!(@restaurant, menu)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/menus_2025',
            locals: { restaurant: @restaurant, filter: 'all' },
          )
        end
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'menus') }
      end
    rescue ActiveRecord::RecordInvalid
      redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Unable to attach menu'
    end

    # POST /restaurants/:restaurant_id/menus/:id/share
    def share
      menu = Menu.find(params[:id])
      authorize RestaurantMenu.new(restaurant: @restaurant, menu: menu), :attach?

      owner_restaurant_id = menu.owner_restaurant_id.presence || menu.restaurant_id
      unless owner_restaurant_id == @restaurant.id
        return redirect_to(edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Only the owner restaurant can share this menu')
      end

      raw_target_ids = []
      raw_target_ids.concat(Array(params[:target_restaurant_ids])) if params.key?(:target_restaurant_ids)
      raw_target_ids << params[:target_restaurant_id] if params.key?(:target_restaurant_id)
      raw_target_ids = raw_target_ids.map(&:to_s).map(&:strip).compact_blank

      other_restaurant_ids = Restaurant.on_primary do
        Restaurant.where(user_id: current_user.id).where.not(id: @restaurant.id).pluck(:id)
      end

      target_ids = if raw_target_ids.include?('all')
                     other_restaurant_ids
                   else
                     raw_target_ids.map(&:to_i).reject(&:zero?)
                   end

      target_restaurants = Restaurant.on_primary do
        Restaurant.where(user_id: current_user.id).where(id: target_ids).to_a
      end

      if target_restaurants.empty?
        return redirect_to(edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Restaurant not found')
      end

      target_restaurants.each do |target_restaurant|
        restaurant_menu = RestaurantMenu.find_or_initialize_by(restaurant: target_restaurant, menu: menu)
        authorize restaurant_menu, :attach?

        next if restaurant_menu.persisted?

        restaurant_menu.sequence ||= (target_restaurant.restaurant_menus.maximum(:sequence).to_i + 1)
        restaurant_menu.status ||= :active
        restaurant_menu.availability_override_enabled = false if restaurant_menu.availability_override_enabled.nil?
        restaurant_menu.availability_state ||= :available
        restaurant_menu.save!

        ensure_smartmenus_for_restaurant_menu!(target_restaurant, menu)
      end

      redirect_to edit_restaurant_path(@restaurant, section: 'menus')
    rescue ActiveRecord::RecordNotFound
      redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Restaurant not found'
    rescue ActiveRecord::RecordInvalid
      redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Unable to share menu'
    end

    # DELETE /restaurants/:restaurant_id/menus/:id/detach
    def detach
      menu = Menu.find(params[:id])

      authorize RestaurantMenu.new(restaurant: @restaurant, menu: menu), :detach?

      owner_restaurant_id = menu.owner_restaurant_id.presence || menu.restaurant_id
      if owner_restaurant_id.present? && owner_restaurant_id == @restaurant.id
        return redirect_to(edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Owner restaurant cannot detach its own menu')
      end

      restaurant_menu = RestaurantMenu.find_by!(restaurant_id: @restaurant.id, menu_id: menu.id)
      authorize restaurant_menu, :detach?
      restaurant_menu.destroy!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'restaurant_content',
            partial: 'restaurants/sections/menus_2025',
            locals: { restaurant: @restaurant, filter: 'all' },
          )
        end
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'menus') }
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'Menu not attached'
    end
  end
end
