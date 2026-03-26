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
      menusection: menusections(:mains_section),
    )
    MenuitemSizeMapping.create!(menuitem: @item_with_sizes, size: @size_small, price: 3.00)
    MenuitemSizeMapping.create!(menuitem: @item_with_sizes, size: @size_large, price: 4.50)

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

    assert_selector('.size-add-group .dropdown-menu.show', wait: 3),
      'Size dropdown should open with .show class after clicking toggle'
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

    find('.size-add-group .dropdown-menu.show .size-option', wait: 3).click

    assert_selector('#addItemToOrderModal.show', wait: 5),
      'Clicking a size option should open the add-to-order modal'
  end

  test 'size toggle is disabled when no table is set' do
    smartmenu_no_table = Smartmenu.create!(
      slug: 'no-table-size-test',
      public_token: 'e' * 64,
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: nil,
    )

    visit table_link_path(smartmenu_no_table.public_token)
    assert_testid('menu-content-container', wait: 5)
    sleep 0.6

    btn = find_testid("add-item-btn-#{@item_with_sizes.id}", wait: 5)
    assert btn.disabled?, 'Size toggle should be disabled when no table is set'
  end
end
