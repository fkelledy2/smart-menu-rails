require 'sidekiq'
require 'securerandom'

class SmartMenuSyncJob
  include Sidekiq::Job

  def perform(*args)
      Smartmenu.destroy_all
      Restaurant.all.each do |restaurant|
          Menu.where(restaurant_id: restaurant.id).each do |menu|
              @smartmenu = Smartmenu.new
              @smartmenu.restaurant = restaurant
              @smartmenu.menu = menu
              @smartmenu.slug = uuid = SecureRandom.uuid
              @smartmenu.save
              Tablesetting.where(restaurant_id: restaurant.id).order('name ASC').each do |tablesetting|
                @smartmenu = Smartmenu.new
                @smartmenu.restaurant = restaurant
                @smartmenu.menu = menu
                @smartmenu.tablesetting = tablesetting
                @smartmenu.slug = uuid = SecureRandom.uuid
                @smartmenu.save
              end
          end
          Tablesetting.where(restaurant_id: restaurant.id).order('name ASC').each do |tablesetting|
            @smartmenu = Smartmenu.new
            @smartmenu.restaurant = restaurant
            @smartmenu.tablesetting = tablesetting
            @smartmenu.slug = uuid = SecureRandom.uuid
            @smartmenu.save
          end
      end
  end
end
