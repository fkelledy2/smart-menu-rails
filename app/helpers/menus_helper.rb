module MenusHelper
  def menu_form_with(menu, **options, &block)
    url = if menu.persisted?
            restaurant_menu_path(menu.restaurant, menu)
          else
            restaurant_menus_path(menu.restaurant)
          end
    
    defaults = {
      model: menu,
      url: url,
      method: menu.persisted? ? :patch : :post,
      local: true
    }
    
    form_with(**defaults.merge(options), &block)
  end
end
