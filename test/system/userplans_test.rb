require "application_system_test_case"

class UserplansTest < ApplicationSystemTestCase
  setup do
    @userplan = userplans(:one)
  end

  test "visiting the index" do
    visit userplans_url
    assert_selector "h1", text: "Userplans"
  end

  test "should create userplan" do
    visit userplans_url
    click_on "New userplan"

    fill_in "Plan", with: @userplan.plan_id
    fill_in "User", with: @userplan.user_id
    click_on "Create Userplan"

    assert_text "Userplan was successfully created"
    click_on "Back"
  end

  test "should update Userplan" do
    visit userplan_url(@userplan)
    click_on "Edit this userplan", match: :first

    fill_in "Plan", with: @userplan.plan_id
    fill_in "User", with: @userplan.user_id
    click_on "Update Userplan"

    assert_text "Userplan was successfully updated"
    click_on "Back"
  end

  test "should destroy Userplan" do
    visit userplan_url(@userplan)
    click_on "Destroy this userplan", match: :first

    assert_text "Userplan was successfully destroyed"
  end
end
