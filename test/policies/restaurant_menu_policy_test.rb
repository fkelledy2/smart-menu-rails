require 'test_helper'

class RestaurantMenuPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)

    @restaurant_a = restaurants(:one) # owned by @user
    @restaurant_other = restaurants(:two) # owned by @other_user

    @restaurant_b = Restaurant.create!(
      name: 'Policy Target Restaurant',
      description: 'Second restaurant owned by same user',
      address1: 'Addr',
      address2: 'Addr2',
      city: 'City',
      state: 'State',
      postcode: '00000',
      country: 'Country',
      status: :active,
      capacity: 10,
      currency: 'USD',
      user: @user,
    )

    @menu = Menu.create!(
      restaurant: @restaurant_a,
      owner_restaurant: @restaurant_a,
      name: 'Policy Shared Menu',
      status: :active,
    )

    @rm_a = RestaurantMenu.create!(
      restaurant: @restaurant_a,
      menu: @menu,
      status: :active,
      availability_override_enabled: false,
      availability_state: :available,
    )

    @rm_b = RestaurantMenu.create!(
      restaurant: @restaurant_b,
      menu: @menu,
      status: :active,
      availability_override_enabled: false,
      availability_state: :available,
    )
  end

  test 'update? allows restaurant owner to change attachment settings' do
    policy = RestaurantMenuPolicy.new(@user, @rm_b)
    assert policy.update?
    assert policy.availability?
    assert policy.reorder?
    assert policy.bulk_update?
    assert policy.bulk_availability?
  end

  test 'update? denies non-owner of the restaurant' do
    policy = RestaurantMenuPolicy.new(@other_user, @rm_b)
    assert_not policy.update?
  end

  test 'attach? allows user who owns target restaurant and menu owner restaurant' do
    policy = RestaurantMenuPolicy.new(@user, @rm_b)
    assert policy.attach?
  end

  test 'attach? denies user who does not own the target restaurant' do
    policy = RestaurantMenuPolicy.new(@other_user, @rm_b)
    assert_not policy.attach?
  end

  test 'detach? allows user who owns target restaurant and menu owner restaurant' do
    policy = RestaurantMenuPolicy.new(@user, @rm_b)
    assert policy.detach?
  end

  test 'detach? denies user who does not own the menu owner restaurant' do
    foreign_menu = Menu.create!(
      restaurant: @restaurant_other,
      owner_restaurant: @restaurant_other,
      name: 'Foreign Shared Menu',
      status: :active,
    )
    foreign_rm = RestaurantMenu.create!(
      restaurant: @restaurant_a,
      menu: foreign_menu,
      status: :active,
      availability_override_enabled: false,
      availability_state: :available,
    )

    policy = RestaurantMenuPolicy.new(@user, foreign_rm)
    assert_not policy.detach?
  end
end
