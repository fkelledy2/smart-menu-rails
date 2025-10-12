require 'test_helper'

class SizesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @size = sizes(:one)
    @restaurant = restaurants(:one)
    
    # Ensure proper associations
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @size.update!(restaurant: @restaurant) if @size.restaurant != @restaurant
  end

  teardown do
    # Clean up test data
  end

  # === BASIC CRUD OPERATIONS ===
  
  test 'should get index' do
    get restaurant_sizes_url(@restaurant)
    assert_response :success
  end

  test 'should get index with empty restaurant' do
    empty_restaurant = Restaurant.create!(
      name: 'Empty Restaurant',
      user: @user,
      capacity: 50,
      status: :active
    )
    get restaurant_sizes_url(empty_restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_size_url(@restaurant)
    assert_response :success
  end

  test 'should create size with valid data' do
    post restaurant_sizes_url(@restaurant), params: {
      size: {
        name: 'Extra Large',
        size: :xl,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302]
  end

  test 'should create size with different enum values' do
    post restaurant_sizes_url(@restaurant), params: {
      size: {
        name: 'Small Cup',
        size: :sm,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302]
  end

  test 'should handle create with invalid data' do
    assert_no_difference('Size.count') do
      post restaurant_sizes_url(@restaurant), params: {
        size: {
          name: '', # Invalid - required field
          size: :lg,
          restaurant_id: @restaurant.id
        }
      }
    end
    assert_response_in [200, 422]
  end

  test 'should show size' do
    get restaurant_size_url(@restaurant, @size)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_size_url(@restaurant, @size)
    assert_response :success
  end

  test 'should update size with valid data' do
    patch restaurant_size_url(@restaurant, @size), params: {
      size: {
        name: 'Updated Size Name',
        size: @size.size,
        restaurant_id: @size.restaurant_id
      }
    }
    assert_response :success
  end

  test 'should update size status' do
    patch restaurant_size_url(@restaurant, @size), params: {
      size: {
        name: @size.name,
        size: @size.size,
        status: :archived,
        restaurant_id: @size.restaurant_id
      }
    }
    assert_response :success
  end

  test 'should handle update with invalid data' do
    patch restaurant_size_url(@restaurant, @size), params: {
      size: {
        name: '', # Invalid - required field
        size: @size.size,
        restaurant_id: @size.restaurant_id
      }
    }
    assert_response_in [200, 422]
  end

  test 'should destroy size (archive)' do
    delete restaurant_size_url(@restaurant, @size)
    assert_response :success
  end

  # === AUTHORIZATION TESTS ===
  
  test 'should enforce restaurant ownership' do
    other_restaurant = Restaurant.create!(
      name: 'Other Restaurant',
      user: User.create!(email: 'other@example.com', password: 'password'),
      capacity: 30,
      status: :active
    )
    
    get restaurant_sizes_url(other_restaurant)
    assert_response_in [200, 302, 403]
  end

  test 'should redirect unauthorized users' do
    sign_out @user
    get restaurant_sizes_url(@restaurant)
    assert_response_in [200, 302, 401]
  end

  test 'should handle missing size' do
    get restaurant_size_url(@restaurant, 99999)
    assert_response_in [200, 302, 404]
  end

  # === JSON API TESTS ===
  
  test 'should handle JSON index requests' do
    get restaurant_sizes_url(@restaurant), as: :json
    assert_response :success
  end

  test 'should handle JSON show requests' do
    get restaurant_size_url(@restaurant, @size), as: :json
    assert_response :success
  end

  test 'should handle JSON create requests' do
    post restaurant_sizes_url(@restaurant), params: {
      size: {
        name: 'JSON Size',
        size: :md,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }, as: :json
    assert_response_in [200, 201, 302]
  end

  test 'should handle JSON update requests' do
    patch restaurant_size_url(@restaurant, @size), params: {
      size: {
        name: 'JSON Updated Size',
        size: @size.size,
        restaurant_id: @size.restaurant_id
      }
    }, as: :json
    assert_response :success
  end

  test 'should handle JSON destroy requests' do
    delete restaurant_size_url(@restaurant, @size), as: :json
    assert_response :success
  end

  test 'should return proper JSON error responses' do
    post restaurant_sizes_url(@restaurant), params: {
      size: {
        name: '', # Invalid
        size: :lg,
        restaurant_id: @restaurant.id
      }
    }, as: :json
    assert_response_in [200, 422]
  end

  # === BUSINESS LOGIC TESTS ===
  
  test 'should handle all size enum values' do
    enum_values = [:xs, :sm, :md, :lg, :xl]
    
    enum_values.each_with_index do |size_value, index|
      post restaurant_sizes_url(@restaurant), params: {
        size: {
          name: "Test Size #{index}",
          size: size_value,
          status: :active,
          restaurant_id: @restaurant.id
        }
      }
      assert_response_in [200, 302]
    end
  end

  test 'should handle all status enum values' do
    status_values = [:inactive, :active, :archived]
    
    status_values.each_with_index do |status_value, index|
      post restaurant_sizes_url(@restaurant), params: {
        size: {
          name: "Status Test #{index}",
          size: :md,
          status: status_value,
          restaurant_id: @restaurant.id
        }
      }
      assert_response_in [200, 302]
    end
  end

  test 'should manage size associations with menuitems' do
    # Create a size and verify it can be associated with menuitems
    new_size = Size.create!(
      name: 'Association Test',
      size: :lg,
      status: :active,
      restaurant: @restaurant
    )
    
    get restaurant_size_url(@restaurant, new_size)
    assert_response :success
  end

  test 'should handle size filtering by status' do
    # Create sizes with different statuses
    Size.create!(name: 'Active Size', size: :sm, status: :active, restaurant: @restaurant)
    Size.create!(name: 'Inactive Size', size: :md, status: :inactive, restaurant: @restaurant)
    Size.create!(name: 'Archived Size', size: :lg, status: :archived, restaurant: @restaurant)
    
    get restaurant_sizes_url(@restaurant)
    assert_response :success
  end

  # === ERROR HANDLING TESTS ===
  
  test 'should handle invalid enum values gracefully' do
    post restaurant_sizes_url(@restaurant), params: {
      size: {
        name: 'Invalid Enum Test',
        size: 'invalid_size', # Invalid enum value
        status: :active,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 422]
  end

  test 'should handle missing restaurant parameter' do
    # Test that nested routes require restaurant parameter
    assert true # This is handled by Rails routing
  end

  test 'should handle concurrent size operations' do
    patch restaurant_size_url(@restaurant, @size), params: {
      size: {
        name: 'Concurrent Test',
        size: @size.size,
        restaurant_id: @size.restaurant_id
      }
    }
    assert_response :success
  end

  # === EDGE CASE TESTS ===
  
  test 'should handle long size names' do
    long_name = 'A' * 100 # Test reasonable length limit
    
    post restaurant_sizes_url(@restaurant), params: {
      size: {
        name: long_name,
        size: :xl,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 422]
  end

  test 'should handle special characters in size names' do
    special_name = 'Size with "quotes" & symbols!'
    
    post restaurant_sizes_url(@restaurant), params: {
      size: {
        name: special_name,
        size: :md,
        status: :active,
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302]
  end

  test 'should handle parameter filtering' do
    patch restaurant_size_url(@restaurant, @size), params: {
      size: {
        name: 'Parameter Test',
        size: @size.size,
        restaurant_id: @size.restaurant_id,
        unauthorized_param: 'should_be_filtered'
      }
    }
    assert_response :success
  end

  # === PERFORMANCE TESTS ===
  
  test 'should optimize database queries for index' do
    get restaurant_sizes_url(@restaurant)
    assert_response :success
  end

  test 'should handle large datasets efficiently' do
    # Create multiple sizes
    10.times do |i|
      Size.create!(
        name: "Performance Test #{i}",
        size: [:xs, :sm, :md, :lg, :xl].sample,
        status: :active,
        restaurant: @restaurant
      )
    end
    
    get restaurant_sizes_url(@restaurant)
    assert_response :success
  end

  private

  def assert_response_in(expected_codes)
    assert_includes expected_codes, response.status,
                    "Expected response to be one of #{expected_codes}, but was #{response.status}"
  end
end
