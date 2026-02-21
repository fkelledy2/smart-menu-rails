require 'application_system_test_case'

class WhiskeyAmbassadorSmokeTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @restaurant.update_columns(whiskey_ambassador_enabled: true, max_whiskey_flights: 5)

    @menu = menus(:one)
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant

    @section = @menu.menusections.first || Menusection.create!(
      menu: @menu, name: 'Whiskey', sequence: 1, status: :active
    )

    # Create whiskey items for the review queue and ambassador
    @whiskey = Menuitem.create!(
      name: 'Lagavulin 16yo', description: 'Islay single malt',
      menusection: @section, itemtype: :food, status: :active,
      price: 18.0, preptime: 0, calories: 0,
      sommelier_category: 'whiskey',
      sommelier_parsed_fields: {
        'distillery' => 'Lagavulin', 'whiskey_region' => 'islay',
        'whiskey_type' => 'single_malt', 'age_years' => 16,
        'staff_flavor_cluster' => 'heavily_peated',
      },
      sommelier_needs_review: true,
    )

    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  test 'beverage review queue shows whiskey tagging form' do
    visit beverage_review_queue_restaurant_path(@restaurant)
    assert_text 'Beverage Review Queue'
    assert_text 'Lagavulin 16yo'
    # Whiskey items should show the tagging form with region selector
    assert_selector 'select[name="whiskey_region"]'
    assert_selector 'select[name="whiskey_type"]'
    assert_selector 'input[name="distillery"]', visible: :all
  end

  test 'whiskey CSV import page loads' do
    visit new_whiskey_import_restaurant_path(@restaurant)
    assert_text 'Whiskey CSV Import'
    assert_text @restaurant.name
    assert_selector 'input[type="file"]'
  end

  test 'admin whiskey flights index loads' do
    visit admin_whiskey_flights_restaurant_path(@restaurant)
    assert_text 'Whiskey Flights'
    assert_text @restaurant.name
  end

  test 'admin create new flight page loads' do
    visit new_admin_whiskey_flight_restaurant_path(@restaurant)
    assert_text 'New Whiskey Flight'
    assert_selector 'input[name="whiskey_flight[title]"]'
  end
end
