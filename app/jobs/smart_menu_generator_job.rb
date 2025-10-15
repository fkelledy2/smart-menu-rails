require 'sidekiq'
require 'securerandom'

class SmartMenuGeneratorJob
  include Sidekiq::Job

  def perform(restaurantId)
    restaurant = Restaurant.find_by(id: restaurantId)
    return unless restaurant # Skip if restaurant doesn't exist
    #       Restaurant.all.each do |restaurant|
    Menu.where(restaurant_id: restaurant.id).find_each do |menu|
      if Smartmenu.where(restaurant_id: restaurant.id, menu_id: menu.id, tablesetting_id: nil).first.nil?
        @smartmenu = Smartmenu.new
        @smartmenu.restaurant = restaurant
        @smartmenu.tablesetting = nil
        @smartmenu.menu = menu
        @smartmenu.slug = uuid = SecureRandom.uuid
        @smartmenu.save
      end
      Tablesetting.where(restaurant_id: restaurant.id).order(:name).each do |tablesetting|
        next unless Smartmenu.where(restaurant_id: restaurant.id, menu_id: menu.id,
                                    tablesetting_id: tablesetting.id,).first.nil?

        @smartmenu = Smartmenu.new
        @smartmenu.restaurant = restaurant
        @smartmenu.menu = menu
        @smartmenu.tablesetting = tablesetting
        @smartmenu.slug = uuid = SecureRandom.uuid
        @smartmenu.save
      end
    end
    Tablesetting.where(restaurant_id: restaurant.id).order(:name).each do |tablesetting|
      next unless Smartmenu.where(tablesetting_id: tablesetting.id, restaurant_id: restaurant.id,
                                  menu_id: nil,).first.nil?

      @smartmenu = Smartmenu.new
      @smartmenu.restaurant = restaurant
      @smartmenu.menu = nil
      @smartmenu.tablesetting = tablesetting
      @smartmenu.slug = SecureRandom.uuid
      @smartmenu.save
    end
    #       end
  end
end
