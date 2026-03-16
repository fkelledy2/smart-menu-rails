module RestaurantsHelper
  def restaurant_form_with(restaurant, **options, &)
    url = restaurant.persisted? ? restaurant_path(restaurant) : restaurants_path

    defaults = {
      model: restaurant,
      url: url,
      method: restaurant.persisted? ? :patch : :post,
      local: true,
    }

    form_with(**defaults.merge(options), &)
  end
end
