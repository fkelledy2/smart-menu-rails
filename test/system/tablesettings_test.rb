require "application_system_test_case"

class TablesettingsTest < ApplicationSystemTestCase
  setup do
    @tablesetting = tablesettings(:one)
  end

  test "visiting the index" do
    visit tablesettings_url
    assert_selector "h1", text: "Tablesettings"
  end

  test "should create tablesetting" do
    visit tablesettings_url
    click_on "New tablesetting"

    fill_in "Capacity", with: @tablesetting.capacity
    fill_in "Description", with: @tablesetting.description
    fill_in "Name", with: @tablesetting.name
    fill_in "Restaurant", with: @tablesetting.restaurant_id
    fill_in "Status", with: @tablesetting.status
    click_on "Create Tablesetting"

    assert_text "Tablesetting was successfully created"
    click_on "Back"
  end

  test "should update Tablesetting" do
    visit tablesetting_url(@tablesetting)
    click_on "Edit this tablesetting", match: :first

    fill_in "Capacity", with: @tablesetting.capacity
    fill_in "Description", with: @tablesetting.description
    fill_in "Name", with: @tablesetting.name
    fill_in "Restaurant", with: @tablesetting.restaurant_id
    fill_in "Status", with: @tablesetting.status
    click_on "Update Tablesetting"

    assert_text "Tablesetting was successfully updated"
    click_on "Back"
  end

  test "should destroy Tablesetting" do
    visit tablesetting_url(@tablesetting)
    click_on "Destroy this tablesetting", match: :first

    assert_text "Tablesetting was successfully destroyed"
  end
end
