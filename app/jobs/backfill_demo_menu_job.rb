class BackfillDemoMenuJob < ApplicationJob
  queue_as :default

  def perform
    demo_menu = DemoMenuService.demo_menu
    return if demo_menu.nil?

    demo_menu_id = DemoMenuService.demo_menu_id
    demo_restaurant_id = DemoMenuService.demo_restaurant_id
    old_demo_menu_ids = Rails.env.development? ? [3] : []

    Restaurant.on_primary do
      Restaurant.find_each do |restaurant|
        next if restaurant.id == demo_restaurant_id

        old_demo_menu_ids.each do |old_menu_id|
          next if old_menu_id == demo_menu_id

          RestaurantMenu.where(restaurant_id: restaurant.id, menu_id: old_menu_id).destroy_all
        end

        next if RestaurantMenu.exists?(restaurant_id: restaurant.id, menu_id: demo_menu_id)

        DemoMenuService.attach_demo_menu_to_restaurant!(restaurant)
      end
    end
  end
end
