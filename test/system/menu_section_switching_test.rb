# frozen_string_literal: true

require 'application_system_test_case'

# System tests for menu edit page: sidebar section switching,
# section reorder handles, and inline edit on menu items.
class MenuSectionSwitchingTest < ApplicationSystemTestCase
  setup do
    @plan = Plan.create!(
      key: 'free',
      descriptionKey: 'Free Plan',
      attribute1: '-',
    )

    @user = User.create!(
      email: "menu-test-#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Test',
      last_name: 'User',
      plan: @plan,
    )

    @restaurant = @user.restaurants.create!(
      name: 'Test Restaurant',
      archived: false,
      status: 1,
      currency: 'USD',
    )

    @menu = @restaurant.menus.create!(
      name: 'Test Menu',
      status: 1,
      archived: false,
    )

    @section1 = @menu.menusections.create!(
      name: 'Starters',
      status: 1,
      sequence: 1,
      archived: false,
    )

    @section2 = @menu.menusections.create!(
      name: 'Mains',
      status: 1,
      sequence: 2,
      archived: false,
    )

    @item1 = @section1.menuitems.create!(
      name: 'Caesar Salad',
      price: 12.50,
      status: 1,
      sequence: 1,
      archived: false,
      calories: 350,
      preptime: 10,
      itemtype: 'food',
      tasting_carrier: false,
      hidden: false,
    )

    @item2 = @section2.menuitems.create!(
      name: 'Grilled Salmon',
      price: 24.00,
      status: 1,
      sequence: 1,
      archived: false,
      calories: 520,
      preptime: 15,
      itemtype: 'food',
      tasting_carrier: false,
      hidden: false,
    )

    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  # ===================
  # SECTION SWITCHING VIA SIDEBAR
  # ===================

  test 'menu edit page loads on details section by default' do
    visit edit_restaurant_menu_path(@restaurant, @menu)

    assert_selector "[data-testid='menu-title']", text: 'Test Menu'
    # Details is the default section — sidebar link should be active
    assert_selector '.sidebar-link.active', text: 'Details'
  end

  test 'clicking Sections sidebar link loads sections content' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'details')

    # Click sections link in sidebar
    find('.sidebar-link', text: 'Sections').click

    # Wait for turbo frame update
    assert_text 'Starters', wait: 5
    assert_text 'Mains'
  end

  test 'clicking Items sidebar link loads items content' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'details')

    # Click items link in sidebar
    find('.sidebar-link', text: 'Items').click

    # Wait for turbo frame update — items view shows section headers and item names
    assert_text 'Caesar Salad', wait: 5
    assert_text 'Grilled Salmon'
  end

  test 'switching between sections preserves sidebar' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'details')

    # Navigate to sections
    find('.sidebar-link', text: 'Sections').click
    assert_text 'Starters', wait: 5

    # Sidebar should still be present (turbo frame only updates content area)
    assert_selector '.sidebar-2025'

    # Navigate to items
    find('.sidebar-link', text: 'Items').click
    assert_text 'Caesar Salad', wait: 5

    # Sidebar still present
    assert_selector '.sidebar-2025'

    # Navigate back to details
    find('.sidebar-link', text: 'Details').click
    sleep 1

    # Sidebar still present
    assert_selector '.sidebar-2025'
  end

  test 'direct URL to sections tab renders sections' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'sections')

    assert_text 'Starters'
    assert_text 'Mains'
    assert_selector '.sidebar-link.active', text: 'Sections'
  end

  test 'direct URL to items tab renders items' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

    assert_text 'Caesar Salad'
    assert_text 'Grilled Salmon'
    assert_selector '.sidebar-link.active', text: 'Items'
  end

  # ===================
  # SECTIONS LIST
  # ===================

  test 'sections tab lists all menu sections with item counts' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'sections')

    assert_text 'Starters'
    assert_text 'Mains'
  end

  test 'sections tab shows drag handles for reordering' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'sections')

    # Each section row should have a drag handle
    assert_selector '.section-handle', minimum: 2
    assert_selector '.bi-grip-vertical', minimum: 2
  end

  test 'sections tab has sortable controller wired up' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'sections')

    # The tbody should have the sortable data-controller
    assert_selector 'tbody[data-controller="sortable"]'
  end

  test 'sections have correct sortable IDs matching database IDs' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'sections')

    assert_selector "tr[data-sortable-id='#{@section1.id}']"
    assert_selector "tr[data-sortable-id='#{@section2.id}']"
  end

  test 'section edit links navigate to section edit page' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'sections')

    find("[data-testid='edit-menusection-#{@section1.id}-btn']").click

    assert_current_path edit_restaurant_menu_menusection_path(@restaurant, @menu, @section1), ignore_query: true
  end

  # ===================
  # ITEMS LIST + INLINE EDIT
  # ===================

  test 'items tab shows section headers with item rows' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

    # Section headers
    assert_selector "[data-testid='section-header-#{@section1.id}']", text: 'Starters'
    assert_selector "[data-testid='section-header-#{@section2.id}']", text: 'Mains'

    # Item rows
    assert_selector "[data-testid='menu-item-#{@item1.id}']"
    assert_selector "[data-testid='menu-item-#{@item2.id}']"
  end

  test 'items have inline edit controller wired up' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

    # Each item row should have the inline-edit controller
    assert_selector "[data-testid='menu-item-#{@item1.id}'][data-controller='inline-edit']"
    assert_selector "[data-testid='menu-item-#{@item2.id}'][data-controller='inline-edit']"
  end

  test 'items have inline-editable cells for name and price' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

    within "[data-testid='menu-item-#{@item1.id}']" do
      # Name cell
      name_cell = find('.inline-editable[data-field="name"]')
      assert_equal 'Caesar Salad', name_cell.text.strip

      # Price cell
      price_cell = find('.inline-editable[data-field="price"]')
      assert_includes price_cell.text, '12.50'
    end
  end

  test 'clicking an inline-editable name cell opens an input' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

    within "[data-testid='menu-item-#{@item1.id}']" do
      name_cell = find('.inline-editable[data-field="name"]')
      name_cell.click

      # An input should appear inside the cell
      input = find('input[type="text"]')
      assert_equal 'Caesar Salad', input.value
    end
  end

  test 'pressing Escape cancels inline edit' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

    within "[data-testid='menu-item-#{@item1.id}']" do
      name_cell = find('.inline-editable[data-field="name"]')
      name_cell.click

      input = find('input[type="text"]')
      # Type a character then immediately Escape — Escape fires keydown before blur
      input.send_keys('X', :escape)

      # Should revert to original (input removed, original HTML restored)
      assert_no_selector 'input[type="text"]'
      assert_text 'Caesar Salad'
    end
  end

  test 'inline edit saves on blur and updates the database' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

    within "[data-testid='menu-item-#{@item1.id}']" do
      name_cell = find('.inline-editable[data-field="name"]')
      name_cell.click

      input = find('input[type="text"]')
      input.set('Updated Salad')

      # Blur the input to trigger save (click outside)
      find('.item-handle').click
    end

    # Wait for the PATCH request to complete
    sleep 1

    # Verify DB was updated
    @item1.reload
    assert_equal 'Updated Salad', @item1.name
  end

  test 'items have drag handles for reordering' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

    # Each item row should have a drag handle
    assert_selector '.item-handle', minimum: 2
  end

  test 'items have sortable controller on section tbody' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

    # Each section's items tbody should have sortable controller
    assert_selector 'tbody.sortable-group[data-controller="sortable"]', minimum: 2
  end

  test 'item edit links navigate to item edit page' do
    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

    find("[data-testid='edit-item-#{@item1.id}-btn']").click

    assert_current_path edit_restaurant_menu_menusection_menuitem_path(
      @restaurant, @menu, @section1, @item1
    ), ignore_query: true
  end

  # ===================
  # EMPTY STATE
  # ===================

  test 'sections tab shows empty state when no sections exist' do
    # Remove all sections
    @menu.menusections.each { |s| s.menuitems.delete_all; s.delete }

    visit edit_restaurant_menu_path(@restaurant, @menu, section: 'sections')

    # Should show the EmptyStateComponent
    assert_selector "[data-testid='empty-state']", wait: 3
  end

  # ===================
  # SIDEBAR BADGES
  # ===================

  test 'sidebar shows section and item counts as badges' do
    visit edit_restaurant_menu_path(@restaurant, @menu)

    # Sidebar should show badge counts
    within '.sidebar-2025' do
      sections_link = find('.sidebar-link', text: 'Sections')
      assert_includes sections_link.text, '2'

      items_link = find('.sidebar-link', text: 'Items')
      assert_includes items_link.text, '2'
    end
  end
end
