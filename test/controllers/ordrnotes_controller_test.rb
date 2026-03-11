require 'test_helper'

class OrdrnotesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user) # Ensure user owns restaurant
    
    # Ensure employee belongs to the restaurant and user
    @employee = employees(:one)
    @employee.update!(user: @user, restaurant: @restaurant)
    
    # Reload to ensure associations are fresh
    @employee.reload
    @restaurant.reload
    
    @ordr = ordrs(:one)
    @ordr.update!(restaurant: @restaurant)

    @ordrnote = @ordr.ordrnotes.create!(
      employee: @employee,
      content: 'Customer has severe nut allergy',
      category: 'dietary',
      priority: 'urgent',
    )

    sign_in @user
    
    # Verify the employee-user-restaurant relationship is correct
    assert_equal @user, @employee.user
    assert_equal @restaurant, @employee.restaurant
    assert_not_nil @restaurant.employees.find_by(user: @user), "Employee not found for user in restaurant"
  end

  test 'should get index' do
    get restaurant_ordr_ordrnotes_url(@restaurant, @ordr)
    assert_response :success
  end

  test 'should get index as json' do
    get restaurant_ordr_ordrnotes_url(@restaurant, @ordr, format: :json)
    assert_response :success
    json_response = response.parsed_body
    assert json_response.is_a?(Array)
  end

  test 'should show ordrnote' do
    get restaurant_ordr_ordrnote_url(@restaurant, @ordr, @ordrnote)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_ordr_ordrnote_url(@restaurant, @ordr)
    assert_response :success
  end

  test 'should create ordrnote' do
    assert_difference('Ordrnote.count') do
      post restaurant_ordr_ordrnotes_url(@restaurant, @ordr), params: {
        ordrnote: {
          content: 'Rush order - needed ASAP',
          category: 'timing',
          priority: 'high',
          visible_to_kitchen: true,
          visible_to_servers: true,
          visible_to_customers: false,
        },
      }
    end

    assert_redirected_to restaurant_ordr_url(@restaurant, @ordr)
    assert_equal 'Order note added successfully.', flash[:notice]
  end

  test 'should create ordrnote as json' do
    assert_difference('Ordrnote.count') do
      post restaurant_ordr_ordrnotes_url(@restaurant, @ordr, format: :json), params: {
        ordrnote: {
          content: 'Birthday celebration',
          category: 'customer_service',
          priority: 'medium',
        },
      }
    end

    assert_response :created
    json_response = response.parsed_body
    assert_equal 'Birthday celebration', json_response['content']
  end

  test 'should not create ordrnote with invalid params' do
    assert_no_difference('Ordrnote.count') do
      post restaurant_ordr_ordrnotes_url(@restaurant, @ordr), params: {
        ordrnote: {
          content: 'ab', # too short
          category: 'dietary',
          priority: 'high',
        },
      }
    end

    assert_response :unprocessable_entity
  end

  test 'should get edit' do
    get edit_restaurant_ordr_ordrnote_url(@restaurant, @ordr, @ordrnote)
    assert_response :success
  end

  test 'should update ordrnote within time window' do
    @ordrnote.update_column(:created_at, 5.minutes.ago)

    patch restaurant_ordr_ordrnote_url(@restaurant, @ordr, @ordrnote), params: {
      ordrnote: {
        content: 'Updated: Customer has severe nut allergy - NO NUTS',
      },
    }

    assert_redirected_to restaurant_ordr_url(@restaurant, @ordr)
    @ordrnote.reload
    assert_equal 'Updated: Customer has severe nut allergy - NO NUTS', @ordrnote.content
  end

  test 'should update ordrnote as json' do
    @ordrnote.update_column(:created_at, 5.minutes.ago)

    patch restaurant_ordr_ordrnote_url(@restaurant, @ordr, @ordrnote, format: :json), params: {
      ordrnote: {
        priority: 'high',
      },
    }

    assert_response :success
    @ordrnote.reload
    assert_equal 'high', @ordrnote.priority
  end

  test 'should not update ordrnote with invalid params' do
    @ordrnote.update_column(:created_at, 5.minutes.ago)

    patch restaurant_ordr_ordrnote_url(@restaurant, @ordr, @ordrnote), params: {
      ordrnote: {
        content: 'ab', # too short
      },
    }

    assert_response :unprocessable_entity
  end

  test 'should destroy ordrnote within time window' do
    @ordrnote.update_column(:created_at, 5.minutes.ago)

    assert_difference('Ordrnote.count', -1) do
      delete restaurant_ordr_ordrnote_url(@restaurant, @ordr, @ordrnote)
    end

    assert_redirected_to restaurant_ordr_url(@restaurant, @ordr)
    assert_equal 'Order note removed successfully.', flash[:notice]
  end

  test 'should destroy ordrnote as json' do
    @ordrnote.update_column(:created_at, 5.minutes.ago)

    assert_difference('Ordrnote.count', -1) do
      delete restaurant_ordr_ordrnote_url(@restaurant, @ordr, @ordrnote, format: :json)
    end

    assert_response :no_content
  end

  test 'should set employee from current user' do
    post restaurant_ordr_ordrnotes_url(@restaurant, @ordr), params: {
      ordrnote: {
        content: 'Test note',
        category: 'operational',
        priority: 'low',
      },
    }

    created_note = Ordrnote.last
    assert_equal @employee, created_note.employee
  end

  test 'should enforce authorization' do
    sign_out @user

    get restaurant_ordr_ordrnotes_url(@restaurant, @ordr)
    assert_redirected_to new_user_session_url
  end
end
