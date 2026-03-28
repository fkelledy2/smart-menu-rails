require 'application_system_test_case'

# Tests the client-side menu item search/filter on the smartmenu show page.
#
# Root cause that was fixed:
#   1. menu_search_controller.js only queried .menu-item-card-mobile — staff-view
#      items (.menu-item-card) were never found.
#   2. For logged-in users the application.js bundle was served; menu-search was
#      not registered in that bundle's Stimulus application, so typing produced
#      no response at all.
class SmartmenuSearchFilterTest < ApplicationSystemTestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:ordering_menu)
    @smartmenu = smartmenus(:one)

    @spring_rolls    = menuitems(:spring_rolls)    # name: "Spring Rolls"
    @caesar_salad    = menuitems(:caesar_salad)    # name: "Caesar Salad"
    @burger          = menuitems(:burger)          # name: "Classic Burger"
    @pasta           = menuitems(:pasta)           # name: "Spaghetti Carbonara"

    # Visit as unauthenticated customer so smartmenu_customer.js is served.
    logout if respond_to?(:logout)
  end

  # ------------------------------------------------------------------
  # Customer view (.menu-item-card-mobile)
  # ------------------------------------------------------------------

  test 'customer view: search input is present and visible' do
    visit table_link_path(@smartmenu.public_token)
    assert_selector '[data-testid="menu-search-input"]', visible: true, wait: 10
  end

  test 'customer view: all items visible before searching' do
    visit table_link_path(@smartmenu.public_token)
    assert_selector '[data-testid="menu-search-input"]', wait: 10

    assert_selector "[data-testid='menu-item-#{@spring_rolls.id}']",  visible: true
    assert_selector "[data-testid='menu-item-#{@caesar_salad.id}']",  visible: true
    assert_selector "[data-testid='menu-item-#{@burger.id}']",        visible: true
    assert_selector "[data-testid='menu-item-#{@pasta.id}']",         visible: true
  end

  test 'customer view: typing a query hides non-matching items' do
    visit table_link_path(@smartmenu.public_token)
    input = find('[data-testid="menu-search-input"]', wait: 10)
    input.fill_in with: 'burger'

    assert_selector    "[data-testid='menu-item-#{@burger.id}']",       visible: true,  wait: 2
    assert_no_selector "[data-testid='menu-item-#{@spring_rolls.id}']", visible: true
    assert_no_selector "[data-testid='menu-item-#{@caesar_salad.id}']", visible: true
    assert_no_selector "[data-testid='menu-item-#{@pasta.id}']",        visible: true
  end

  test 'customer view: search matches on description' do
    visit table_link_path(@smartmenu.public_token)
    input = find('[data-testid="menu-search-input"]', wait: 10)
    # @pasta description contains "bacon"
    input.fill_in with: 'bacon'

    assert_selector    "[data-testid='menu-item-#{@pasta.id}']",        visible: true,  wait: 2
    assert_no_selector "[data-testid='menu-item-#{@burger.id}']",       visible: true
  end

  test 'customer view: search is case-insensitive' do
    visit table_link_path(@smartmenu.public_token)
    input = find('[data-testid="menu-search-input"]', wait: 10)
    input.fill_in with: 'SPRING'

    assert_selector    "[data-testid='menu-item-#{@spring_rolls.id}']", visible: true, wait: 2
    assert_no_selector "[data-testid='menu-item-#{@burger.id}']",       visible: true
  end

  test 'customer view: clearing search restores all items' do
    visit table_link_path(@smartmenu.public_token)
    input = find('[data-testid="menu-search-input"]', wait: 10)
    input.fill_in with: 'burger'
    assert_no_selector "[data-testid='menu-item-#{@spring_rolls.id}']", visible: true, wait: 2

    input.fill_in with: ''
    assert_selector "[data-testid='menu-item-#{@spring_rolls.id}']", visible: true, wait: 2
    assert_selector "[data-testid='menu-item-#{@caesar_salad.id}']", visible: true
    assert_selector "[data-testid='menu-item-#{@burger.id}']",       visible: true
    assert_selector "[data-testid='menu-item-#{@pasta.id}']",        visible: true
  end

  test 'customer view: no-results message shown when nothing matches' do
    visit table_link_path(@smartmenu.public_token)
    input = find('[data-testid="menu-search-input"]', wait: 10)
    input.fill_in with: 'xyzzy_no_match'

    assert_selector '[data-testid="menu-search-no-results"]', visible: true, wait: 2
  end

  test 'customer view: no-results message hidden when items match' do
    visit table_link_path(@smartmenu.public_token)
    input = find('[data-testid="menu-search-input"]', wait: 10)
    input.fill_in with: 'burger'

    assert_no_selector '[data-testid="menu-search-no-results"]', visible: true, wait: 2
  end
end
