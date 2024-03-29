require "application_system_test_case"

class RestaurantavailabilitiesTest < ApplicationSystemTestCase
  setup do
    @restaurantavailability = restaurantavailabilities(:one)
  end

  test "visiting the index" do
    visit restaurantavailabilities_url
    assert_selector "h1", text: "Restaurantavailabilities"
  end

  test "should create restaurantavailability" do
    visit restaurantavailabilities_url
    click_on "New restaurantavailability"

    fill_in "Dayofweek", with: @restaurantavailability.dayofweek
    fill_in "Endhour", with: @restaurantavailability.endhour
    fill_in "Endmin", with: @restaurantavailability.endmin
    fill_in "Restaurant", with: @restaurantavailability.restaurant_id
    fill_in "Starthour", with: @restaurantavailability.starthour
    fill_in "Startmin", with: @restaurantavailability.startmin
    click_on "Create Restaurantavailability"

    assert_text "Restaurantavailability was successfully created"
    click_on "Back"
  end

  test "should update Restaurantavailability" do
    visit restaurantavailability_url(@restaurantavailability)
    click_on "Edit this restaurantavailability", match: :first

    fill_in "Dayofweek", with: @restaurantavailability.dayofweek
    fill_in "Endhour", with: @restaurantavailability.endhour
    fill_in "Endmin", with: @restaurantavailability.endmin
    fill_in "Restaurant", with: @restaurantavailability.restaurant_id
    fill_in "Starthour", with: @restaurantavailability.starthour
    fill_in "Startmin", with: @restaurantavailability.startmin
    click_on "Update Restaurantavailability"

    assert_text "Restaurantavailability was successfully updated"
    click_on "Back"
  end

  test "should destroy Restaurantavailability" do
    visit restaurantavailability_url(@restaurantavailability)
    click_on "Destroy this restaurantavailability", match: :first

    assert_text "Restaurantavailability was successfully destroyed"
  end
end
