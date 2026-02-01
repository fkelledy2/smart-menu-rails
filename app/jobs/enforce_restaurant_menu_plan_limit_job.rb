class EnforceRestaurantMenuPlanLimitJob < ApplicationJob
  queue_as :default

  def perform(restaurant_id: nil, user_id: nil)
    if restaurant_id.present?
      restaurant = Restaurant.find_by(id: restaurant_id)
      enforce_for_restaurant(restaurant) if restaurant
      return
    end

    if user_id.present?
      user = User.find_by(id: user_id)
      return unless user

      user.restaurants.find_each do |restaurant|
        enforce_for_restaurant(restaurant)
      end
      return
    end

    Restaurant.find_each do |restaurant|
      enforce_for_restaurant(restaurant)
    end
  end

  private

  def enforce_for_restaurant(restaurant)
    user = restaurant.user
    plan = user&.plan
    return unless plan
    return if plan.menusperlocation == -1

    limit = plan.menusperlocation.to_i
    return if limit <= 0

    scoped = restaurant.restaurant_menus
      .where.not(status: RestaurantMenu.statuses[:archived])
      .joins(:menu)
      .where(menus: { archived: false })

    total_count = scoped.count
    return if total_count <= limit

    import_times = OcrMenuImport
      .where(restaurant_id: restaurant.id)
      .where.not(menu_id: nil)
      .group(:menu_id)
      .maximum(:created_at)

    ranked = scoped
      .includes(:menu)
      .order(Arel.sql('restaurant_menus.created_at DESC, restaurant_menus.id DESC'))
      .to_a
      .sort_by do |rm|
        menu = rm.menu
        menu_id = menu&.id
        imported_at = import_times[menu_id]
        fallback_at = menu&.created_at || rm.created_at
        [-(imported_at || fallback_at || Time.at(0)).to_i, -rm.id]
      end

    keep_ids = ranked.first(limit).map(&:id)

    ApplicationRecord.on_primary do
      RestaurantMenu
        .where(restaurant_id: restaurant.id)
        .where.not(status: RestaurantMenu.statuses[:archived])
        .where.not(id: keep_ids)
        .update_all(status: RestaurantMenu.statuses[:inactive], updated_at: Time.current)

      RestaurantMenu
        .where(restaurant_id: restaurant.id, id: keep_ids)
        .where.not(status: RestaurantMenu.statuses[:archived])
        .update_all(status: RestaurantMenu.statuses[:active], updated_at: Time.current)
    end
  end
end
