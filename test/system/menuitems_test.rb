require "application_system_test_case"

class MenuitemsTest < ApplicationSystemTestCase
  setup do
    @menuitem = menuitems(:one)
  end

  test "visiting the index" do
    visit menuitems_url
    assert_selector "h1", text: "Menuitems"
  end

  test "should create menuitem" do
    visit menuitems_url
    click_on "New menuitem"

    fill_in "Calories", with: @menuitem.calories
    fill_in "Description", with: @menuitem.description
    fill_in "Image", with: @menuitem.image
    fill_in "Menusection", with: @menuitem.menusection_id
    fill_in "Name", with: @menuitem.name
    fill_in "Price", with: @menuitem.price
    fill_in "Sequence", with: @menuitem.sequence
    fill_in "Status", with: @menuitem.status
    click_on "Create Menuitem"

    assert_text "Menuitem was successfully created"
    click_on "Back"
  end

  test "should update Menuitem" do
    visit menuitem_url(@menuitem)
    click_on "Edit this menuitem", match: :first

    fill_in "Calories", with: @menuitem.calories
    fill_in "Description", with: @menuitem.description
    fill_in "Image", with: @menuitem.image
    fill_in "Menusection", with: @menuitem.menusection_id
    fill_in "Name", with: @menuitem.name
    fill_in "Price", with: @menuitem.price
    fill_in "Sequence", with: @menuitem.sequence
    fill_in "Status", with: @menuitem.status
    click_on "Update Menuitem"

    assert_text "Menuitem was successfully updated"
    click_on "Back"
  end

  test "should destroy Menuitem" do
    visit menuitem_url(@menuitem)
    click_on "Destroy this menuitem", match: :first

    assert_text "Menuitem was successfully destroyed"
  end
end
