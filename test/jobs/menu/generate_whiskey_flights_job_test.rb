# frozen_string_literal: true

require 'test_helper'

class Menu::GenerateWhiskeyFlightsJobTest < ActiveSupport::TestCase
  setup do
    @menu = menus(:one)
    @restaurant = @menu.restaurant
    @restaurant.update_columns(whiskey_ambassador_enabled: true, max_whiskey_flights: 5)

    @section = @menu.menusections.first || Menusection.create!(
      menu: @menu, name: 'Whiskey', sequence: 1, status: :active,
    )

    # Create enough whiskey items for flights (need ≥6)
    create_whiskey('Lagavulin 16yo', 18.0, {
      'whiskey_region' => 'islay', 'whiskey_type' => 'single_malt',
      'cask_type' => 'sherry_cask', 'age_years' => 16,
      'bottling_strength_abv' => 43.0, 'staff_flavor_cluster' => 'heavily_peated',
      'staff_pick' => true,
    })
    create_whiskey('Ardbeg 10', 14.0, {
      'whiskey_region' => 'islay', 'whiskey_type' => 'single_malt',
      'age_years' => 10, 'bottling_strength_abv' => 46.0,
      'staff_flavor_cluster' => 'heavily_peated',
    })
    create_whiskey('Bowmore 12', 12.0, {
      'whiskey_region' => 'islay', 'whiskey_type' => 'single_malt',
      'cask_type' => 'sherry_cask', 'age_years' => 12,
      'bottling_strength_abv' => 40.0, 'staff_flavor_cluster' => 'smoky_coastal',
      'staff_pick' => true,
    })
    create_whiskey('Macallan 12', 14.0, {
      'whiskey_region' => 'speyside', 'whiskey_type' => 'single_malt',
      'cask_type' => 'sherry_cask', 'age_years' => 12,
      'bottling_strength_abv' => 40.0, 'staff_flavor_cluster' => 'rich_sherried',
      'staff_pick' => true,
    })
    create_whiskey('Buffalo Trace', 10.0, {
      'whiskey_region' => 'kentucky', 'whiskey_type' => 'bourbon',
      'cask_type' => 'bourbon_cask', 'bottling_strength_abv' => 45.0,
      'staff_flavor_cluster' => 'fruity_sweet',
    })
    create_whiskey('Redbreast 12', 12.0, {
      'whiskey_region' => 'ireland', 'whiskey_type' => 'irish_single_pot',
      'age_years' => 12, 'bottling_strength_abv' => 40.0,
      'staff_flavor_cluster' => 'fruity_sweet',
    })
    create_whiskey('Talisker 10', 15.0, {
      'whiskey_region' => 'islands', 'whiskey_type' => 'single_malt',
      'age_years' => 10, 'bottling_strength_abv' => 45.8,
      'staff_flavor_cluster' => 'smoky_coastal',
    })
    create_whiskey('Glenmorangie 10', 11.0, {
      'whiskey_region' => 'highland', 'whiskey_type' => 'single_malt',
      'age_years' => 10, 'bottling_strength_abv' => 40.0,
      'staff_flavor_cluster' => 'light_delicate',
    })
  end

  test 'generates flights for menu with enough items' do
    WhiskeyFlight.count
    Menu::GenerateWhiskeyFlightsJob.perform_now(@menu.id)

    flights = WhiskeyFlight.where(menu: @menu)
    assert flights.any?, 'Should have generated at least one flight'
    assert flights.count <= 5, 'Should respect max_whiskey_flights'

    flights.each do |flight|
      assert flight.title.present?, "Flight #{flight.theme_key} should have a title"
      assert flight.narrative.present?, "Flight #{flight.theme_key} should have a narrative"
      assert flight.items.is_a?(Array), "Flight #{flight.theme_key} should have items array"
      assert flight.items.size >= 3, "Flight #{flight.theme_key} should have at least 3 items"
      assert flight.total_price.to_f.positive?, "Flight #{flight.theme_key} should have a total price"
      assert_equal 'ai', flight.source
      assert_equal 'draft', flight.status
      assert flight.generated_at.present?
    end
  end

  test 'respects max_whiskey_flights setting' do
    @restaurant.update_columns(max_whiskey_flights: 2)

    Menu::GenerateWhiskeyFlightsJob.perform_now(@menu.id)

    assert WhiskeyFlight.where(menu: @menu).count <= 2
  end

  test 'does not overwrite manual flights' do
    WhiskeyFlight.create!(
      menu: @menu, theme_key: 'regional_journey', title: 'My Custom Flight',
      items: [{ 'menuitem_id' => 1, 'position' => 1 }],
      source: :manual, status: :published,
    )

    Menu::GenerateWhiskeyFlightsJob.perform_now(@menu.id)

    manual = WhiskeyFlight.find_by(menu: @menu, theme_key: 'regional_journey')
    assert_equal 'My Custom Flight', manual.title, 'Manual flight should not be overwritten'
    assert manual.manual?, 'Source should still be manual'
  end

  test 'does not generate flights with fewer than 6 items' do
    sparse_menu = Menu.create!(name: 'Sparse', description: '', status: 1, sequence: 99, restaurant: @restaurant)
    sparse_section = Menusection.create!(menu: sparse_menu, name: 'Whiskey', sequence: 1, status: :active)
    3.times do |i|
      Menuitem.create!(
        name: "Sparse Whiskey #{i}", description: '', menusection: sparse_section,
        itemtype: :whiskey, status: :active, price: 10.0, preptime: 0, calories: 0,
        sommelier_parsed_fields: { 'whiskey_region' => 'islay' },
      )
    end

    count = Menu::GenerateWhiskeyFlightsJob.perform_now(sparse_menu.id)
    assert_nil count, 'Should return nil with too few items'
    assert_equal 0, WhiskeyFlight.where(menu: sparse_menu).count
  end

  test 'flight items reference valid menuitem_ids' do
    Menu::GenerateWhiskeyFlightsJob.perform_now(@menu.id)

    valid_ids = @menu.menuitems.pluck(:id).to_set
    WhiskeyFlight.where(menu: @menu).find_each do |flight|
      flight.items.each do |item|
        assert valid_ids.include?(item['menuitem_id']),
               "Flight #{flight.theme_key} references invalid menuitem_id #{item['menuitem_id']}"
      end
    end
  end

  test 'regeneration updates existing AI flights' do
    Menu::GenerateWhiskeyFlightsJob.perform_now(@menu.id)
    first_count = WhiskeyFlight.where(menu: @menu).count

    Menu::GenerateWhiskeyFlightsJob.perform_now(@menu.id)
    second_count = WhiskeyFlight.where(menu: @menu).count

    assert_equal first_count, second_count, 'Regeneration should update, not duplicate'
  end

  private

  def create_whiskey(name, price, parsed_fields)
    Menuitem.create!(
      name: name, description: '', menusection: @section,
      itemtype: :whiskey, status: :active, price: price,
      preptime: 0, calories: 0,
      sommelier_parsed_fields: parsed_fields,
    )
  end
end
