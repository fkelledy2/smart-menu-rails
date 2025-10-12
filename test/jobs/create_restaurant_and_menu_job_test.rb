require 'test_helper'

class CreateRestaurantAndMenuJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    @plan = plans(:one)
    
    # Create onboarding session with complete data
    @onboarding = OnboardingSession.create!(
      user: @user,
      status: :menu_created,
      restaurant_name: 'Test Restaurant',
      restaurant_type: 'casual_dining',
      cuisine_type: 'italian',
      location: 'New York, NY',
      phone: '555-1234',
      menu_name: 'Test Menu',
      menu_items: [
        { 'name' => 'Pasta Carbonara', 'price' => '15.99', 'description' => 'Classic Italian pasta' },
        { 'name' => 'Margherita Pizza', 'price' => '12.99', 'description' => 'Traditional pizza' }
      ]
    )
  end

  teardown do
    # Clean up test data
  end

  # === BASIC JOB EXECUTION TESTS ===
  
  test 'should be configured with correct queue' do
    # Test that the job is configured with the default queue
    job = CreateRestaurantAndMenuJob.new
    assert_equal 'default', job.queue_name
  end

  test 'should perform job successfully with valid data' do
    initial_restaurant_count = Restaurant.count
    initial_menu_count = Menu.count
    
    assert_nothing_raised do
      CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    end
    
    assert_equal initial_restaurant_count + 1, Restaurant.count
    assert_equal initial_menu_count + 1, Menu.count
  end

  test 'should update onboarding session status to completed' do
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    @onboarding.reload
    assert_equal 'completed', @onboarding.status
    assert_not_nil @onboarding.restaurant
    assert_not_nil @onboarding.menu
  end

  test 'should handle missing user gracefully' do
    assert_raises ActiveRecord::RecordNotFound do
      CreateRestaurantAndMenuJob.perform_now(99999, @onboarding.id)
    end
  end

  test 'should handle missing onboarding session gracefully' do
    assert_raises ActiveRecord::RecordNotFound do
      CreateRestaurantAndMenuJob.perform_now(@user.id, 99999)
    end
  end

  # === RESTAURANT CREATION TESTS ===
  
  test 'should create restaurant with correct attributes' do
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    restaurant = Restaurant.last
    assert_equal 'Test Restaurant', restaurant.name
    assert_equal @user, restaurant.user
    assert_equal 'Casual dining restaurant serving Italian cuisine', restaurant.description
    assert_equal 'New York, NY', restaurant.address1
    assert_equal 'USD', restaurant.currency
    assert_equal 50, restaurant.capacity
    assert restaurant.allowOrdering
    assert_equal 'active', restaurant.status
    assert_not restaurant.archived
  end

  test 'should detect currency from location' do
    # Test different locations with separate onboarding sessions to avoid FK constraints
    locations_and_currencies = [
      ['London, UK', 'GBP'],
      ['Berlin, Germany', 'EUR'],
      ['Toronto, Canada', 'CAD'],
      ['Sydney, Australia', 'AUD'],
      ['Tokyo, Japan', 'USD'], # Default
      ['', 'USD'] # Empty location
    ]
    
    locations_and_currencies.each_with_index do |(location, expected_currency), index|
      # Create separate onboarding session for each test
      test_onboarding = OnboardingSession.create!(
        user: @user,
        status: :menu_created,
        restaurant_name: "Currency Test Restaurant #{index}",
        restaurant_type: 'casual_dining',
        cuisine_type: 'italian',
        location: location,
        menu_name: 'Currency Test Menu',
        menu_items: [
          { 'name' => 'Test Item', 'price' => '10.00', 'description' => 'Test description' }
        ]
      )
      
      CreateRestaurantAndMenuJob.perform_now(@user.id, test_onboarding.id)
      
      test_onboarding.reload
      restaurant = test_onboarding.restaurant
      assert_equal expected_currency, restaurant.currency, "Wrong currency for location: #{location}"
    end
  end

  test 'should create default restaurant settings' do
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    restaurant = Restaurant.last
    
    # Check table settings
    assert restaurant.tablesettings.exists?
    table = restaurant.tablesettings.first
    assert_equal 'Table 1', table.name
    assert_equal 4, table.capacity
    assert_equal 'indoor', table.tabletype
    assert_equal 'free', table.status
    
    # Check taxes
    assert restaurant.taxes.exists?
    tax = restaurant.taxes.first
    assert_equal 'Default Tax', tax.name
    assert_equal 'local', tax.taxtype
    assert_equal 10.0, tax.taxpercentage
    
    # Check tips
    assert restaurant.tips.exists?
    tip = restaurant.tips.first
    assert_equal 10.0, tip.percentage
    assert_equal 'active', tip.status
    
    # Check locales
    assert restaurant.restaurantlocales.exists?
    assert_equal 2, restaurant.restaurantlocales.count
    
    en_locale = restaurant.restaurantlocales.find_by(locale: 'EN')
    assert en_locale.dfault
    assert_equal 'active', en_locale.status
    
    it_locale = restaurant.restaurantlocales.find_by(locale: 'IT')
    assert_not it_locale.dfault
    assert_equal 'active', it_locale.status
    
    # Check availabilities (6 days, excluding Monday)
    assert restaurant.restaurantavailabilities.exists?
    assert_equal 6, restaurant.restaurantavailabilities.count
    
    availability = restaurant.restaurantavailabilities.first
    assert_equal 9, availability.starthour
    assert_equal 0, availability.startmin
    assert_equal 21, availability.endhour
    assert_equal 0, availability.endmin
    assert_equal 'open', availability.status
    
    # Check allergens
    assert restaurant.allergyns.exists?
    assert_equal 2, restaurant.allergyns.count
    
    allergen1 = restaurant.allergyns.find_by(name: 'Allergen 1')
    assert_equal 'A1', allergen1.symbol
    assert_equal 'active', allergen1.status
    
    # Check sizes
    assert restaurant.sizes.exists?
    assert_equal 3, restaurant.sizes.count
    
    small_size = restaurant.sizes.find_by(size: 'sm')
    assert_equal 'Small', small_size.name
    assert_equal 'active', small_size.status
  end

  test 'should create owner employee record' do
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    restaurant = Restaurant.last
    assert restaurant.employees.exists?
    
    owner_employee = restaurant.employees.first
    assert_equal @user, owner_employee.user
    assert_equal @user.name, owner_employee.name
    assert_equal @user.email, owner_employee.email
    assert_equal "OWNER#{restaurant.id}", owner_employee.eid
    assert_equal 'manager', owner_employee.role
    assert_equal 'active', owner_employee.status
    assert_not owner_employee.archived
  end

  # === MENU CREATION TESTS ===
  
  test 'should create menu with correct attributes' do
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    menu = Menu.last
    assert_equal 'Test Menu', menu.name
    assert_equal 'active', menu.status
    assert_not menu.archived
    assert menu.allowOrdering
  end

  test 'should create menu with default name when not provided' do
    @onboarding.update!(menu_name: nil)
    
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    menu = Menu.last
    assert_equal 'Demo Menu', menu.name
  end

  test 'should create menu section and items' do
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    menu = Menu.last
    
    # Check menu section
    assert menu.menusections.exists?
    section = menu.menusections.first
    assert_equal 'Demo Section', section.name
    assert_equal 'Demo menu items', section.description
    assert_equal 'active', section.status
    assert_equal 1, section.sequence
    
    # Check menu items
    assert_equal 2, section.menuitems.count
    
    pasta = section.menuitems.find_by(name: 'Pasta Carbonara')
    assert_equal 'Classic Italian pasta', pasta.description
    assert_equal 15.99, pasta.price
    assert_equal 750, pasta.calories
    assert_equal 10, pasta.preptime
    assert_equal 1, pasta.sequence
    assert_equal 'active', pasta.status
    
    pizza = section.menuitems.find_by(name: 'Margherita Pizza')
    assert_equal 'Traditional pizza', pizza.description
    assert_equal 12.99, pizza.price
    assert_equal 2, pizza.sequence
  end

  test 'should create allergen mappings for menu items' do
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    menu = Menu.last
    menu_items = menu.menusections.first.menuitems
    
    menu_items.each do |item|
      # Each item should have allergen mappings
      assert item.menuitem_allergyn_mappings.exists?
    end
  end

  test 'should create size mappings for first menu item only' do
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    menu = Menu.last
    menu_items = menu.menusections.first.menuitems.order(:sequence)
    
    first_item = menu_items.first
    second_item = menu_items.second
    
    # First item should have size mappings
    assert first_item.menuitem_size_mappings.exists?
    assert_equal 3, first_item.menuitem_size_mappings.count
    
    # Check pricing
    small_mapping = first_item.menuitem_size_mappings.joins(:size).find_by(sizes: { size: 'sm' })
    medium_mapping = first_item.menuitem_size_mappings.joins(:size).find_by(sizes: { size: 'md' })
    large_mapping = first_item.menuitem_size_mappings.joins(:size).find_by(sizes: { size: 'lg' })
    
    base_price = first_item.price
    assert_equal (base_price * 0.8).round(2), small_mapping.price.round(2)
    assert_equal base_price, medium_mapping.price
    assert_equal (base_price * 1.3).round(2), large_mapping.price.round(2)
    
    # Second item should not have size mappings
    assert_not second_item.menuitem_size_mappings.exists?
  end

  test 'should create inventory for each menu item' do
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    menu = Menu.last
    menu_items = menu.menusections.first.menuitems
    
    menu_items.each_with_index do |item, index|
      assert_not_nil item.inventory
      inventory = item.inventory
      assert_equal 10, inventory.startinginventory
      assert_equal 10, inventory.currentinventory
      assert_equal 9, inventory.resethour
      assert_equal 'active', inventory.status
      assert_not inventory.archived
      assert_equal index + 1, inventory.sequence
    end
  end

  test 'should create menu availabilities matching restaurant hours' do
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    restaurant = Restaurant.last
    menu = Menu.last
    
    # Menu should have same availabilities as restaurant
    assert_equal restaurant.restaurantavailabilities.count, menu.menuavailabilities.count
    
    restaurant.restaurantavailabilities.each do |rest_avail|
      menu_avail = menu.menuavailabilities.find_by(dayofweek: rest_avail.dayofweek)
      assert_not_nil menu_avail
      assert_equal rest_avail.starthour, menu_avail.starthour
      assert_equal rest_avail.startmin, menu_avail.startmin
      assert_equal rest_avail.endhour, menu_avail.endhour
      assert_equal rest_avail.endmin, menu_avail.endmin
      assert_equal 'active', menu_avail.status
    end
  end

  test 'should handle empty menu items gracefully' do
    @onboarding.update!(menu_items: [])
    
    assert_nothing_raised do
      CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    end
    
    menu = Menu.last
    # Should still create menu but no sections or items
    assert_equal 0, menu.menusections.count
  end

  test 'should handle hash format menu items' do
    @onboarding.update!(menu_items: {
      '0' => { 'name' => 'Hash Item 1', 'price' => '10.00' },
      '1' => { 'name' => 'Hash Item 2', 'price' => '15.00' }
    })
    
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    menu = Menu.last
    section = menu.menusections.first
    assert_equal 2, section.menuitems.count
    
    item1 = section.menuitems.find_by(name: 'Hash Item 1')
    assert_equal 10.0, item1.price
  end

  # === ANALYTICS TRACKING TESTS ===
  
  test 'should track analytics events' do
    # Mock AnalyticsService to verify calls
    analytics_calls = []
    
    AnalyticsService.stub :track_onboarding_completed, ->(user, data) { analytics_calls << [:onboarding_completed, user, data] } do
      AnalyticsService.stub :track_restaurant_created, ->(user, restaurant) { analytics_calls << [:restaurant_created, user, restaurant] } do
        AnalyticsService.stub :track_menu_created, ->(user, menu) { analytics_calls << [:menu_created, user, menu] } do
          AnalyticsService.stub :identify_user, ->(user, traits) { analytics_calls << [:identify_user, user, traits] } do
            CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
          end
        end
      end
    end
    
    assert_equal 4, analytics_calls.length
    
    # Check onboarding completed call
    onboarding_call = analytics_calls.find { |call| call[0] == :onboarding_completed }
    assert_not_nil onboarding_call
    assert_equal @user, onboarding_call[1]
    
    # Check identify user call
    identify_call = analytics_calls.find { |call| call[0] == :identify_user }
    assert_not_nil identify_call
    traits = identify_call[2]
    assert traits[:has_restaurant]
    assert traits[:has_menu]
    assert traits[:onboarding_completed]
    assert_not_nil traits[:onboarding_completed_at]
  end

  test 'should handle analytics failures gracefully' do
    # Mock AnalyticsService to raise errors
    AnalyticsService.stub :track_onboarding_completed, -> { raise StandardError.new('Analytics error') } do
      assert_nothing_raised do
        CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
      end
    end
    
    # Job should still complete successfully
    @onboarding.reload
    assert_equal 'completed', @onboarding.status
  end

  # === SMART MENU SYNC TESTS ===
  
  test 'should call SmartMenuSyncJob perform_async' do
    # Mock SmartMenuSyncJob to verify it's called
    sync_job_called = false
    SmartMenuSyncJob.stub :perform_async, ->(restaurant_id) { 
      sync_job_called = true
      assert_not_nil restaurant_id
    } do
      CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    end
    
    assert sync_job_called, 'SmartMenuSyncJob.perform_async should have been called'
  end

  # === ERROR HANDLING TESTS ===
  
  test 'should handle database transaction rollback' do
    initial_restaurant_count = Restaurant.count
    initial_menu_count = Menu.count
    
    # Create an invalid onboarding session to trigger failure
    invalid_onboarding = OnboardingSession.create!(
      user: @user,
      status: :menu_created,
      restaurant_name: '', # Invalid - blank name should cause failure
      restaurant_type: 'casual_dining',
      cuisine_type: 'italian',
      location: 'New York, NY',
      menu_name: 'Test Menu',
      menu_items: []
    )
    
    assert_raises ActiveRecord::RecordInvalid do
      CreateRestaurantAndMenuJob.perform_now(@user.id, invalid_onboarding.id)
    end
    
    # Should rollback all changes
    assert_equal initial_restaurant_count, Restaurant.count
    assert_equal initial_menu_count, Menu.count
    
    invalid_onboarding.reload
    assert_not_equal 'completed', invalid_onboarding.status
  end

  test 'should log errors and re-raise' do
    # Capture log output
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)
    
    begin
      # Use non-existent user ID to cause failure
      assert_raises ActiveRecord::RecordNotFound do
        CreateRestaurantAndMenuJob.perform_now(99999, @onboarding.id)
      end
      
      log_content = log_output.string
      assert_includes log_content, 'Failed to create restaurant and menu'
    ensure
      Rails.logger = original_logger
    end
  end

  # === INTEGRATION TESTS ===
  
  test 'should work with real database operations' do
    # Test without mocking to ensure real database operations work
    initial_counts = {
      restaurants: Restaurant.count,
      menus: Menu.count,
      menusections: Menusection.count,
      menuitems: Menuitem.count,
      employees: Employee.count,
      tablesettings: Tablesetting.count,
      taxes: Tax.count,
      tips: Tip.count,
      allergyns: Allergyn.count,
      sizes: Size.count
    }
    
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    # Verify all expected records were created
    assert_equal initial_counts[:restaurants] + 1, Restaurant.count
    assert_equal initial_counts[:menus] + 1, Menu.count
    assert_equal initial_counts[:menusections] + 1, Menusection.count
    assert_equal initial_counts[:menuitems] + 2, Menuitem.count # 2 menu items
    assert_equal initial_counts[:employees] + 1, Employee.count
    assert_equal initial_counts[:tablesettings] + 1, Tablesetting.count
    assert_equal initial_counts[:taxes] + 1, Tax.count
    assert_equal initial_counts[:tips] + 1, Tip.count
    assert_equal initial_counts[:allergyns] + 2, Allergyn.count # 2 allergens
    assert_equal initial_counts[:sizes] + 3, Size.count # 3 sizes
  end

  # === PERFORMANCE TESTS ===
  
  test 'should complete job execution within reasonable time' do
    start_time = Time.current
    
    CreateRestaurantAndMenuJob.perform_now(@user.id, @onboarding.id)
    
    execution_time = Time.current - start_time
    assert execution_time < 10.seconds, "Job took too long: #{execution_time}s"
  end

  # === BUSINESS SCENARIO TESTS ===
  
  test 'should handle complete onboarding workflow' do
    # Test the complete flow from onboarding to restaurant creation
    user = User.create!(
      email: 'newuser@example.com',
      password: 'password123',
      first_name: 'New',
      last_name: 'User',
      plan: @plan
    )
    
    onboarding = OnboardingSession.create!(
      user: user,
      status: :menu_created,
      restaurant_name: 'New User Restaurant',
      restaurant_type: 'fine_dining',
      cuisine_type: 'french',
      location: 'Paris, France',
      menu_name: 'French Menu',
      menu_items: [
        { 'name' => 'Coq au Vin', 'price' => '28.99', 'description' => 'Classic French chicken' }
      ]
    )
    
    CreateRestaurantAndMenuJob.perform_now(user.id, onboarding.id)
    
    # Verify complete setup
    onboarding.reload
    assert_equal 'completed', onboarding.status
    
    restaurant = onboarding.restaurant
    assert_equal 'New User Restaurant', restaurant.name
    assert_equal 'EUR', restaurant.currency # France should use EUR
    
    menu = onboarding.menu
    assert_equal 'French Menu', menu.name
    
    menu_item = menu.menusections.first.menuitems.first
    assert_equal 'Coq au Vin', menu_item.name
    assert_equal 28.99, menu_item.price
  end
end
