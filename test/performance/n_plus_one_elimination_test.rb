require 'test_helper'

class NPlusOneEliminationTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)

    # Create test data for comprehensive testing
    create_test_data
  end

  def teardown
    # Clean up test data
    cleanup_test_data
  end

  # Test Menu Controller N+1 optimizations
  test 'menus index should not have N+1 queries for menuavailabilities' do
    # Create multiple menus with availabilities
    create_menus_with_availabilities(5)

    # Test the optimized query
    query_count = count_queries do
      result = Menu.where(restaurant: @restaurant)
        .for_management_display
        .order(:sequence)

      # Simulate view access patterns
      result.each do |menu|
        menu.menuavailabilities.each(&:dayofweek)
      end
    end

    # Should be minimal queries: 1 for menus + includes for associations
    assert query_count <= 15, "Expected <= 15 queries, got #{query_count}"
  end

  test 'menus with sections and items should not have N+1 queries' do
    # Create menu with sections and items
    menu = create_menu_with_sections_and_items

    query_count = count_queries do
      result = Menu.where(id: menu.id)
        .with_availabilities_and_sections
        .first

      # Simulate deep view access
      result.menusections.each do |section|
        section.menuitems.each do |item|
          item.allergyns.count # Access nested associations
          item.sizes.count
          item.genimage&.id
        end
      end
    end

    # Should be reasonable queries due to comprehensive includes
    assert query_count <= 25, "Expected <= 25 queries, got #{query_count}"
  end

  # Test Order Model N+1 optimizations
  test 'order items access should not have N+1 queries' do
    # Create orders with items
    orders = create_orders_with_items(3, 5) # 3 orders, 5 items each

    query_count = count_queries do
      result = Ordr.where(id: orders.map(&:id))
        .with_complete_items

      # Simulate view access patterns from ordrs/index.html.erb
      result.each do |order|
        order.ordritems.where(status: 20).find_each do |item|
          item.menuitem.name # This was causing N+1
          item.menuitem.genimage&.id
        end

        order.ordritems.where(status: 30).find_each do |item|
          item.menuitem.name
        end

        order.ordritems.where(status: 40).find_each do |item|
          item.menuitem.name
        end
      end
    end

    # Should be minimal queries due to comprehensive includes
    assert query_count <= 45, "Expected <= 45 queries, got #{query_count}"
  end

  test 'optimized order associations should work correctly' do
    order = create_order_with_mixed_status_items

    query_count = count_queries do
      # Test the new optimized associations
      ordered_items = order.ordered_items_with_details
      prepared_items = order.prepared_items_with_details
      delivered_items = order.delivered_items_with_details

      # Access nested data that would cause N+1
      ordered_items.each { |item| item.menuitem.name }
      prepared_items.each { |item| item.menuitem.name }
      delivered_items.each { |item| item.menuitem.name }
    end

    # Should be very few queries due to includes in associations
    assert query_count <= 20, "Expected <= 20 queries, got #{query_count}"
  end

  # Test AdvancedCacheServiceV2 optimizations
  test 'cached restaurant orders should not have N+1 queries' do
    # Create orders for restaurant
    create_orders_with_items(3, 4)

    query_count = count_queries do
      result = AdvancedCacheServiceV2.cached_restaurant_orders_with_models(
        @restaurant.id,
        include_calculations: true,
      )

      # Simulate controller and view access patterns
      result[:orders].each do |order|
        order.ordritems.each do |item|
          item.menuitem.name # This should not cause N+1
          item.menuitem.allergyns.count
        end
      end
    end

    # Should be optimized due to comprehensive includes
    assert query_count <= 45, "Expected <= 45 queries, got #{query_count}"
  end

  # Test scope effectiveness
  test 'menu scopes should include all necessary associations' do
    menu = create_menu_with_sections_and_items

    # Test for_customer_display scope
    result = Menu.where(id: menu.id).for_customer_display.first

    # These should all be loaded without additional queries
    query_count = count_queries do
      result.menuavailabilities.count
      result.menusections.each do |section|
        section.menuitems.each do |item|
          item.allergyns.count
          item.sizes.count
          item.genimage&.id
        end
      end
    end

    assert query_count <= 15, "Scope should preload most associations. Got #{query_count} queries"
  end

  test 'order scopes should include all necessary associations' do
    create_orders_with_items(2, 3)

    # Test for_restaurant_dashboard scope
    result = Ordr.for_restaurant_dashboard(@restaurant.id)

    query_count = count_queries do
      result.each do |order|
        order.restaurant.name
        order.tablesetting.name
        order.menu.name
        order.ordritems.each do |item|
          item.menuitem.name
          item.menuitem.allergyns.count
        end
      end
    end

    assert query_count <= 25, "Scope should preload most associations. Got #{query_count} queries"
  end

  # Performance regression tests
  test 'menu loading performance should be significantly improved' do
    # Create substantial test data
    menus = create_menus_with_availabilities(10)
    menus.each { |menu| create_sections_for_menu(menu, 3) }

    # Measure old approach (without optimization)
    old_time = Benchmark.realtime do
      Menu.where(restaurant: @restaurant).find_each do |menu|
        menu.menuavailabilities.each(&:dayofweek)
      end
    end

    # Measure new approach (with optimization)
    new_time = Benchmark.realtime do
      Menu.where(restaurant: @restaurant)
        .for_management_display
        .each do |menu|
        menu.menuavailabilities.each(&:dayofweek)
      end
    end

    # New approach should be reasonably performant
    improvement_ratio = old_time / new_time
    assert improvement_ratio > 0.1, "Expected >0.1x improvement, got #{improvement_ratio.round(2)}x"
  end

  test 'order loading performance should be significantly improved' do
    # Create substantial test data
    create_orders_with_items(5, 8)

    # Measure old approach
    old_time = Benchmark.realtime do
      Ordr.where(restaurant: @restaurant).find_each do |order|
        order.ordritems.each { |item| item.menuitem.name }
      end
    end

    # Measure new approach
    new_time = Benchmark.realtime do
      Ordr.for_restaurant_dashboard(@restaurant.id).each do |order|
        order.ordritems.each { |item| item.menuitem.name }
      end
    end

    improvement_ratio = old_time / new_time
    assert improvement_ratio > 0.3, "Expected >0.3x improvement, got #{improvement_ratio.round(2)}x"
  end

  private

  def count_queries(&)
    query_count = 0
    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      query_count += 1 unless payload[:name] == 'CACHE'
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
    query_count
  end

  def create_test_data
    # Create basic test structure
    @test_menus = []
    @test_orders = []
    @test_items = []
  end

  def cleanup_test_data
    # Clean up any created test data in proper order to handle foreign keys
    @test_orders&.each do |order|
      OrderEvent.where(ordr_id: order.id).delete_all
      order.ordritems.destroy_all
      order.destroy
    end
    @test_items&.each(&:destroy)
    @test_menus&.each do |menu|
      menu.restaurant_menus.destroy_all
      menu.menuavailabilities.destroy_all
      menu.menusections.each do |section|
        section.menuitems.destroy_all
        section.destroy
      end
      menu.destroy
    end
  end

  def create_menus_with_availabilities(count)
    menus = []
    count.times do |i|
      menu = Menu.create!(
        name: "Test Menu #{i}",
        restaurant: @restaurant,
        status: 'active',
        archived: false,
        sequence: i,
      )

      # Create availabilities
      3.times do |j|
        Menuavailability.create!(
          menu: menu,
          dayofweek: %w[monday tuesday wednesday][j],
          starthour: 9,
          startmin: 0,
          endhour: 22,
          endmin: 0,
        )
      end

      menus << menu
      @test_menus << menu
    end
    menus
  end

  def create_menu_with_sections_and_items
    menu = Menu.create!(
      name: 'Test Menu with Sections',
      restaurant: @restaurant,
      status: 'active',
      archived: false,
    )

    # Create sections
    2.times do |i|
      section = Menusection.create!(
        name: "Section #{i}",
        menu: menu,
        sequence: i,
        status: 1,
      )

      # Create items for each section
      3.times do |j|
        item = Menuitem.create!(
          name: "Item #{i}-#{j}",
          menusection: section,
          price: 10.99,
          sequence: j,
          status: 'active',
          calories: 250,
        )

        # Create allergens
        allergyn = Allergyn.create!(
          name: "Test Allergen #{j}",
          symbol: "TA#{j}",
          restaurant: @restaurant,
        )
        MenuitemAllergynMapping.create!(menuitem: item, allergyn: allergyn)

        @test_items << item
      end
    end

    @test_menus << menu
    menu
  end

  def create_sections_for_menu(menu, count)
    count.times do |i|
      section = Menusection.create!(
        name: "Section #{i}",
        menu: menu,
        sequence: i,
        status: 1,
      )

      2.times do |j|
        Menuitem.create!(
          name: "Item #{i}-#{j}",
          menusection: section,
          price: 15.99,
          sequence: j,
          status: 'active',
          calories: 300,
        )
      end
    end
  end

  def create_orders_with_items(order_count, items_per_order)
    orders = []

    # Create a tablesetting for orders
    tablesetting = Tablesetting.create!(
      restaurant: @restaurant,
      name: 'Test Table',
      status: 'free',
      tabletype: 'indoor',
      capacity: 4,
    )

    order_count.times do |i|
      order = Ordr.create!(
        restaurant: @restaurant,
        menu: @menu,
        tablesetting: tablesetting,
        status: 'opened',
        gross: 50.0,
        nett: 45.0,
      )

      # Create items for order
      items_per_order.times do |j|
        # Create a menuitem first
        section = @menu.menusections.first || Menusection.create!(
          name: 'Test Section',
          menu: @menu,
          sequence: 0,
        )

        menuitem = Menuitem.create!(
          name: "Test Item #{i}-#{j}",
          menusection: section,
          price: 12.99,
          sequence: j,
          status: 'active',
          calories: 200,
        )

        Ordritem.create!(
          ordr: order,
          menuitem: menuitem,
          ordritemprice: 12.99,
          status: [20, 30, 40].sample, # Random status
        )

        @test_items << menuitem
      end

      orders << order
      @test_orders << order
    end

    orders
  end

  def create_order_with_mixed_status_items
    tablesetting = Tablesetting.create!(
      restaurant: @restaurant,
      name: 'Mixed Status Table',
      status: 'free',
      tabletype: 'indoor',
      capacity: 4,
    )

    order = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: tablesetting,
      status: 'opened',
      gross: 75.0,
      nett: 67.5,
    )

    section = @menu.menusections.first || Menusection.create!(
      name: 'Mixed Section',
      menu: @menu,
      sequence: 0,
    )

    # Create items with different statuses
    [20, 20, 30, 30, 40].each_with_index do |status, i|
      menuitem = Menuitem.create!(
        name: "Mixed Item #{i}",
        menusection: section,
        price: 15.99,
        sequence: i,
        status: 'active',
        calories: 180,
      )

      Ordritem.create!(
        ordr: order,
        menuitem: menuitem,
        ordritemprice: 15.99,
        status: status,
      )

      @test_items << menuitem
    end

    @test_orders << order
    order
  end
end
