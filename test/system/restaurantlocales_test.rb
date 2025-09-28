require 'application_system_test_case'

class RestaurantlocalesTest < ApplicationSystemTestCase
  setup do
    @restaurantlocale = restaurantlocales(:one)
  end

  test 'visiting the index' do
    visit restaurantlocales_url
    assert_selector 'h1', text: 'Restaurantlocales'
  end

  test 'should create restaurantlocale' do
    visit restaurantlocales_url
    click_on 'New restaurantlocale'

    fill_in 'Locale', with: @restaurantlocale.locale
    fill_in 'Restaurant', with: @restaurantlocale.restaurant_id
    fill_in 'Status', with: @restaurantlocale.status
    click_on 'Create Restaurantlocale'

    assert_text 'Restaurantlocale was successfully created'
    click_on 'Back'
  end

  test 'should update Restaurantlocale' do
    visit restaurantlocale_url(@restaurantlocale)
    click_on 'Edit this restaurantlocale', match: :first

    fill_in 'Locale', with: @restaurantlocale.locale
    fill_in 'Restaurant', with: @restaurantlocale.restaurant_id
    fill_in 'Status', with: @restaurantlocale.status
    click_on 'Update Restaurantlocale'

    assert_text 'Restaurantlocale was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Restaurantlocale' do
    visit restaurantlocale_url(@restaurantlocale)
    click_on 'Destroy this restaurantlocale', match: :first

    assert_text 'Restaurantlocale was successfully destroyed'
  end
end
