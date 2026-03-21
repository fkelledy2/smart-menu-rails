# frozen_string_literal: true

module Restaurants
  class BaseController < ApplicationController
    include CachePerformanceMonitoring

    before_action :authenticate_user!
    after_action :verify_authorized

    private

    def set_restaurant
      id_param = params[:restaurant_id] || params[:id]

      Rails.logger.debug do
        "[Restaurants::BaseController] set_restaurant called with id_param=#{id_param}, action=#{action_name}"
      end

      if id_param.blank?
        Rails.logger.error "[Restaurants::BaseController] No restaurant ID provided in params: #{params.inspect}"
        redirect_to restaurants_path, alert: 'Restaurant not specified'
        return
      end

      @restaurant = if current_user
                      current_user.restaurants.find(id_param)
                    else
                      Restaurant.find(id_param)
                    end

      Rails.logger.debug { "[Restaurants::BaseController] Found restaurant: #{@restaurant&.id} - #{@restaurant&.name}" }

      @canAddMenu = false
      if @restaurant && current_user
        @menuCount = if @restaurant.respond_to?(:fetch_menus)
                       @restaurant.fetch_menus.count { |m| m.status == 'active' && !m.archived? }
                     else
                       Menu.where(restaurant: @restaurant, status: 'active', archived: false).count
                     end

        @canAddMenu = current_user.super_admin? || @menuCount < current_user.plan.menusperlocation || current_user.plan.menusperlocation == -1
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn "[Restaurants::BaseController] Restaurant not found for id=#{id_param}: #{e.message}"
      redirect_to restaurants_path, alert: 'Restaurant not found or access denied'
    rescue StandardError => e
      Rails.logger.error "[Restaurants::BaseController] Error in set_restaurant: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to restaurants_path, alert: 'An error occurred while loading the restaurant'
    end

    def set_currency
      if params[:id]
        @restaurant = Restaurant.fetch(params[:id])
        @restaurantCurrency = if @restaurant&.currency.present?
                                ISO4217::Currency.from_code(@restaurant.currency)
                              else
                                ISO4217::Currency.from_code('USD')
                              end
      else
        @restaurantCurrency = ISO4217::Currency.from_code('USD')
      end
    end

    def section_partial_name(section)
      case section
      when 'details', 'address' then 'details_2025'
      when 'hours' then 'hours_2025'
      when 'localization' then 'localization_2025'
      when 'menus', 'menus_active', 'menus_inactive' then 'menus_2025'
      when 'allergens' then 'allergens_2025'
      when 'sizes' then 'sizes_2025'
      when 'import' then 'import_2025'
      when 'staff', 'roles' then 'staff_2025'
      when 'settings' then 'settings_2025'
      when 'taxes_and_tips', 'financials', 'catalog' then 'catalog_2025'
      when 'jukebox' then 'jukebox_2025'
      when 'tables' then 'tables_2025'
      when 'ordering' then 'ordering_2025'
      when 'insights' then 'insights_2025'
      when 'wifi' then 'wifi_2025'
      when 'advanced' then 'advanced_2025'
      when 'profitability' then 'profitability_2025'
      when 'profitability_margins' then 'profitability_margins_2025'
      when 'profitability_ingredients' then 'profitability_ingredients_2025'
      when 'profitability_optimization' then 'profitability_optimization_2025'
      when 'profitability_targets' then 'profitability_targets_2025'
      when 'profitability_analytics' then 'profitability_analytics_2025'
      else 'details_2025'
      end
    end

    def onboarding_required_text_for(onboarding_next)
      case onboarding_next
      when 'details'
        missing = @restaurant.onboarding_missing_details_fields
        labels = {
          description: 'a description',
          currency: 'a currency',
          address: 'your address/location',
          country: 'your country',
        }
        items = missing.filter_map { |k| labels[k] }
        "To continue setup, please add #{items.to_sentence}."
      when 'localization'
        'Add at least one language and set a default language to continue setup.'
      when 'tables'
        'Add at least one table (capacity 4 is fine) to continue setup.'
      when 'staff'
        'Add at least one staff member to continue setup.'
      when 'menus'
        'Create or import a menu to continue setup.'
      else
        'Continue the required setup to proceed.'
      end
    rescue StandardError => e
      Rails.logger.warn("[Restaurants::BaseController] Failed to build onboarding message: #{e.message}")
      'Continue the required setup to proceed.'
    end

    def disable_turbo
      @disable_turbo = true
    end

    def skip_policy_scope_for_json?
      request.format.json? && current_user.present?
    end
  end
end
