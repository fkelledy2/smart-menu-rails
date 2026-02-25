# frozen_string_literal: true

# Generates Schema.org JSON-LD structured data for public smartmenu pages.
# Accepts restaurant + menu context and returns a JSON string suitable for
# embedding in a <script type="application/ld+json"> block.
#
# Usage:
#   SchemaOrgSerializer.new(
#     restaurant: @restaurant,
#     menu: @menu,
#     menusections: @menu.menusections,
#     smartmenu: @smartmenu,
#   ).to_json_ld
class SchemaOrgSerializer
  def initialize(restaurant:, menu:, menusections:, smartmenu:)
    @restaurant = restaurant
    @menu = menu
    @menusections = menusections
    @smartmenu = smartmenu
  end

  def to_json_ld
    JSON.generate(restaurant_with_menu)
  end

  private

  def restaurant_with_menu
    {
      '@context' => 'https://schema.org',
      '@type' => 'Restaurant',
      'name' => @restaurant.name,
      'description' => @restaurant.description,
      'url' => smartmenu_url,
      'address' => address_hash,
      'geo' => geo_hash,
      'menu' => menu_hash,
      'servesCuisine' => serves_cuisine,
    }.compact
  end

  def address_hash
    return nil if @restaurant.address1.blank?

    {
      '@type' => 'PostalAddress',
      'streetAddress' => [@restaurant.address1, @restaurant.address2].compact_blank.join(', '),
      'addressLocality' => @restaurant.city,
      'addressRegion' => @restaurant.state,
      'postalCode' => @restaurant.postcode,
      'addressCountry' => @restaurant.country,
    }.compact
  end

  def geo_hash
    return nil if @restaurant.latitude.blank? || @restaurant.longitude.blank?

    {
      '@type' => 'GeoCoordinates',
      'latitude' => @restaurant.latitude,
      'longitude' => @restaurant.longitude,
    }
  end

  def menu_hash
    {
      '@type' => 'Menu',
      'name' => @menu.name,
      'hasMenuSection' => @menusections.map { |s| menu_section_hash(s) },
    }
  end

  def menu_section_hash(section)
    items = section.menuitems.select(&:active?)
    {
      '@type' => 'MenuSection',
      'name' => section.name,
      'description' => section.description,
      'hasMenuItem' => items.map { |item| menu_item_hash(item) },
    }.compact
  end

  def menu_item_hash(item)
    hash = {
      '@type' => 'MenuItem',
      'name' => item.name,
      'description' => item.description,
    }

    if item.price.present? && item.price.positive?
      hash['offers'] = {
        '@type' => 'Offer',
        'price' => item.price.to_f,
        'priceCurrency' => @restaurant.currency || 'EUR',
      }
    end

    if item.calories.present? && item.calories.positive?
      hash['nutrition'] = {
        '@type' => 'NutritionInformation',
        'calories' => "#{item.calories} cal",
      }
    end

    if item.allergyns.any?
      hash['suitableForDiet'] = item.allergyns.map(&:name)
    end

    hash.compact
  end

  def serves_cuisine
    types = @restaurant.try(:establishment_types)
    return nil if types.blank?

    types
  end

  def smartmenu_url
    "https://www.mellow.menu/smartmenus/#{@smartmenu.slug}"
  end
end
