require "application_system_test_case"

class MenulocalesTest < ApplicationSystemTestCase
  setup do
    @menulocale = menulocales(:one)
  end

  test "visiting the index" do
    visit menulocales_url
    assert_selector "h1", text: "Menulocales"
  end

  test "should create menulocale" do
    visit menulocales_url
    click_on "New menulocale"

    fill_in "Description", with: @menulocale.description
    fill_in "Locale", with: @menulocale.locale
    fill_in "Menu", with: @menulocale.menu_id
    fill_in "Name", with: @menulocale.name
    fill_in "Status", with: @menulocale.status
    click_on "Create Menulocale"

    assert_text "Menulocale was successfully created"
    click_on "Back"
  end

  test "should update Menulocale" do
    visit menulocale_url(@menulocale)
    click_on "Edit this menulocale", match: :first

    fill_in "Description", with: @menulocale.description
    fill_in "Locale", with: @menulocale.locale
    fill_in "Menu", with: @menulocale.menu_id
    fill_in "Name", with: @menulocale.name
    fill_in "Status", with: @menulocale.status
    click_on "Update Menulocale"

    assert_text "Menulocale was successfully updated"
    click_on "Back"
  end

  test "should destroy Menulocale" do
    visit menulocale_url(@menulocale)
    click_on "Destroy this menulocale", match: :first

    assert_text "Menulocale was successfully destroyed"
  end
end
