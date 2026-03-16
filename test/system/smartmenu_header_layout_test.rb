require 'application_system_test_case'

class SmartmenuHeaderLayoutTest < ApplicationSystemTestCase
  setup do
    @restaurant = Restaurant.create!(
      name: 'Test Restaurant',
      user: users(:one),
      address1: '123 Test St',
      city: 'Test City',
      state: 'TS',
      country: 'US',
      status: 'active',
    )

    @menu = Menu.create!(
      name: 'Test Menu',
      restaurant: @restaurant,
      user: users(:one),
    )

    @smartmenu = Smartmenu.create!(
      menu: @menu,
      restaurant: @restaurant,
    )
  end

  test 'no nested order-button-group divs' do
    visit smartmenu_url(@menu, view: 'customer')
    assert_selector '.header-order-row', visible: true, wait: 10

    # Count all order-button-group divs (including nested ones)
    all_button_groups = all('.order-button-group', visible: :all)
    assert_equal 1, all_button_groups.count, "Expected 1 order-button-group, found #{all_button_groups.count}"
  end

  test 'menu name and buttons on same row' do
    visit smartmenu_url(@menu, view: 'customer')
    assert_selector '.header-order-row', visible: true, wait: 10

    header = find('.header-order-row')
    menu_name = header.find('.menu-name')
    button_group = header.find('.order-button-group')

    # Check Y positions (should be on same row)
    menu_y = menu_name.native.location.y
    buttons_y = button_group.native.location.y
    y_diff = (menu_y - buttons_y).abs

    assert y_diff < 10, "Menu name and buttons not on same row (Y diff: #{y_diff}px)"

    # Check X positions (menu should be left of buttons)
    menu_x = menu_name.native.location.x
    buttons_x = button_group.native.location.x

    assert menu_x < buttons_x, "Menu name (X:#{menu_x}) should be left of buttons (X:#{buttons_x})"
  end
end
