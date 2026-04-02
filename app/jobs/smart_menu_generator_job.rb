require 'sidekiq'
require 'securerandom'

class SmartMenuGeneratorJob
  include Sidekiq::Job

  def perform(restaurantId)
    restaurant = Restaurant.find_by(id: restaurantId)
    return unless restaurant # Skip if restaurant doesn't exist

    # Pre-load tablesettings once rather than re-querying inside the menus loop
    # (previously fired one SELECT per menu + one final SELECT — N+1 on tablesettings).
    tablesettings = Tablesetting.where(restaurant_id: restaurant.id).order(:name).to_a

    #       Restaurant.all.each do |restaurant|
    Menu.where(restaurant_id: restaurant.id).find_each do |menu|
      begin
        Smartmenu.create!(
          restaurant: restaurant,
          menu: menu,
          tablesetting: nil,
          slug: SecureRandom.uuid,
        )
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      tablesettings.each do |tablesetting|
        Smartmenu.create!(
          restaurant: restaurant,
          menu: menu,
          tablesetting: tablesetting,
          slug: SecureRandom.uuid,
        )
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end

    tablesettings.each do |tablesetting|
      Smartmenu.create!(
        restaurant: restaurant,
        menu: nil,
        tablesetting: tablesetting,
        slug: SecureRandom.uuid,
      )
    rescue ActiveRecord::RecordNotUnique
      nil
    end
    #       end
  end
end
