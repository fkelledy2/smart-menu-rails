require 'test_helper'

class IngredientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user)
    sign_in @user
    @ingredient = ingredients(:one)
    @ingredient.update!(restaurant: @restaurant)
  end

  test 'GET index returns success' do
    get restaurant_ingredients_path(@restaurant)
    assert_response :success
  end

  test 'GET index redirects unauthenticated users' do
    sign_out @user
    get restaurant_ingredients_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET new returns success' do
    get new_restaurant_ingredient_path(@restaurant)
    assert_response :success
  end

  test 'GET edit returns success' do
    get edit_restaurant_ingredient_path(@restaurant, @ingredient)
    assert_response :success
  end

  test 'POST create with valid params redirects to index' do
    post restaurant_ingredients_path(@restaurant), params: {
      ingredient: {
        name: 'Tomato',
        unit_of_measure: 'kg',
        current_cost_per_unit: 2.5,
        is_shared: false,
      },
    }
    assert_redirected_to restaurant_ingredients_path(@restaurant)
  end

  test 'POST create with invalid params re-renders new' do
    post restaurant_ingredients_path(@restaurant), params: {
      ingredient: {
        name: '',
      },
    }
    assert_includes [200, 422], response.status
  end

  test 'PATCH update with valid params redirects to index' do
    patch restaurant_ingredient_path(@restaurant, @ingredient), params: {
      ingredient: {
        name: 'Updated Ingredient',
        unit_of_measure: 'g',
      },
    }
    assert_redirected_to restaurant_ingredients_path(@restaurant)
  end

  test 'DELETE destroy archives ingredient and redirects' do
    delete restaurant_ingredient_path(@restaurant, @ingredient)
    assert_redirected_to restaurant_ingredients_path(@restaurant)
    @ingredient.reload
    assert @ingredient.archived
  end
end
