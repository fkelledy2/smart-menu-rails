require 'application_system_test_case'

class MenuLayoutToggleTest < ApplicationSystemTestCase
  setup do
    @smartmenu = smartmenus(:one)
  end

  test 'layout buttons have menu-layout controller' do
    visit smartmenu_path(@smartmenu.slug, view: 'customer')

    within('[data-controller*="menu-layout"]') do
      assert_selector 'button[data-menu-layout-target="cardBtn"]'
      assert_selector 'button[data-menu-layout-target="listBtn"]'
    end
  end

  test 'clicking list button works' do
    visit smartmenu_path(@smartmenu.slug, view: 'customer')

    find('button[data-menu-layout-target="listBtn"]').click
    sleep 0.5

    assert_selector '.menu-layout-list', wait: 2
  end
end
