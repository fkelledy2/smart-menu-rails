require 'test_helper'

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @tag = tags(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user)
  end

  test 'GET index returns success' do
    get restaurant_tags_path(@restaurant)
    assert_response :success
  end

  test 'GET index redirects unauthenticated users' do
    sign_out @user
    get restaurant_tags_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'DELETE destroy via JSON archives tag' do
    delete restaurant_tag_path(@restaurant, @tag), as: :json
    assert_response :no_content
    @tag.reload
    assert @tag.archived
  end
end
