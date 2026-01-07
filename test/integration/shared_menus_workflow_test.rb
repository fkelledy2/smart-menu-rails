require 'test_helper'

class SharedMenusWorkflowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  setup do
    @previous_allow_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false

    @owner = users(:one)
    @restaurant_a = restaurants(:one)

    # Create a second restaurant owned by the same user (required by the spec constraints)
    @restaurant_b = Restaurant.create!(
      name: 'Shared Target Restaurant',
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
      user: @owner,
    )

    Restaurantlocale.create!(restaurant: @restaurant_a, locale: 'en', status: :active, dfault: true)
    Restaurantlocale.create!(restaurant: @restaurant_b, locale: 'en', status: :active, dfault: true)

    Tablesetting.create!(restaurant: @restaurant_a, name: 'Table A', capacity: 4, status: :occupied, tabletype: :indoor)
    Tablesetting.create!(restaurant: @restaurant_b, name: 'Table B', capacity: 4, status: :occupied, tabletype: :indoor)

    Tax.create!(restaurant: @restaurant_a, name: 'VAT', taxpercentage: 10.0, taxtype: :local, status: :active)
    Tip.create!(restaurant: @restaurant_a, percentage: 10.0, status: :active)
    Tax.create!(restaurant: @restaurant_b, name: 'VAT', taxpercentage: 10.0, taxtype: :local, status: :active)
    Tip.create!(restaurant: @restaurant_b, percentage: 10.0, status: :active)

    Warden.test_mode!
    login_as(@owner, scope: :user)

    @menu = Menu.create!(
      restaurant: @restaurant_a,
      owner_restaurant: @restaurant_a,
      name: 'Shared Menu',
      status: :active,
    )

    get new_restaurant_menu_path(@restaurant_a)
    assert_response :success

    RestaurantMenu.create!(
      restaurant: @restaurant_a,
      menu: @menu,
      status: :active,
      availability_override_enabled: false,
      availability_state: :available,
    )

    @menusection = Menusection.create!(
      menu: @menu,
      name: 'Starters',
      status: :active,
    )
  end

  test 'can attach menu to another owned restaurant and override availability' do
    assert_difference('RestaurantMenu.count', 1) do
      post attach_restaurant_menu_path(@restaurant_b, @menu)
    end
    assert_redirected_to edit_restaurant_path(@restaurant_b, section: 'menus')

    rm = RestaurantMenu.find_by!(restaurant_id: @restaurant_b.id, menu_id: @menu.id)

    patch availability_restaurant_restaurant_menu_path(@restaurant_b, rm), params: {
      availability_override_enabled: 'true',
      availability_state: 'unavailable',
    }
    assert_response :redirect

    rm.reload
    assert rm.availability_override_enabled?
    assert_equal 'unavailable', rm.availability_state

    # Owner restaurant attachment should remain default
    owner_rm = RestaurantMenu.find_by!(restaurant_id: @restaurant_a.id, menu_id: @menu.id)
    assert_not owner_rm.availability_override_enabled?
  end

  test 'attached restaurant cannot create menu sections (read-only enforcement)' do
    post attach_restaurant_menu_path(@restaurant_b, @menu)
    assert_redirected_to edit_restaurant_path(@restaurant_b, section: 'menus')

    assert_no_difference('Menusection.count') do
      post restaurant_menu_menusections_path(@restaurant_b, @menu), params: {
        menusection: {
          name: 'Should Not Create',
          status: :active,
          menu_id: @menu.id,
          sequence: 1,
        },
      }
    end

    assert_redirected_to edit_restaurant_path(@restaurant_b, section: 'menus')
    assert_equal 'This menu is read-only for this restaurant', flash[:alert]
  end

  test "attached menu appears in restaurant B's menus list" do
    post attach_restaurant_menu_path(@restaurant_b, @menu)
    assert_redirected_to edit_restaurant_path(@restaurant_b, section: 'menus')

    get edit_restaurant_path(@restaurant_b, section: 'menus')
    follow_redirect! while response.redirect?
    assert_response :success
    assert_includes response.body, @menu.name
  end

  test 'detaching a menu removes it from restaurant B' do
    post attach_restaurant_menu_path(@restaurant_b, @menu)
    assert_redirected_to edit_restaurant_path(@restaurant_b, section: 'menus')

    assert_difference("RestaurantMenu.where(restaurant_id: @restaurant_b.id, menu_id: @menu.id).count", -1) do
      delete detach_restaurant_menu_path(@restaurant_b, @menu)
    end
    assert_redirected_to edit_restaurant_path(@restaurant_b, section: 'menus')
  end

  test 'reorder in restaurant B does not affect ordering in restaurant A' do
    menu2 = Menu.create!(
      restaurant: @restaurant_a,
      owner_restaurant: @restaurant_a,
      name: 'Shared Menu Two',
      status: :active,
    )

    rm_a_1 = RestaurantMenu.find_by!(restaurant_id: @restaurant_a.id, menu_id: @menu.id)
    rm_a_2 = RestaurantMenu.create!(
      restaurant: @restaurant_a,
      menu: menu2,
      status: :active,
      availability_override_enabled: false,
      availability_state: :available,
      sequence: 2,
    )
    rm_a_1.update!(sequence: 1)

    post attach_restaurant_menu_path(@restaurant_b, @menu)
    post attach_restaurant_menu_path(@restaurant_b, menu2)

    rm_b_1 = RestaurantMenu.find_by!(restaurant_id: @restaurant_b.id, menu_id: @menu.id)
    rm_b_2 = RestaurantMenu.find_by!(restaurant_id: @restaurant_b.id, menu_id: menu2.id)
    rm_b_1.update!(sequence: 1)
    rm_b_2.update!(sequence: 2)

    patch reorder_restaurant_restaurant_menus_path(@restaurant_b), params: {
      order: [
        { id: rm_b_1.id, sequence: 2 },
        { id: rm_b_2.id, sequence: 1 },
      ],
    }, as: :json
    assert_response :success

    assert_equal 2, rm_b_1.reload.sequence
    assert_equal 1, rm_b_2.reload.sequence

    assert_equal 1, rm_a_1.reload.sequence
    assert_equal 2, rm_a_2.reload.sequence
  end

  teardown do
    Warden.test_reset!

    ActionController::Base.allow_forgery_protection = @previous_allow_forgery_protection
  end
end
