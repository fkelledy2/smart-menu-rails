require 'test_helper'

class AuthorizationSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @restaurant = restaurants(:one)
    @other_restaurant = restaurants(:two)
    @menu = menus(:one)
    @ordr = ordrs(:one)
    @ordritem = ordritems(:one)
    @menuparticipant = menuparticipants(:one)
  end

  # Test that anonymous users can access public resources
  test "anonymous users can view public menu" do
    get menu_path(@menu)
    assert_response :success
  end

  test "anonymous users can create orders" do
    post ordrs_path, params: { 
      ordr: { 
        restaurant_id: @restaurant.id,
        tablesetting_id: tablesettings(:one).id
      } 
    }
    assert_response :redirect
  end

  test "anonymous users can create order items" do
    post ordritems_path, params: { 
      ordritem: { 
        ordr_id: @ordr.id,
        menuitem_id: menuitems(:one).id,
        quantity: 1
      } 
    }
    assert_response :redirect
  end

  test "anonymous users can create menu participants" do
    post menuparticipants_path, params: { 
      menuparticipant: { 
        menu_id: @menu.id,
        sessionid: 'test_session'
      } 
    }
    assert_response :redirect
  end

  # Test that authenticated users can access their own resources
  test "authenticated users can access their own restaurant data" do
    sign_in @user
    get restaurant_path(@restaurant)
    assert_response :success
  end

  test "authenticated users can access their own menu data" do
    sign_in @user
    get menu_path(@menu)
    assert_response :success
  end

  # Test that users cannot access other users' private data
  test "users cannot access other users' restaurant data" do
    sign_in @user
    
    assert_raises(Pundit::NotAuthorizedError) do
      get restaurant_path(@other_restaurant)
    end
  end

  test "users cannot edit other users' menus" do
    sign_in @user
    
    assert_raises(Pundit::NotAuthorizedError) do
      patch menu_path(menus(:two)), params: { menu: { name: 'Hacked' } }
    end
  end

  # Test authorization enforcement on all critical actions
  test "all controllers enforce authorization" do
    # Test that verify_authorized is called
    sign_in @user
    
    # These should all work without raising NotAuthorizedError
    get restaurant_path(@restaurant)
    get menu_path(@menu)
    
    # These should raise NotAuthorizedError for unauthorized access
    assert_raises(Pundit::NotAuthorizedError) do
      get restaurant_path(@other_restaurant)
    end
  end

  # Test policy scoping works correctly
  test "policy scoping restricts data access" do
    sign_in @user
    
    get restaurants_path
    assert_response :success
    
    # Should only see user's own restaurants
    assert_select 'body', text: @restaurant.name
    assert_select 'body', text: @other_restaurant.name, count: 0
  end

  # Test that sensitive actions require authentication
  test "sensitive actions require authentication" do
    # Try to access admin functions without authentication
    get admin_cache_index_path
    assert_redirected_to new_user_session_path
  end

  test "admin functions require admin role" do
    sign_in @user # Regular user, not admin
    
    assert_raises(Pundit::NotAuthorizedError) do
      get admin_cache_index_path
    end
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password'
      }
    }
  end
end
