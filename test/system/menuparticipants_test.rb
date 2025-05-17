require "application_system_test_case"

class MenuparticipantsTest < ApplicationSystemTestCase
  setup do
    @menuparticipant = menuparticipants(:one)
  end

  test "visiting the index" do
    visit menuparticipants_url
    assert_selector "h1", text: "Menuparticipants"
  end

  test "should create menuparticipant" do
    visit menuparticipants_url
    click_on "New menuparticipant"

    fill_in "Preferredlocale", with: @menuparticipant.preferredlocale
    fill_in "Sessionid", with: @menuparticipant.sessionid
    fill_in "Smartmenu", with: @menuparticipant.smartmenu_id
    click_on "Create Menuparticipant"

    assert_text "Menuparticipant was successfully created"
    click_on "Back"
  end

  test "should update Menuparticipant" do
    visit menuparticipant_url(@menuparticipant)
    click_on "Edit this menuparticipant", match: :first

    fill_in "Preferredlocale", with: @menuparticipant.preferredlocale
    fill_in "Sessionid", with: @menuparticipant.sessionid
    fill_in "Smartmenu", with: @menuparticipant.smartmenu_id
    click_on "Update Menuparticipant"

    assert_text "Menuparticipant was successfully updated"
    click_on "Back"
  end

  test "should destroy Menuparticipant" do
    visit menuparticipant_url(@menuparticipant)
    click_on "Destroy this menuparticipant", match: :first

    assert_text "Menuparticipant was successfully destroyed"
  end
end
