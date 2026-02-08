require 'test_helper'

class RestaurantProvisioningServiceTest < ActiveSupport::TestCase
  test 'creates manager employee, default locale, and default 4-top table when missing' do
    user = users(:one)

    restaurant = Restaurant.create!(
      user: user,
      name: 'Provisioning Test',
      description: 'desc',
      currency: 'USD',
      address1: '123 Main',
      city: 'Town',
      postcode: '12345',
      country: 'US',
      status: :active,
      capacity: 10,
    )

    assert_equal 0, restaurant.employees.count
    assert_equal 0, restaurant.restaurantlocales.count
    assert_equal 0, restaurant.tablesettings.count

    RestaurantProvisioningService.call(restaurant: restaurant, user: user)

    assert restaurant.employees.exists?(user: user, role: :manager, status: :active)
    assert restaurant.restaurantlocales.exists?(status: :active)
    assert restaurant.restaurantlocales.exists?(status: :active, dfault: true)
    assert restaurant.tablesettings.exists?
    assert_equal 4, restaurant.tablesettings.order(:id).first.capacity
  end

  test 'does not create tax when country is blank' do
    user = users(:one)

    restaurant = Restaurant.create!(
      user: user,
      name: 'No Country',
      description: 'desc',
      currency: 'USD',
      address1: '123 Main',
      city: 'Town',
      postcode: '12345',
      country: nil,
      status: :active,
      capacity: 10,
    )

    RestaurantProvisioningService.call(restaurant: restaurant, user: user)

    assert_equal 0, restaurant.taxes.count
  end

  test 'creates tax only when country is set and a restaurant-services rate exists' do
    user = users(:one)

    restaurant = Restaurant.create!(
      user: user,
      name: 'With Country',
      description: 'desc',
      currency: 'EUR',
      address1: '123 Main',
      city: 'Town',
      postcode: '12345',
      country: 'IT',
      status: :active,
      capacity: 10,
    )

    Rails.application.stub(:config_for, { 'IT' => 10.0 }) do
      RestaurantProvisioningService.call(restaurant: restaurant, user: user)
    end

    assert_equal 1, restaurant.taxes.count
    assert_in_delta 10.0, restaurant.taxes.first.taxpercentage.to_f, 0.001
  end
end
