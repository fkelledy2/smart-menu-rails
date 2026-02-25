# frozen_string_literal: true

require 'test_helper'

class SchemaOrgSerializerTest < ActiveSupport::TestCase
  # Lightweight structs to avoid AR validation/association issues in unit tests
  MockItem = Struct.new(:name, :description, :price, :calories, :is_active, :allergyns, keyword_init: true) do
    def active?
      is_active
    end
  end

  MockSection = Struct.new(:id, :name, :description, :menuitems, keyword_init: true)

  setup do
    @restaurant = Restaurant.new(
      id: 1,
      name: 'Da Mimmo',
      description: 'Authentic Italian cuisine in Dublin',
      address1: '148 North Strand Road',
      address2: 'Dublin 3',
      city: 'Dublin',
      state: 'Leinster',
      postcode: 'D03 Y1R5',
      country: 'Ireland',
      latitude: 53.3598,
      longitude: -6.2451,
      currency: 'EUR',
      establishment_types: %w[Italian Pizza],
    )

    @menu = Menu.new(id: 10, name: 'Lunch Menu')

    @smartmenu = Smartmenu.new(slug: 'da-mimmo-lunch')

    @item1 = MockItem.new(
      name: 'Bruschetta',
      description: 'Toasted bread with tomatoes and basil',
      price: 8.50,
      calories: 220,
      is_active: true,
      allergyns: [],
    )
    @item2 = MockItem.new(
      name: 'Soup of the Day',
      description: "Chef's daily soup",
      price: 6.00,
      calories: 0,
      is_active: true,
      allergyns: [],
    )
    @item_inactive = MockItem.new(
      name: 'Archived Item',
      description: 'Should not appear',
      price: 5.00,
      calories: 0,
      is_active: false,
      allergyns: [],
    )

    @section = MockSection.new(
      id: 100,
      name: 'Starters',
      description: 'Appetizers and small plates',
      menuitems: [@item1, @item2, @item_inactive],
    )
  end

  test 'to_json_ld returns valid JSON string' do
    json = build_serializer.to_json_ld
    assert_nothing_raised { JSON.parse(json) }
  end

  test 'includes Restaurant type and name' do
    data = parsed_json
    assert_equal 'https://schema.org', data['@context']
    assert_equal 'Restaurant', data['@type']
    assert_equal 'Da Mimmo', data['name']
    assert_equal 'Authentic Italian cuisine in Dublin', data['description']
  end

  test 'includes full address hash' do
    data = parsed_json
    address = data['address']
    assert_equal 'PostalAddress', address['@type']
    assert_equal '148 North Strand Road, Dublin 3', address['streetAddress']
    assert_equal 'Dublin', address['addressLocality']
    assert_equal 'Ireland', address['addressCountry']
    assert_equal 'D03 Y1R5', address['postalCode']
  end

  test 'includes geo coordinates' do
    data = parsed_json
    geo = data['geo']
    assert_equal 'GeoCoordinates', geo['@type']
    assert_in_delta 53.3598, geo['latitude'], 0.001
    assert_in_delta(-6.2451, geo['longitude'], 0.001)
  end

  test 'omits address when address1 is blank' do
    @restaurant.address1 = nil
    data = parsed_json
    assert_nil data['address']
  end

  test 'omits geo when latitude is blank' do
    @restaurant.latitude = nil
    data = parsed_json
    assert_nil data['geo']
  end

  test 'includes menu with sections and items' do
    data = parsed_json
    menu = data['menu']
    assert_equal 'Menu', menu['@type']
    assert_equal 'Lunch Menu', menu['name']

    sections = menu['hasMenuSection']
    assert_equal 1, sections.length

    section = sections.first
    assert_equal 'MenuSection', section['@type']
    assert_equal 'Starters', section['name']
    assert_equal 'Appetizers and small plates', section['description']
  end

  test 'only includes active menu items' do
    data = parsed_json
    items = data.dig('menu', 'hasMenuSection', 0, 'hasMenuItem')
    names = items.pluck('name')
    assert_includes names, 'Bruschetta'
    assert_includes names, 'Soup of the Day'
    assert_not_includes names, 'Archived Item'
  end

  test 'includes price as Offer with currency' do
    data = parsed_json
    items = data.dig('menu', 'hasMenuSection', 0, 'hasMenuItem')
    bruschetta = items.find { |i| i['name'] == 'Bruschetta' }
    offer = bruschetta['offers']
    assert_equal 'Offer', offer['@type']
    assert_equal 8.50, offer['price']
    assert_equal 'EUR', offer['priceCurrency']
  end

  test 'includes nutrition when calories > 0' do
    data = parsed_json
    items = data.dig('menu', 'hasMenuSection', 0, 'hasMenuItem')
    bruschetta = items.find { |i| i['name'] == 'Bruschetta' }
    assert_equal '220 cal', bruschetta.dig('nutrition', 'calories')
  end

  test 'omits nutrition when calories is 0' do
    data = parsed_json
    items = data.dig('menu', 'hasMenuSection', 0, 'hasMenuItem')
    soup = items.find { |i| i['name'] == 'Soup of the Day' }
    assert_nil soup['nutrition']
  end

  test 'includes servesCuisine from establishment_types' do
    data = parsed_json
    assert_equal %w[Italian Pizza], data['servesCuisine']
  end

  test 'omits servesCuisine when establishment_types is empty' do
    @restaurant.establishment_types = []
    data = parsed_json
    assert_nil data['servesCuisine']
  end

  test 'includes correct smartmenu URL' do
    data = parsed_json
    assert_equal 'https://www.mellow.menu/smartmenus/da-mimmo-lunch', data['url']
  end

  test 'falls back to EUR when restaurant currency is nil' do
    @restaurant.currency = nil
    data = parsed_json
    items = data.dig('menu', 'hasMenuSection', 0, 'hasMenuItem')
    bruschetta = items.find { |i| i['name'] == 'Bruschetta' }
    assert_equal 'EUR', bruschetta.dig('offers', 'priceCurrency')
  end

  test 'includes allergen data when present on items' do
    allergen = OpenStruct.new(name: 'Gluten')
    @item1 = MockItem.new(
      name: 'Bruschetta',
      description: 'Toasted bread with tomatoes and basil',
      price: 8.50,
      calories: 220,
      is_active: true,
      allergyns: [allergen],
    )
    @section = MockSection.new(
      id: 100, name: 'Starters', description: 'Appetizers and small plates',
      menuitems: [@item1, @item2, @item_inactive],
    )

    data = parsed_json
    items = data.dig('menu', 'hasMenuSection', 0, 'hasMenuItem')
    bruschetta = items.find { |i| i['name'] == 'Bruschetta' }
    assert_equal ['Gluten'], bruschetta['suitableForDiet']
  end

  private

  def build_serializer
    SchemaOrgSerializer.new(
      restaurant: @restaurant,
      menu: @menu,
      menusections: [@section],
      smartmenu: @smartmenu,
    )
  end

  def parsed_json
    JSON.parse(build_serializer.to_json_ld)
  end
end
