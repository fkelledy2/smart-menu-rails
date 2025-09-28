require 'application_system_test_case'

class RestaurantsTest < ApplicationSystemTestCase
  setup do
    @restaurant = restaurants(:one)
  end

  test 'visiting the index' do
    visit restaurants_url
    assert_selector 'h1', text: 'Restaurants'
  end

  test 'should create restaurant' do
    visit restaurants_url
    click_on 'New restaurant'

    fill_in 'Address1', with: @restaurant.address1
    fill_in 'Address2', with: @restaurant.address2
    fill_in 'Capacity', with: @restaurant.capacity
    fill_in 'City', with: @restaurant.city
    fill_in 'Country', with: @restaurant.country
    fill_in 'Description', with: @restaurant.description
    fill_in 'Image', with: @restaurant.image
    fill_in 'Name', with: @restaurant.name
    fill_in 'Postcode', with: @restaurant.postcode
    fill_in 'State', with: @restaurant.state
    fill_in 'Status', with: @restaurant.status
    fill_in 'User', with: @restaurant.user_id
    click_on 'Create Restaurant'

    assert_text 'Restaurant was successfully created'
    click_on 'Back'
  end

  test 'should update Restaurant' do
    visit restaurant_url(@restaurant)
    click_on 'Edit this restaurant', match: :first

    fill_in 'Address1', with: @restaurant.address1
    fill_in 'Address2', with: @restaurant.address2
    fill_in 'Capacity', with: @restaurant.capacity
    fill_in 'City', with: @restaurant.city
    fill_in 'Country', with: @restaurant.country
    fill_in 'Description', with: @restaurant.description
    fill_in 'Image', with: @restaurant.image
    fill_in 'Name', with: @restaurant.name
    fill_in 'Postcode', with: @restaurant.postcode
    fill_in 'State', with: @restaurant.state
    fill_in 'Status', with: @restaurant.status
    fill_in 'User', with: @restaurant.user_id
    click_on 'Update Restaurant'

    assert_text 'Restaurant was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Restaurant' do
    visit restaurant_url(@restaurant)
    click_on 'Destroy this restaurant', match: :first

    assert_text 'Restaurant was successfully destroyed'
  end
end
