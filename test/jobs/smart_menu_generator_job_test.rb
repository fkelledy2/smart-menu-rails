require 'test_helper'

class SmartMenuGeneratorJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    
    # Ensure proper associations
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant
    
    # Create table settings
    @table1 = Tablesetting.create!(
      name: 'Table 1',
      description: 'First table',
      capacity: 4,
      restaurant: @restaurant,
      tabletype: :indoor,
      status: :free,
      sequence: 1
    )
    
    @table2 = Tablesetting.create!(
      name: 'Table 2', 
      description: 'Second table',
      capacity: 6,
      restaurant: @restaurant,
      tabletype: :outdoor,
      status: :free,
      sequence: 2
    )
  end

  teardown do
    # Clean up test data
  end

  # === BASIC JOB EXECUTION TESTS ===
  
  test 'should perform job successfully with valid restaurant' do
    assert_nothing_raised do
      SmartMenuGeneratorJob.new.perform(@restaurant.id)
    end
  end

  test 'should handle missing restaurant gracefully' do
    # Job should return early without raising an exception when restaurant doesn't exist
    assert_nothing_raised do
      SmartMenuGeneratorJob.new.perform(99999)
    end
  end

  test 'should handle restaurant with no menus' do
    # Create restaurant with no menus
    empty_restaurant = Restaurant.create!(
      name: 'Empty Restaurant',
      user: @user,
      capacity: 20,
      status: :active
    )
    
    # Create table for empty restaurant
    Tablesetting.create!(
      name: 'Empty Table',
      restaurant: empty_restaurant,
      capacity: 4,
      tabletype: :indoor,
      status: :free,
      sequence: 1
    )
    
    assert_nothing_raised do
      SmartMenuGeneratorJob.new.perform(empty_restaurant.id)
    end
  end

  test 'should handle restaurant with no tables' do
    # Create restaurant with no tables
    no_tables_restaurant = Restaurant.create!(
      name: 'No Tables Restaurant',
      user: @user,
      capacity: 20,
      status: :active
    )
    
    # Create menu for restaurant
    Menu.create!(
      name: 'No Tables Menu',
      restaurant: no_tables_restaurant,
      status: :active
    )
    
    assert_nothing_raised do
      SmartMenuGeneratorJob.new.perform(no_tables_restaurant.id)
    end
  end

  # === SMARTMENU CREATION TESTS ===
  
  test 'should create smartmenu for menu without table' do
    initial_count = Smartmenu.count
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Should create smartmenu for menu without table
    menu_smartmenu = Smartmenu.find_by(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: nil
    )
    
    assert_not_nil menu_smartmenu
    assert_not_nil menu_smartmenu.slug
    assert menu_smartmenu.slug.length > 0
  end

  test 'should create smartmenus for each menu-table combination' do
    initial_count = Smartmenu.count
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Should create smartmenus for each menu-table combination
    [@table1, @table2].each do |table|
      menu_table_smartmenu = Smartmenu.find_by(
        restaurant: @restaurant,
        menu: @menu,
        tablesetting: table
      )
      
      assert_not_nil menu_table_smartmenu
      assert_not_nil menu_table_smartmenu.slug
      assert_equal @restaurant, menu_table_smartmenu.restaurant
      assert_equal @menu, menu_table_smartmenu.menu
      assert_equal table, menu_table_smartmenu.tablesetting
    end
  end

  test 'should create smartmenus for tables without menu' do
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Should create smartmenus for each table without menu
    [@table1, @table2].each do |table|
      table_smartmenu = Smartmenu.find_by(
        restaurant: @restaurant,
        menu: nil,
        tablesetting: table
      )
      
      assert_not_nil table_smartmenu
      assert_not_nil table_smartmenu.slug
      assert_equal @restaurant, table_smartmenu.restaurant
      assert_nil table_smartmenu.menu
      assert_equal table, table_smartmenu.tablesetting
    end
  end

  test 'should generate unique slugs for each smartmenu' do
    # Clean up existing smartmenus to ensure we only test newly generated ones
    Smartmenu.where(restaurant: @restaurant).each do |smartmenu|
      Menuparticipant.where(smartmenu: smartmenu).destroy_all
    end
    Smartmenu.where(restaurant: @restaurant).destroy_all
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    smartmenus = Smartmenu.where(restaurant: @restaurant)
    slugs = smartmenus.pluck(:slug)
    
    # All slugs should be unique
    assert_equal slugs.length, slugs.uniq.length
    
    # All slugs should be valid UUIDs (36 characters with dashes)
    slugs.each do |slug|
      assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, slug)
    end
  end

  test 'should not create duplicate smartmenus' do
    # Run job twice
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    initial_count = Smartmenu.where(restaurant: @restaurant).count
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    final_count = Smartmenu.where(restaurant: @restaurant).count
    
    # Count should not change on second run
    assert_equal initial_count, final_count
  end

  test 'should handle multiple menus correctly' do
    # Create additional menu
    menu2 = Menu.create!(
      name: 'Second Menu',
      description: 'Second menu description',
      restaurant: @restaurant,
      status: :active
    )
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Should create smartmenus for both menus
    [@menu, menu2].each do |menu|
      # Menu without table
      menu_smartmenu = Smartmenu.find_by(
        restaurant: @restaurant,
        menu: menu,
        tablesetting: nil
      )
      assert_not_nil menu_smartmenu
      
      # Menu with each table
      [@table1, @table2].each do |table|
        menu_table_smartmenu = Smartmenu.find_by(
          restaurant: @restaurant,
          menu: menu,
          tablesetting: table
        )
        assert_not_nil menu_table_smartmenu
      end
    end
  end

  # === EDGE CASE TESTS ===
  
  test 'should handle existing smartmenus gracefully' do
    # Create existing smartmenu manually
    existing_smartmenu = Smartmenu.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @table1,
      slug: 'existing-slug-123'
    )
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Existing smartmenu should not be modified
    existing_smartmenu.reload
    assert_equal 'existing-slug-123', existing_smartmenu.slug
    
    # Other smartmenus should still be created
    menu_only_smartmenu = Smartmenu.find_by(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: nil
    )
    assert_not_nil menu_only_smartmenu
  end

  test 'should handle tables with different statuses' do
    # Create table with different status
    occupied_table = Tablesetting.create!(
      name: 'Occupied Table',
      restaurant: @restaurant,
      capacity: 2,
      tabletype: :indoor,
      status: :occupied,
      sequence: 3
    )
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Should create smartmenu regardless of table status
    occupied_smartmenu = Smartmenu.find_by(
      restaurant: @restaurant,
      tablesetting: occupied_table
    )
    assert_not_nil occupied_smartmenu
  end

  test 'should handle archived tables' do
    # Create archived table
    archived_table = Tablesetting.create!(
      name: 'Archived Table',
      restaurant: @restaurant,
      capacity: 4,
      tabletype: :indoor,
      status: :free,
      archived: true,
      sequence: 4
    )
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Should still create smartmenu for archived table
    archived_smartmenu = Smartmenu.find_by(
      restaurant: @restaurant,
      tablesetting: archived_table
    )
    assert_not_nil archived_smartmenu
  end

  test 'should handle archived menus' do
    # Create archived menu
    archived_menu = Menu.create!(
      name: 'Archived Menu',
      restaurant: @restaurant,
      status: :active,
      archived: true
    )
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Should still create smartmenu for archived menu
    archived_smartmenu = Smartmenu.find_by(
      restaurant: @restaurant,
      menu: archived_menu,
      tablesetting: nil
    )
    assert_not_nil archived_smartmenu
  end

  # === PERFORMANCE TESTS ===
  
  test 'should handle large number of tables efficiently' do
    # Create many tables
    20.times do |i|
      Tablesetting.create!(
        name: "Performance Table #{i}",
        restaurant: @restaurant,
        capacity: 4,
        tabletype: :indoor,
        status: :free,
        sequence: i + 10
      )
    end
    
    start_time = Time.current
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    execution_time = Time.current - start_time
    assert execution_time < 10.seconds, "Job took too long with many tables: #{execution_time}s"
    
    # Should create smartmenus for all tables
    total_tables = Tablesetting.where(restaurant: @restaurant).count
    table_only_smartmenus = Smartmenu.where(
      restaurant: @restaurant,
      menu: nil
    ).count
    
    assert_equal total_tables, table_only_smartmenus
  end

  test 'should handle large number of menus efficiently' do
    # Create many menus
    10.times do |i|
      Menu.create!(
        name: "Performance Menu #{i}",
        restaurant: @restaurant,
        status: :active
      )
    end
    
    start_time = Time.current
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    execution_time = Time.current - start_time
    assert execution_time < 15.seconds, "Job took too long with many menus: #{execution_time}s"
    
    # Should create smartmenus for all menus
    total_menus = Menu.where(restaurant: @restaurant).count
    menu_only_smartmenus = Smartmenu.where(
      restaurant: @restaurant,
      tablesetting: nil
    ).count
    
    assert_equal total_menus, menu_only_smartmenus
  end

  # === INTEGRATION TESTS ===
  
  test 'should work with real database operations' do
    # Clean up any existing smartmenus for this restaurant to ensure clean test
    # First clean up dependent records
    Smartmenu.where(restaurant: @restaurant).each do |smartmenu|
      Menuparticipant.where(smartmenu: smartmenu).destroy_all
    end
    Smartmenu.where(restaurant: @restaurant).destroy_all
    
    # Count actual menus and tables for this restaurant
    menu_count = Menu.where(restaurant: @restaurant).count
    table_count = Tablesetting.where(restaurant: @restaurant).count
    
    initial_smartmenu_count = Smartmenu.where(restaurant: @restaurant).count
    
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    final_smartmenu_count = Smartmenu.where(restaurant: @restaurant).count
    
    # Calculate expected smartmenus:
    # - menu_count smartmenus (menu-only)
    # - menu_count * table_count smartmenus (menu-table combinations)  
    # - table_count smartmenus (table-only)
    expected_new_smartmenus = menu_count + (menu_count * table_count) + table_count
    assert_equal initial_smartmenu_count + expected_new_smartmenus, final_smartmenu_count
  end

  test 'should integrate with restaurant onboarding workflow' do
    # Simulate restaurant creation workflow
    new_restaurant = Restaurant.create!(
      name: 'New Restaurant',
      user: @user,
      capacity: 40,
      status: :active
    )
    
    new_menu = Menu.create!(
      name: 'New Menu',
      restaurant: new_restaurant,
      status: :active
    )
    
    new_table = Tablesetting.create!(
      name: 'New Table',
      restaurant: new_restaurant,
      capacity: 4,
      tabletype: :indoor,
      status: :free,
      sequence: 1
    )
    
    # Run sync job
    SmartMenuGeneratorJob.new.perform(new_restaurant.id)
    
    # Should create all necessary smartmenus
    smartmenus = Smartmenu.where(restaurant: new_restaurant)
    assert_equal 3, smartmenus.count # menu-only, menu-table, table-only
    
    # Check each type exists
    assert smartmenus.exists?(menu: new_menu, tablesetting: nil)
    assert smartmenus.exists?(menu: new_menu, tablesetting: new_table)
    assert smartmenus.exists?(menu: nil, tablesetting: new_table)
  end

  # === BUSINESS SCENARIO TESTS ===
  
  test 'should handle restaurant expansion scenario' do
    # Initial sync
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    initial_count = Smartmenu.where(restaurant: @restaurant).count
    
    # Restaurant adds new table
    new_table = Tablesetting.create!(
      name: 'Expansion Table',
      restaurant: @restaurant,
      capacity: 8,
      tabletype: :outdoor,
      status: :free,
      sequence: 10
    )
    
    # Run sync again
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Should create smartmenus for new table
    new_count = Smartmenu.where(restaurant: @restaurant).count
    assert new_count > initial_count
    
    # New table should have smartmenus
    assert Smartmenu.exists?(restaurant: @restaurant, menu: @menu, tablesetting: new_table)
    assert Smartmenu.exists?(restaurant: @restaurant, menu: nil, tablesetting: new_table)
  end

  test 'should handle menu addition scenario' do
    # Initial sync
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    initial_count = Smartmenu.where(restaurant: @restaurant).count
    
    # Restaurant adds new menu
    new_menu = Menu.create!(
      name: 'Dinner Menu',
      description: 'Evening dining options',
      restaurant: @restaurant,
      status: :active
    )
    
    # Run sync again
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Should create smartmenus for new menu
    new_count = Smartmenu.where(restaurant: @restaurant).count
    assert new_count > initial_count
    
    # New menu should have smartmenus
    assert Smartmenu.exists?(restaurant: @restaurant, menu: new_menu, tablesetting: nil)
    [@table1, @table2].each do |table|
      assert Smartmenu.exists?(restaurant: @restaurant, menu: new_menu, tablesetting: table)
    end
  end

  test 'should handle QR code generation workflow' do
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Each smartmenu should have a unique slug for QR code generation
    smartmenus = Smartmenu.where(restaurant: @restaurant)
    
    smartmenus.each do |smartmenu|
      # Slug should be suitable for URL generation
      assert_not_nil smartmenu.slug
      assert smartmenu.slug.length > 0
      assert_no_match(/\s/, smartmenu.slug) # No spaces
      
      # Should be able to construct URL
      url = "https://example.com/smartmenus/#{smartmenu.slug}"
      assert url.length > 0
    end
  end

  test 'should handle table ordering workflow' do
    SmartMenuGeneratorJob.new.perform(@restaurant.id)
    
    # Each table should have smartmenus for ordering
    [@table1, @table2].each do |table|
      # Table should have menu-specific smartmenu
      menu_smartmenu = Smartmenu.find_by(
        restaurant: @restaurant,
        menu: @menu,
        tablesetting: table
      )
      assert_not_nil menu_smartmenu
      
      # Table should have general smartmenu (no specific menu)
      general_smartmenu = Smartmenu.find_by(
        restaurant: @restaurant,
        menu: nil,
        tablesetting: table
      )
      assert_not_nil general_smartmenu
    end
  end

  # === CONCURRENT EXECUTION TESTS ===
  
  test 'should handle concurrent sync operations' do
    # Test multiple sync jobs running simultaneously
    jobs = []
    
    3.times do
      jobs << Thread.new do
        SmartMenuGeneratorJob.new.perform(@restaurant.id)
      end
    end
    
    # Wait for all jobs to complete
    jobs.each(&:join)
    
    # Should not create duplicates
    smartmenus = Smartmenu.where(restaurant: @restaurant)
    
    # Check for duplicates
    combinations = smartmenus.map { |sm| [sm.menu_id, sm.tablesetting_id] }
    assert_equal combinations.length, combinations.uniq.length, 'Should not create duplicate smartmenus'
  end
end
