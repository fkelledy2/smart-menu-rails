require 'securerandom'

class DemoMenuService
  def self.demo_restaurant_id
    Rails.env.development? ? 1 : 3
  end

  def self.demo_menu_id
    Rails.env.development? ? 1 : 3
  end

  def self.demo_smartmenu_for_host(host)
    ApplicationRecord.on_primary do
      demo_smartmenu
    end
  end

  def self.demo_smartmenu
    ApplicationRecord.on_primary do
      return nil unless Restaurant.exists?(demo_restaurant_id) && Menu.exists?(demo_menu_id)
      Smartmenu.where(restaurant_id: demo_restaurant_id, menu_id: demo_menu_id, tablesetting_id: nil).first ||
        Smartmenu.create!(
          restaurant_id: demo_restaurant_id,
          menu_id: demo_menu_id,
          tablesetting_id: nil,
          slug: SecureRandom.uuid,
        )
    end
  end

  def self.demo_menu
    ApplicationRecord.on_primary do
      Menu.find_by(id: demo_menu_id)
    end
  end

  def self.attach_demo_menu_to_restaurant!(restaurant)
    menu = demo_menu
    return false if menu.nil?

    ActiveRecord::Base.transaction do
      restaurant_menu = RestaurantMenu.find_or_initialize_by(restaurant: restaurant, menu: menu)
      if restaurant_menu.new_record?
        restaurant_menu.sequence ||= (restaurant.restaurant_menus.maximum(:sequence).to_i + 1)
        restaurant_menu.status ||= :inactive
        restaurant_menu.availability_override_enabled = false if restaurant_menu.availability_override_enabled.nil?
        restaurant_menu.availability_state ||= :available
        restaurant_menu.save!
      end

      ensure_smartmenus_for_restaurant_menu!(restaurant, menu)
    end

    true
  end

  def self.ensure_smartmenus_for_restaurant_menu!(restaurant, menu)
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
end
