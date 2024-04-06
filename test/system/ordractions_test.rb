require "application_system_test_case"

class OrdractionsTest < ApplicationSystemTestCase
  setup do
    @ordraction = ordractions(:one)
  end

  test "visiting the index" do
    visit ordractions_url
    assert_selector "h1", text: "Ordractions"
  end

  test "should create ordraction" do
    visit ordractions_url
    click_on "New ordraction"

    fill_in "Action", with: @ordraction.action
    fill_in "Employee", with: @ordraction.employee_id
    fill_in "Ordr", with: @ordraction.ordr_id
    fill_in "Ordritem", with: @ordraction.ordritem_id
    fill_in "Ordrparticipant", with: @ordraction.ordrparticipant_id
    fill_in "Sessionid", with: @ordraction.sessionid
    click_on "Create Ordraction"

    assert_text "Ordraction was successfully created"
    click_on "Back"
  end

  test "should update Ordraction" do
    visit ordraction_url(@ordraction)
    click_on "Edit this ordraction", match: :first

    fill_in "Action", with: @ordraction.action
    fill_in "Employee", with: @ordraction.employee_id
    fill_in "Ordr", with: @ordraction.ordr_id
    fill_in "Ordritem", with: @ordraction.ordritem_id
    fill_in "Ordrparticipant", with: @ordraction.ordrparticipant_id
    fill_in "Sessionid", with: @ordraction.sessionid
    click_on "Update Ordraction"

    assert_text "Ordraction was successfully updated"
    click_on "Back"
  end

  test "should destroy Ordraction" do
    visit ordraction_url(@ordraction)
    click_on "Destroy this ordraction", match: :first

    assert_text "Ordraction was successfully destroyed"
  end
end
