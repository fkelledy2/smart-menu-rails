module ApplicationHelper
  # Enhanced restaurant context helper for JavaScript
  def restaurant_context_data(restaurant = nil)
    # Try to determine restaurant from various sources
    restaurant ||= @restaurant || 
                   @menu&.restaurant || 
                   @menuitem&.menusection&.menu&.restaurant ||
                   @menusection&.menu&.restaurant ||
                   current_user&.restaurants&.first

    return {} unless restaurant

    {
      'data-restaurant-id' => restaurant.id,
      'data-restaurant-name' => restaurant.name,
      'data-restaurant-slug' => restaurant.slug
    }
  end

  # Add restaurant context meta tags
  def restaurant_context_meta_tags(restaurant = nil)
    restaurant ||= @restaurant || 
                   @menu&.restaurant || 
                   @menuitem&.menusection&.menu&.restaurant ||
                   @menusection&.menu&.restaurant

    return '' unless restaurant

    content_for :head do
      tag.meta(name: 'restaurant-id', content: restaurant.id) +
      tag.meta(name: 'current-restaurant', content: restaurant.id) +
      tag.meta(property: 'restaurant:id', content: restaurant.id)
    end
  end

  # JavaScript context initialization
  def restaurant_context_script(restaurant = nil)
    restaurant ||= @restaurant || 
                   @menu&.restaurant || 
                   @menuitem&.menusection&.menu&.restaurant ||
                   @menusection&.menu&.restaurant

    return '' unless restaurant

    javascript_tag do
      raw <<~JS
        // Set global restaurant context for JavaScript
        window.currentRestaurant = {
          id: #{restaurant.id.to_json},
          name: #{restaurant.name.to_json},
          slug: #{restaurant.slug.to_json}
        };
        
        // Store in session storage for persistence
        try {
          sessionStorage.setItem('currentRestaurantId', #{restaurant.id.to_json});
        } catch(e) {
          console.warn('Unable to store restaurant context:', e);
        }
      JS
    end
  end

  # Enhanced body tag with restaurant context
  def body_with_restaurant_context(options = {}, restaurant = nil)
    restaurant ||= @restaurant || 
                   @menu&.restaurant || 
                   @menuitem&.menusection&.menu&.restaurant ||
                   @menusection&.menu&.restaurant

    if restaurant
      options.merge!(restaurant_context_data(restaurant))
    end

    tag.body(options) do
      yield if block_given?
    end
  end
end
