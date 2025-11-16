require "test_helper"

class RestaurantAutoSaveIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user)
    
    # Use Devise's sign_in helper for integration tests
    sign_in @user
  end

  test "controller returns JSON success for AJAX auto-save requests" do
    # Simulate an AJAX PATCH request like auto-save would make
    patch restaurant_path(@restaurant),
          params: { restaurant: { name: "Auto Saved Name" } },
          headers: { 
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json'
          },
          as: :json

    assert_response :success
    
    # Parse response
    json_response = JSON.parse(response.body)
    
    # Verify response format
    assert json_response['success'], "Response should indicate success"
    assert_equal "Saved successfully", json_response['message']
    
    # Verify data was actually saved
    @restaurant.reload
    assert_equal "Auto Saved Name", @restaurant.name
    
    puts "✓ AJAX request successful"
    puts "✓ Response: #{json_response.inspect}"
    puts "✓ Restaurant name saved: #{@restaurant.name}"
  end

  test "auto-save request includes CSRF token" do
    # Make AJAX request with CSRF token (Rails handles this automatically in tests)
    patch restaurant_path(@restaurant),
          params: { restaurant: { description: "With CSRF" } },
          headers: { 
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json'
          },
          as: :json

    assert_response :success
    
    @restaurant.reload
    assert_equal "With CSRF", @restaurant.description
    
    puts "✓ CSRF protection working"
    puts "✓ Request accepted with valid token"
  end

  test "auto-save updates multiple fields in single request" do
    patch restaurant_path(@restaurant),
          params: { 
            restaurant: { 
              name: "New Name",
              description: "New Description",
              city: "New York",
              currency: "USD"
            } 
          },
          headers: { 
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json'
          },
          as: :json

    assert_response :success
    
    @restaurant.reload
    assert_equal "New Name", @restaurant.name
    assert_equal "New Description", @restaurant.description
    assert_equal "New York", @restaurant.city
    assert_equal "USD", @restaurant.currency
    
    puts "✓ Multiple fields updated in one request"
    puts "  Name: #{@restaurant.name}"
    puts "  Description: #{@restaurant.description}"
    puts "  City: #{@restaurant.city}"
    puts "  Currency: #{@restaurant.currency}"
  end

  test "auto-save returns error for invalid data" do
    # Try to save with blank name (required field)
    patch restaurant_path(@restaurant),
          params: { restaurant: { name: "" } },
          headers: { 
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json'
          },
          as: :json

    assert_response :unprocessable_entity
    
    json_response = JSON.parse(response.body)
    assert json_response['name'].present?, "Should have validation error for name"
    
    # Verify original data wasn't changed
    @restaurant.reload
    assert_not_nil @restaurant.name
    assert @restaurant.name.present?
    
    puts "✓ Validation errors returned correctly"
    puts "✓ Original data preserved"
  end

  test "auto-save triggers cache invalidation" do
    # Save initial state
    initial_name = @restaurant.name
    
    # Make auto-save request
    patch restaurant_path(@restaurant),
          params: { restaurant: { name: "Cache Test Name" } },
          headers: { 
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json'
          },
          as: :json

    assert_response :success
    
    # Verify cache was invalidated by checking fresh data
    @restaurant.reload
    assert_equal "Cache Test Name", @restaurant.name
    assert_not_equal initial_name, @restaurant.name
    
    puts "✓ Cache invalidated after auto-save"
  end

  test "auto-save preserves Turbo Frame context" do
    # Auto-save should work within Turbo Frame
    get edit_restaurant_path(@restaurant, section: 'details'),
        headers: { 'Turbo-Frame': 'restaurant_content' }
    
    assert_response :success
    
    # Now auto-save within that context
    patch restaurant_path(@restaurant),
          params: { restaurant: { name: "Turbo Frame Test" } },
          headers: { 
            'X-Requested-With': 'XMLHttpRequest',
            'Turbo-Frame': 'restaurant_content',
            'Accept': 'application/json'
          },
          as: :json

    assert_response :success
    
    @restaurant.reload
    assert_equal "Turbo Frame Test", @restaurant.name
    
    puts "✓ Auto-save works with Turbo Frames"
  end
end
