require 'application_system_test_case'

class MenusectionlocalesTest < ApplicationSystemTestCase
  setup do
    @menusectionlocale = menusectionlocales(:one)
  end

  test 'visiting the index' do
    visit menusectionlocales_url
    assert_selector 'h1', text: 'Menusectionlocales'
  end

  test 'should create menusectionlocale' do
    visit menusectionlocales_url
    click_on 'New menusectionlocale'

    fill_in 'Description', with: @menusectionlocale.description
    fill_in 'Locale', with: @menusectionlocale.locale
    fill_in 'Menusection', with: @menusectionlocale.menusection_id
    fill_in 'Name', with: @menusectionlocale.name
    fill_in 'Status', with: @menusectionlocale.status
    click_on 'Create Menusectionlocale'

    assert_text 'Menusectionlocale was successfully created'
    click_on 'Back'
  end

  test 'should update Menusectionlocale' do
    visit menusectionlocale_url(@menusectionlocale)
    click_on 'Edit this menusectionlocale', match: :first

    fill_in 'Description', with: @menusectionlocale.description
    fill_in 'Locale', with: @menusectionlocale.locale
    fill_in 'Menusection', with: @menusectionlocale.menusection_id
    fill_in 'Name', with: @menusectionlocale.name
    fill_in 'Status', with: @menusectionlocale.status
    click_on 'Update Menusectionlocale'

    assert_text 'Menusectionlocale was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Menusectionlocale' do
    visit menusectionlocale_url(@menusectionlocale)
    click_on 'Destroy this menusectionlocale', match: :first

    assert_text 'Menusectionlocale was successfully destroyed'
  end
end
