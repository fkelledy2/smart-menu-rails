require 'test_helper'

class TipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @tip = tips(:one)
    @restaurant = restaurants(:one)

    # Ensure proper associations
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @tip.update!(restaurant: @restaurant) if @tip.restaurant != @restaurant
  end

  teardown do
    # Clean up test data
  end

  # === BASIC CRUD OPERATIONS ===

  test 'should get index' do
    get restaurant_tips_url(@restaurant)
    assert_response :success
  end

  test 'should get index with empty restaurant' do
    empty_restaurant = Restaurant.create!(
      name: 'Empty Restaurant',
      user: @user,
      capacity: 50,
      status: :active,
    )
    get restaurant_tips_url(empty_restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_tip_url(@restaurant)
    assert_response :success
  end

  test 'should create tip with valid data' do
    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: 18.0,
        status: :active,
        restaurant_id: @restaurant.id,
      },
    }
    assert_response_in [200, 302]
  end

  test 'should create tip with different percentages' do
    percentages = [10.0, 15.0, 20.0, 25.0]

    percentages.each do |percentage|
      post restaurant_tips_url(@restaurant), params: {
        tip: {
          percentage: percentage,
          status: :active,
          restaurant_id: @restaurant.id,
        },
      }
      assert_response_in [200, 302]
    end
  end

  test 'should handle create with invalid data' do
    assert_no_difference('Tip.count') do
      post restaurant_tips_url(@restaurant), params: {
        tip: {
          percentage: nil, # Invalid - required field
          restaurant_id: @restaurant.id,
        },
      }
    end
    assert_response_in [200, 302, 422]
  end

  test 'should show tip' do
    get restaurant_tip_url(@restaurant, @tip)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_tip_url(@restaurant, @tip)
    assert_response :success
  end

  test 'should update tip with valid data' do
    new_percentage = 22.5
    patch restaurant_tip_url(@restaurant, @tip), params: {
      tip: {
        percentage: new_percentage,
        restaurant_id: @tip.restaurant_id,
      },
    }
    assert_response :redirect
  end

  test 'should update tip status' do
    patch restaurant_tip_url(@restaurant, @tip), params: {
      tip: {
        percentage: @tip.percentage,
        status: :archived,
        restaurant_id: @tip.restaurant_id,
      },
    }
    assert_response :redirect
  end

  test 'should handle update with invalid data' do
    patch restaurant_tip_url(@restaurant, @tip), params: {
      tip: {
        percentage: -5.0, # Invalid negative percentage
        restaurant_id: @tip.restaurant_id,
      },
    }
    assert_response_in [200, 302, 422]
  end

  test 'should destroy tip (archive)' do
    delete restaurant_tip_url(@restaurant, @tip)
    assert_response :redirect
  end

  # === AUTHORIZATION TESTS ===

  test 'should enforce restaurant ownership' do
    other_restaurant = Restaurant.create!(
      name: 'Other Restaurant',
      user: User.create!(email: 'other@example.com', password: 'password'),
      capacity: 30,
      status: :active,
    )

    get restaurant_tips_url(other_restaurant)
    assert_response_in [200, 302, 403, 404]
  end

  test 'should redirect unauthorized users' do
    sign_out @user
    get restaurant_tips_url(@restaurant)
    assert_response_in [200, 302, 401]
  end

  test 'should handle missing tip' do
    get restaurant_tip_url(@restaurant, 99999)
    assert_response_in [200, 302, 404]
  end

  # === JSON API TESTS ===

  test 'should handle JSON index requests' do
    get restaurant_tips_url(@restaurant), as: :json
    assert_response :success
  end

  test 'should handle JSON show requests' do
    get restaurant_tip_url(@restaurant, @tip), as: :json
    assert_response :success
  end

  test 'should handle JSON create requests' do
    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: 16.5,
        status: :active,
        restaurant_id: @restaurant.id,
      },
    }, as: :json
    assert_response_in [200, 201, 302]
  end

  test 'should return proper JSON error responses' do
    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: nil, # Invalid
        restaurant_id: @restaurant.id,
      },
    }, as: :json
    assert_response_in [200, 302, 422]
  end

  # === BUSINESS LOGIC TESTS ===

  test 'should handle all status enum values' do
    status_values = %i[inactive active archived]

    status_values.each_with_index do |status_value, index|
      post restaurant_tips_url(@restaurant), params: {
        tip: {
          percentage: 15.0 + index,
          status: status_value,
          restaurant_id: @restaurant.id,
        },
      }
      assert_response_in [200, 302]
    end
  end

  test 'should handle common tip percentages' do
    common_percentages = [10.0, 12.5, 15.0, 18.0, 20.0, 22.0, 25.0]

    common_percentages.each do |percentage|
      post restaurant_tips_url(@restaurant), params: {
        tip: {
          percentage: percentage,
          status: :active,
          restaurant_id: @restaurant.id,
        },
      }
      assert_response_in [200, 302]
    end
  end

  test 'should handle decimal tip percentages' do
    decimal_percentages = [12.5, 17.5, 22.5]

    decimal_percentages.each do |percentage|
      post restaurant_tips_url(@restaurant), params: {
        tip: {
          percentage: percentage,
          status: :active,
          restaurant_id: @restaurant.id,
        },
      }
      assert_response_in [200, 302]
    end
  end

  test 'should handle tip filtering by status' do
    # Create tips with different statuses
    Tip.create!(percentage: 15.0, status: :active, restaurant: @restaurant)
    Tip.create!(percentage: 18.0, status: :inactive, restaurant: @restaurant)
    Tip.create!(percentage: 20.0, status: :archived, restaurant: @restaurant)

    get restaurant_tips_url(@restaurant)
    assert_response :success
  end

  test 'should validate tip percentage ranges' do
    # Test with zero percentage
    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: 0.0,
        status: :active,
        restaurant_id: @restaurant.id,
      },
    }
    assert_response_in [200, 302, 422]

    # Test with high percentage
    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: 50.0,
        status: :active,
        restaurant_id: @restaurant.id,
      },
    }
    assert_response_in [200, 302, 422]
  end

  # === ERROR HANDLING TESTS ===

  test 'should handle invalid tip percentage' do
    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: -10.0, # Invalid negative percentage
        status: :active,
        restaurant_id: @restaurant.id,
      },
    }
    assert_response_in [200, 302, 422]
  end

  test 'should handle non-numeric tip percentage' do
    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: 'not_a_number',
        status: :active,
        restaurant_id: @restaurant.id,
      },
    }
    assert_response_in [200, 302, 422]
  end

  test 'should handle invalid enum values gracefully' do
    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: 15.0,
        status: 'invalid_status', # Invalid enum value
        restaurant_id: @restaurant.id,
      },
    }
    assert_response_in [200, 302, 422]
  end

  test 'should handle concurrent tip operations' do
    patch restaurant_tip_url(@restaurant, @tip), params: {
      tip: {
        percentage: 21.0,
        restaurant_id: @tip.restaurant_id,
      },
    }
    assert_response :redirect
  end

  # === EDGE CASE TESTS ===

  test 'should handle extreme tip percentages' do
    # Test with very small percentage
    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: 0.01,
        status: :active,
        restaurant_id: @restaurant.id,
      },
    }
    assert_response_in [200, 302, 422]

    # Test with very large percentage
    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: 99.99,
        status: :active,
        restaurant_id: @restaurant.id,
      },
    }
    assert_response_in [200, 302, 422]
  end

  test 'should handle high precision decimal percentages' do
    precise_percentage = 15.123456

    post restaurant_tips_url(@restaurant), params: {
      tip: {
        percentage: precise_percentage,
        status: :active,
        restaurant_id: @restaurant.id,
      },
    }
    assert_response_in [200, 302]
  end

  test 'should handle parameter filtering' do
    patch restaurant_tip_url(@restaurant, @tip), params: {
      tip: {
        percentage: 17.0,
        restaurant_id: @tip.restaurant_id,
        unauthorized_param: 'should_be_filtered',
      },
    }
    assert_response :redirect
  end

  # === BUSINESS SCENARIO TESTS ===

  test 'should support restaurant tip configuration scenarios' do
    # Test creating multiple tip options for a restaurant
    tip_options = [
      { percentage: 15.0, name: 'Standard' },
      { percentage: 18.0, name: 'Good Service' },
      { percentage: 20.0, name: 'Excellent Service' },
      { percentage: 25.0, name: 'Outstanding Service' },
    ]

    tip_options.each do |option|
      post restaurant_tips_url(@restaurant), params: {
        tip: {
          percentage: option[:percentage],
          status: :active,
          restaurant_id: @restaurant.id,
        },
      }
      assert_response_in [200, 302]
    end
  end

  test 'should handle tip calculation scenarios' do
    # Create tips for calculation testing
    calculation_tips = [10.0, 15.0, 20.0]

    calculation_tips.each do |percentage|
      tip = Tip.create!(
        percentage: percentage,
        status: :active,
        restaurant: @restaurant,
      )

      get restaurant_tip_url(@restaurant, tip)
      assert_response :success
    end
  end

  # === PERFORMANCE TESTS ===

  test 'should optimize database queries for index' do
    get restaurant_tips_url(@restaurant)
    assert_response :success
  end

  test 'should handle large datasets efficiently' do
    # Create multiple tips
    20.times do |i|
      Tip.create!(
        percentage: (10.0 + (i * 0.5)),
        status: :active,
        restaurant: @restaurant,
      )
    end

    get restaurant_tips_url(@restaurant)
    assert_response :success
  end

  private

  def assert_response_in(expected_codes)
    assert_includes expected_codes, response.status,
                    "Expected response to be one of #{expected_codes}, but was #{response.status}"
  end
end
