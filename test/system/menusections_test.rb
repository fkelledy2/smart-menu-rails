require 'application_system_test_case'

class MenusectionsTest < ApplicationSystemTestCase
  setup do
    @menusection = menusections(:one)
  end

  test 'visiting the index' do
    visit menusections_url
    assert_selector 'h1', text: 'Menusections'
  end

  test 'should create menusection' do
    visit menusections_url
    click_on 'New menusection'

    fill_in 'Description', with: @menusection.description
    fill_in 'Image', with: @menusection.image
    fill_in 'Menu', with: @menusection.menu_id
    fill_in 'Name', with: @menusection.name
    fill_in 'Sequence', with: @menusection.sequence
    fill_in 'Status', with: @menusection.status
    click_on 'Create Menusection'

    assert_text 'Menusection was successfully created'
    click_on 'Back'
  end

  test 'should update Menusection' do
    visit menusection_url(@menusection)
    click_on 'Edit this menusection', match: :first

    fill_in 'Description', with: @menusection.description
    fill_in 'Image', with: @menusection.image
    fill_in 'Menu', with: @menusection.menu_id
    fill_in 'Name', with: @menusection.name
    fill_in 'Sequence', with: @menusection.sequence
    fill_in 'Status', with: @menusection.status
    click_on 'Update Menusection'

    assert_text 'Menusection was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Menusection' do
    visit menusection_url(@menusection)
    click_on 'Destroy this menusection', match: :first

    assert_text 'Menusection was successfully destroyed'
  end
end
