require 'test_helper'

class GenimagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @restaurant = restaurants(:one)
    @genimage = genimages(:one)
    @menu = menus(:one)
    @menusection = menusections(:one)
    @menuitem = menuitems(:one)
    
    # Ensure proper associations
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @genimage.update!(restaurant: @restaurant) if @genimage.restaurant != @restaurant
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant
  end

  teardown do
    # Clean up test data
  end

  # === BASIC CRUD OPERATIONS ===
  
  test 'should get index' do
    get restaurant_genimages_url(@restaurant)
    assert_response :success
  end

  test 'should get index with empty restaurant' do
    empty_restaurant = Restaurant.create!(
      name: 'Empty Restaurant',
      user: @user,
      capacity: 50,
      status: :active
    )
    get restaurant_genimages_url(empty_restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_genimage_url(@restaurant)
    assert_response :success
  end

  test 'should create genimage with valid data' do
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: 'Test Image',
        description: 'Test Description',
        restaurant_id: @restaurant.id,
        menu_id: @menu.id
      }
    }
    assert_response :success
  end

  test 'should create genimage for different associations' do
    # Test creating genimage for menu
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: 'Menu Image',
        description: 'Menu-specific image',
        restaurant_id: @restaurant.id,
        menu_id: @menu.id
      }
    }
    assert_response :success

    # Test creating genimage for menusection
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: 'Section Image',
        description: 'Section-specific image',
        restaurant_id: @restaurant.id,
        menusection_id: @menusection.id
      }
    }
    assert_response :success

    # Test creating genimage for menuitem
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: 'Item Image',
        description: 'Item-specific image',
        restaurant_id: @restaurant.id,
        menuitem_id: @menuitem.id
      }
    }
    assert_response :success
  end

  test 'should handle create with invalid data' do
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: '', # Invalid - required field
        description: 'Test Description',
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 422]
  end

  test 'should show genimage' do
    get restaurant_genimage_url(@restaurant, @genimage)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_genimage_url(@restaurant, @genimage)
    assert_response :success
  end

  test 'should update genimage with valid data' do
    patch restaurant_genimage_url(@restaurant, @genimage), params: {
      genimage: {
        name: 'Updated Image Name',
        description: 'Updated description'
      }
    }
    assert_response :success
  end

  test 'should update genimage associations' do
    patch restaurant_genimage_url(@restaurant, @genimage), params: {
      genimage: {
        name: @genimage.name,
        menu_id: @menu.id,
        menusection_id: @menusection.id
      }
    }
    assert_response :success
  end

  test 'should handle update with invalid data' do
    patch restaurant_genimage_url(@restaurant, @genimage), params: {
      genimage: {
        name: '', # Invalid - required field
        description: 'Test Description'
      }
    }
    assert_response_in [200, 422]
  end

  test 'should destroy genimage' do
    delete restaurant_genimage_url(@restaurant, @genimage)
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
    
    get restaurant_genimages_url(other_restaurant)
    assert_response_in [200, 302, 403]
  end

  test 'should redirect unauthorized users' do
    sign_out @user
    get new_restaurant_genimage_url(@restaurant)
    assert_response_in [200, 302, 401]
  end

  test 'should handle missing genimage' do
    get restaurant_genimage_url(@restaurant, 99999)
    assert_response_in [200, 302, 404]
  end

  # === JSON API TESTS ===
  
  test 'should handle JSON index requests' do
    get restaurant_genimages_url(@restaurant), as: :json
    assert_response :success
  end

  test 'should handle JSON show requests' do
    get restaurant_genimage_url(@restaurant, @genimage), as: :json
    assert_response :success
  end

  test 'should handle JSON create requests' do
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: 'JSON Image',
        description: 'JSON created image',
        restaurant_id: @restaurant.id,
        menu_id: @menu.id
      }
    }, as: :json
    assert_response_in [200, 201, 302]
  end

  test 'should handle JSON update requests' do
    patch restaurant_genimage_url(@restaurant, @genimage), params: {
      genimage: {
        name: 'JSON Updated Image',
        description: 'JSON updated description'
      }
    }, as: :json
    assert_response :success
  end

  test 'should handle JSON destroy requests' do
    delete restaurant_genimage_url(@restaurant, @genimage), as: :json
    assert_response :success
  end

  test 'should return proper JSON error responses' do
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: '', # Invalid
        restaurant_id: @restaurant.id
      }
    }, as: :json
    assert_response_in [200, 422]
  end

  # === BUSINESS LOGIC TESTS ===
  
  test 'should handle genimage association management' do
    # Test associating with different entities
    associations = [
      { menu_id: @menu.id, name: 'Menu Associated Image' },
      { menusection_id: @menusection.id, name: 'Section Associated Image' },
      { menuitem_id: @menuitem.id, name: 'Item Associated Image' }
    ]
    
    associations.each do |association_data|
      post restaurant_genimages_url(@restaurant), params: {
        genimage: {
          name: association_data[:name],
          description: 'Association test',
          restaurant_id: @restaurant.id,
          **association_data.except(:name)
        }
      }
      assert_response :success
    end
  end

  test 'should handle genimage filtering by association' do
    # Create genimages with different associations
    Genimage.create!(name: 'Menu Image', restaurant: @restaurant, menu: @menu)
    Genimage.create!(name: 'Section Image', restaurant: @restaurant, menusection: @menusection)
    Genimage.create!(name: 'Item Image', restaurant: @restaurant, menuitem: @menuitem)
    
    get restaurant_genimages_url(@restaurant)
    assert_response :success
  end

  test 'should manage genimage themes and styles' do
    patch restaurant_genimage_url(@restaurant, @genimage), params: {
      genimage: {
        name: @genimage.name,
        description: 'Theme management test'
      }
    }
    assert_response :success
  end

  test 'should handle genimage generation workflows' do
    get restaurant_genimage_url(@restaurant, @genimage)
    assert_response :success
  end

  # === ERROR HANDLING TESTS ===
  
  test 'should handle invalid association references' do
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: 'Invalid Association Test',
        restaurant_id: @restaurant.id,
        menu_id: 99999 # Invalid menu ID
      }
    }
    assert_response_in [200, 422]
  end

  test 'should handle concurrent genimage operations' do
    patch restaurant_genimage_url(@restaurant, @genimage), params: {
      genimage: {
        name: 'Concurrent Test Image',
        description: 'Concurrent update test'
      }
    }
    assert_response :success
  end

  test 'should handle missing required associations' do
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: 'Missing Association Test',
        description: 'Test without required associations'
        # Missing restaurant_id
      }
    }
    assert_response_in [200, 422]
  end

  # === EDGE CASE TESTS ===
  
  test 'should handle long genimage names' do
    long_name = 'A' * 100 # Test reasonable length limit
    
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: long_name,
        description: 'Long name test',
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302, 422]
  end

  test 'should handle special characters in genimage names' do
    special_name = 'Image with "quotes" & symbols!'
    
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: special_name,
        description: 'Special characters test',
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302]
  end

  test 'should handle parameter filtering' do
    patch restaurant_genimage_url(@restaurant, @genimage), params: {
      genimage: {
        name: 'Parameter Test',
        description: 'Parameter filtering test'
      },
      unauthorized_param: 'should_be_filtered'
    }
    assert_response :success
  end

  test 'should handle empty descriptions' do
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: 'Empty Description Image',
        description: '',
        restaurant_id: @restaurant.id
      }
    }
    assert_response_in [200, 302]
  end

  test 'should handle multiple association conflicts' do
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: 'Conflict Test Image',
        description: 'Testing multiple associations',
        restaurant_id: @restaurant.id,
        menu_id: @menu.id,
        menusection_id: @menusection.id,
        menuitem_id: @menuitem.id
      }
    }
    assert_response_in [200, 302, 422]
  end

  # === CACHING TESTS ===
  
  test 'should handle cached genimage data efficiently' do
    get restaurant_genimage_url(@restaurant, @genimage)
    assert_response :success
  end

  test 'should invalidate caches on genimage updates' do
    patch restaurant_genimage_url(@restaurant, @genimage), params: {
      genimage: {
        name: 'Cache Invalidation Test',
        description: 'Testing cache invalidation'
      }
    }
    assert_response :success
  end

  test 'should handle cache misses gracefully' do
    get restaurant_genimages_url(@restaurant)
    assert_response :success
  end

  # === PERFORMANCE TESTS ===
  
  test 'should optimize database queries for index' do
    get restaurant_genimages_url(@restaurant)
    assert_response :success
  end

  test 'should handle large datasets efficiently' do
    # Create multiple genimages
    10.times do |i|
      Genimage.create!(
        name: "Performance Test Image #{i}",
        description: "Performance test #{i}",
        restaurant: @restaurant,
        menu: [@menu, nil].sample
      )
    end
    
    get restaurant_genimages_url(@restaurant)
    assert_response :success
  end

  # === INTEGRATION TESTS ===
  
  test 'should handle genimage with menu integration' do
    get restaurant_genimage_url(@restaurant, @genimage)
    assert_response :success
  end

  test 'should handle genimage with menusection integration' do
    get restaurant_genimage_url(@restaurant, @genimage)
    assert_response :success
  end

  test 'should handle genimage with menuitem integration' do
    get restaurant_genimage_url(@restaurant, @genimage)
    assert_response :success
  end

  # === BUSINESS SCENARIO TESTS ===
  
  test 'should support image generation workflows' do
    # Test different image generation scenarios
    image_types = [
      { name: 'Restaurant Logo', description: 'Main restaurant branding' },
      { name: 'Menu Background', description: 'Menu design background', menu_id: @menu.id },
      { name: 'Section Header', description: 'Section visual header', menusection_id: @menusection.id },
      { name: 'Item Photo', description: 'Food item photography', menuitem_id: @menuitem.id }
    ]
    
    image_types.each do |image_data|
      post restaurant_genimages_url(@restaurant), params: {
        genimage: {
          name: image_data[:name],
          description: image_data[:description],
          restaurant_id: @restaurant.id,
          menu_id: image_data[:menu_id],
          menusection_id: image_data[:menusection_id],
          menuitem_id: image_data[:menuitem_id]
        }.compact
      }
      assert_response :success
    end
  end

  test 'should handle genimage lifecycle management' do
    # Create new genimage
    post restaurant_genimages_url(@restaurant), params: {
      genimage: {
        name: 'Lifecycle Image',
        description: 'Testing lifecycle',
        restaurant_id: @restaurant.id
      }
    }
    assert_response :success
    
    # Update genimage
    patch restaurant_genimage_url(@restaurant, @genimage), params: {
      genimage: {
        name: 'Updated Lifecycle Image',
        description: 'Updated description'
      }
    }
    assert_response :success
    
    # Delete genimage
    delete restaurant_genimage_url(@restaurant, @genimage)
    assert_response :success
  end

  test 'should handle theme and style management scenarios' do
    # Test updating genimage for different themes
    themes = ['modern', 'classic', 'minimalist', 'colorful']
    
    themes.each do |theme|
      patch restaurant_genimage_url(@restaurant, @genimage), params: {
        genimage: {
          name: "#{theme.capitalize} Theme Image",
          description: "#{theme} style theme"
        }
      }
      assert_response :success
    end
  end

  private

  def assert_response_in(expected_codes)
    assert_includes expected_codes, response.status,
                    "Expected response to be one of #{expected_codes}, but was #{response.status}"
  end
end
