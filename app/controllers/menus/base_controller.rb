# frozen_string_literal: true

module Menus
  # Shared setup and helpers for all Menus::* sub-controllers and MenusController.
  # Sub-controllers declare their own before_action callbacks rather than inheriting
  # a one-size-fits-all filter chain, because set_menu/authenticate_user! have
  # different exclusions per controller.
  class BaseController < ApplicationController
    before_action :set_restaurant

    after_action :verify_authorized

    private

    def ensure_owner_restaurant_context!
      return unless @restaurant && @menu

      owner_restaurant_id = @menu.owner_restaurant_id.presence || @menu.restaurant_id
      return if owner_restaurant_id.blank?
      return if @restaurant.id == owner_restaurant_id

      redirect_to edit_restaurant_path(@restaurant, section: 'menus'), alert: 'This menu is read-only for this restaurant'
    end

    def ensure_smartmenus_for_restaurant_menu!(restaurant, menu)
      Smartmenu.on_primary do
        if Smartmenu.where(restaurant_id: restaurant.id, menu_id: menu.id, tablesetting_id: nil).first.nil?
          Smartmenu.create!(restaurant: restaurant, menu: menu, tablesetting: nil, slug: SecureRandom.uuid)
        end

        restaurant.tablesettings.order(:id).each do |tablesetting|
          next unless Smartmenu.where(restaurant_id: restaurant.id, menu_id: menu.id, tablesetting_id: tablesetting.id).first.nil?

          Smartmenu.create!(restaurant: restaurant, menu: menu, tablesetting: tablesetting, slug: SecureRandom.uuid)
        end
      end
    end

    def set_restaurant
      return if params[:restaurant_id].blank?

      if current_user
        restaurant_id = params[:restaurant_id].to_i
        is_owner = current_user.restaurants.exists?(id: restaurant_id)
        is_active_employee = Employee.exists?(user_id: current_user.id, restaurant_id: restaurant_id, status: :active)

        unless is_owner || is_active_employee
          Rails.logger.warn "[#{self.class.name}] Access denied: User #{current_user.id} cannot access restaurant #{restaurant_id}"
          respond_to do |format|
            format.html { redirect_to restaurants_path, alert: 'Restaurant not found or access denied' }
            format.json { head :forbidden }
          end
          return
        end

        @restaurant = is_owner ? current_user.restaurants.find(restaurant_id) : Restaurant.find(restaurant_id)
      else
        @restaurant = Restaurant.find(params[:restaurant_id])
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn "[#{self.class.name}] Restaurant not found for id=#{params[:restaurant_id]}: #{e.message}"
      respond_to do |format|
        format.html { redirect_to restaurants_path, alert: 'Restaurant not found' }
        format.json { head :not_found }
      end
    rescue StandardError => e
      Rails.logger.error "[#{self.class.name}] Error in set_restaurant: #{e.message}"
      respond_to do |format|
        format.html { redirect_to restaurants_path, alert: 'An error occurred while loading the restaurant' }
        format.json { head :internal_server_error }
      end
    end

    def set_menu
      menu_id = params[:menu_id] || params[:id]

      if menu_id.blank?
        redirect_to(@restaurant ? restaurant_menus_path(@restaurant) : restaurants_path, alert: 'Menu not specified')
        return
      end

      @menu = if @restaurant
                Menu.joins(:restaurant_menus)
                  .where(restaurant_menus: { restaurant_id: @restaurant.id })
                  .find(menu_id)
              else
                Menu.find(menu_id)
              end

      if @restaurant && @menu
        @restaurant_menu = RestaurantMenu.find_by(restaurant_id: @restaurant.id, menu_id: @menu.id)
        owner_restaurant_id = @menu.owner_restaurant_id.presence || @menu.restaurant_id
        @read_only_menu_context = owner_restaurant_id.present? && @restaurant.id != owner_restaurant_id

        ensure_smartmenus_for_restaurant_menu!(@restaurant, @menu)
      end

      if @menu && current_user
        restaurant_currency_code = @restaurant&.currency || @menu.restaurant.currency || 'USD'
        @restaurantCurrency = ISO4217::Currency.from_code(restaurant_currency_code)
        @menuItemCount ||= @menu.menuitems.count
        plan = current_user.plan
        @canAddMenuItem = plan.nil? || plan.itemspermenu == -1 || @menuItemCount < plan.itemspermenu
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn "[#{self.class.name}] Menu not found for id=#{menu_id}: #{e.message}"
      redirect_to(@restaurant ? restaurant_menus_path(@restaurant) : restaurants_path, alert: 'Menu not found')
    rescue StandardError => e
      Rails.logger.error "[#{self.class.name}] Error in set_menu: #{e.message}"
      redirect_to(@restaurant ? restaurant_menus_path(@restaurant) : restaurants_path,
                  alert: 'An error occurred while loading the menu',)
    end
  end
end
