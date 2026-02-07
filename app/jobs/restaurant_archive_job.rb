class RestaurantArchiveJob < ApplicationJob
  queue_as :default

  def perform(*args, **kwargs)
    rid = kwargs.key?(:restaurant_id) ? kwargs[:restaurant_id] : args[0]
    by_id = kwargs.key?(:archived_by_id) ? kwargs[:archived_by_id] : args[1]
    r = kwargs.key?(:reason) ? kwargs[:reason] : args[2]

    restaurant = Restaurant.find_by(id: rid)
    return unless restaurant

    RestaurantArchivalService.archive!(restaurant: restaurant, archived_by_id: by_id, reason: r)
  end
end
