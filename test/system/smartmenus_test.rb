require 'application_system_test_case'

class SmartmenusTest < ApplicationSystemTestCase
  setup do
    @smartmenu = smartmenus(:one)
  end

  test 'visiting the index' do
    visit smartmenus_url
    assert_selector 'h1', text: 'Smartmenus'
  end

  test 'should create smartmenu' do
    visit smartmenus_url
    click_on 'New smartmenu'

    fill_in 'Menu', with: @smartmenu.menu_id
    fill_in 'Restaurant', with: @smartmenu.restaurant_id
    fill_in 'Slug', with: @smartmenu.slug
    fill_in 'Tablesetting', with: @smartmenu.tablesetting_id
    click_on 'Create Smartmenu'

    assert_text 'Smartmenu was successfully created'
    click_on 'Back'
  end

  test 'should update Smartmenu' do
    visit smartmenu_url(@smartmenu)
    click_on 'Edit this smartmenu', match: :first

    fill_in 'Menu', with: @smartmenu.menu_id
    fill_in 'Restaurant', with: @smartmenu.restaurant_id
    fill_in 'Slug', with: @smartmenu.slug
    fill_in 'Tablesetting', with: @smartmenu.tablesetting_id
    click_on 'Update Smartmenu'

    assert_text 'Smartmenu was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Smartmenu' do
    visit smartmenu_url(@smartmenu)
    click_on 'Destroy this smartmenu', match: :first

    assert_text 'Smartmenu was successfully destroyed'
  end
end
