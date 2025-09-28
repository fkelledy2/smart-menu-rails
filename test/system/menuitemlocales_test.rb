require 'application_system_test_case'

class MenuitemlocalesTest < ApplicationSystemTestCase
  setup do
    @menuitemlocale = menuitemlocales(:one)
  end

  test 'visiting the index' do
    visit menuitemlocales_url
    assert_selector 'h1', text: 'Menuitemlocales'
  end

  test 'should create menuitemlocale' do
    visit menuitemlocales_url
    click_on 'New menuitemlocale'

    fill_in 'Description', with: @menuitemlocale.description
    fill_in 'Locale', with: @menuitemlocale.locale
    fill_in 'Menuitem', with: @menuitemlocale.menuitem_id
    fill_in 'Name', with: @menuitemlocale.name
    fill_in 'Status', with: @menuitemlocale.status
    click_on 'Create Menuitemlocale'

    assert_text 'Menuitemlocale was successfully created'
    click_on 'Back'
  end

  test 'should update Menuitemlocale' do
    visit menuitemlocale_url(@menuitemlocale)
    click_on 'Edit this menuitemlocale', match: :first

    fill_in 'Description', with: @menuitemlocale.description
    fill_in 'Locale', with: @menuitemlocale.locale
    fill_in 'Menuitem', with: @menuitemlocale.menuitem_id
    fill_in 'Name', with: @menuitemlocale.name
    fill_in 'Status', with: @menuitemlocale.status
    click_on 'Update Menuitemlocale'

    assert_text 'Menuitemlocale was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Menuitemlocale' do
    visit menuitemlocale_url(@menuitemlocale)
    click_on 'Destroy this menuitemlocale', match: :first

    assert_text 'Menuitemlocale was successfully destroyed'
  end
end
