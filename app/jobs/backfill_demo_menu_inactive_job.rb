class BackfillDemoMenuInactiveJob < ApplicationJob
  queue_as :default

  def perform
    demo_menu_id = DemoMenuService.demo_menu_id
    demo_restaurant_id = DemoMenuService.demo_restaurant_id

    RestaurantMenu.on_primary do
      RestaurantMenu
        .where(menu_id: demo_menu_id)
        .where.not(restaurant_id: demo_restaurant_id)
        .where.not(status: RestaurantMenu.statuses[:inactive])
        .update_all(status: RestaurantMenu.statuses[:inactive])
    end
  end
end
