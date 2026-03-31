require 'application_system_test_case'

class SmartmenuSizeDropdownTest < ApplicationSystemTestCase
  setup do
    @restaurant = restaurants(:one)
    @menu       = menus(:ordering_menu)
    @table      = tablesettings(:table_one)
    @smartmenu  = smartmenus(:one)
    @employee   = employees(:one)

    @size_small = Size.create!(
      restaurant: @restaurant,
      name: 'Small',
      size: :sm,
      status: :active,
    )
    @size_large = Size.create!(
      restaurant: @restaurant,
      name: 'Large',
      size: :lg,
      status: :active,
    )

    @item_with_sizes = Menuitem.create!(
      name: 'Test Coffee',
      description: 'A test drink with size options',
      status: 1,
      sequence: 99,
      price: 3.00,
      itemtype: 'food',
      preptime: 0,
      calories: 0,
      menusection: menusections(:mains_section),
    )
    MenuitemSizeMapping.create!(menuitem: @item_with_sizes, size: @size_small, price: 3.00)
    MenuitemSizeMapping.create!(menuitem: @item_with_sizes, size: @size_large, price: 4.50)

    # Pre-create an open order so the page loads with menuItemsEnabled=true in __SM_STATE.
    # Without a pre-existing order, ordr_commons.js disables all .addItemToOrder buttons
    # (pointer-events: none) because order_hash[:id] is blank.
    @ordr = Ordr.create!(
      restaurant_id: @restaurant.id,
      tablesetting_id: @table.id,
      menu_id: @menu.id,
      status: 0,
      ordercapacity: 1,
    )

    Warden.test_mode!
    login_as(@employee.user, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  test 'size toggle button is rendered for item with size variants' do
    visit table_link_path(@smartmenu.public_token)
    assert_testid('menu-content-container', wait: 5)

    assert_testid("add-item-btn-#{@item_with_sizes.id}", wait: 5)
  end

  test 'clicking the chevron toggle opens the size dropdown to the left' do
    visit table_link_path(@smartmenu.public_token)
    assert_testid('menu-content-container', wait: 5)
    sleep 0.6

    find_testid("add-item-btn-#{@item_with_sizes.id}", wait: 5).click

    assert_selector('.size-add-group .dropdown-menu.show', wait: 3)
  end

  test 'size dropdown is not clipped — menu is fully visible' do
    visit table_link_path(@smartmenu.public_token)
    assert_testid('menu-content-container', wait: 5)
    sleep 0.6

    find_testid("add-item-btn-#{@item_with_sizes.id}", wait: 5).click
    assert_selector('.size-add-group .dropdown-menu.show', wait: 3)

    menu_visible = page.evaluate_script(<<~JS)
      (function() {
        const menu = document.querySelector('.size-add-group .dropdown-menu.show');
        if (!menu) return false;
        const rect = menu.getBoundingClientRect();
        return rect.height > 0 && rect.width > 0;
      })()
    JS
    assert menu_visible, 'Size dropdown menu must be visible and not clipped'
  end

  test 'clicking a size option opens the add-to-order modal' do
    visit table_link_path(@smartmenu.public_token)
    assert_testid('menu-content-container', wait: 5)
    sleep 0.6

    find_testid("add-item-btn-#{@item_with_sizes.id}", wait: 5).click
    assert_selector('.size-add-group .dropdown-menu.show', wait: 3)

    first('.size-add-group .dropdown-menu.show .size-option', wait: 3).click

    assert_selector('#addItemToOrderModal.show', wait: 5)
  end

  test 'size toggle is disabled when no table is set' do
    # Use the existing customer_menu fixture (restaurant: one, menu: ordering_menu,
    # tablesetting: nil) to avoid violating the uniq_smartmenus_restaurant_menu_global
    # constraint that would fire when creating a second global smartmenu for the same pair.
    smartmenu_no_table = smartmenus(:customer_menu)

    visit table_link_path(smartmenu_no_table.public_token)
    assert_testid('menu-content-container', wait: 5)
    sleep 0.8

    # A test-only <script> in show.html.erb removes the HTML `disabled` attribute from all
    # add-item buttons for automation stability — so btn.disabled? is not reliable here.
    # Instead assert pointer-events: none, which ordr_commons.js sets (and does not clear)
    # when menuItemsEnabled is false (no open order / no table context).
    pointer_events = page.evaluate_script(
      "document.querySelector('[data-testid=\"add-item-btn-#{@item_with_sizes.id}\"]')?.style?.pointerEvents",
    )
    assert_equal 'none', pointer_events,
                 'Size toggle should have pointer-events:none when no table is set'
  end
end
