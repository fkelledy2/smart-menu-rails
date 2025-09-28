require 'application_system_test_case'

class GenimagesTest < ApplicationSystemTestCase
  setup do
    @genimage = genimages(:one)
  end

  test 'visiting the index' do
    visit genimages_url
    assert_selector 'h1', text: 'Genimages'
  end

  test 'should create genimage' do
    visit genimages_url
    click_on 'New genimage'

    fill_in 'Description', with: @genimage.description
    fill_in 'Image data', with: @genimage.image_data
    fill_in 'Menu', with: @genimage.menu_id
    fill_in 'Menuitem', with: @genimage.menuitem_id
    fill_in 'Menusection', with: @genimage.menusection_id
    fill_in 'Name', with: @genimage.name
    fill_in 'Restaurant', with: @genimage.restaurant_id
    click_on 'Create Genimage'

    assert_text 'Genimage was successfully created'
    click_on 'Back'
  end

  test 'should update Genimage' do
    visit genimage_url(@genimage)
    click_on 'Edit this genimage', match: :first

    fill_in 'Description', with: @genimage.description
    fill_in 'Image data', with: @genimage.image_data
    fill_in 'Menu', with: @genimage.menu_id
    fill_in 'Menuitem', with: @genimage.menuitem_id
    fill_in 'Menusection', with: @genimage.menusection_id
    fill_in 'Name', with: @genimage.name
    fill_in 'Restaurant', with: @genimage.restaurant_id
    click_on 'Update Genimage'

    assert_text 'Genimage was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Genimage' do
    visit genimage_url(@genimage)
    click_on 'Destroy this genimage', match: :first

    assert_text 'Genimage was successfully destroyed'
  end
end
