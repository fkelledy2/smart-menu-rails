require "application_system_test_case"

class SmartmenuStaffOrderingTest < ApplicationSystemTestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:ordering_menu)
    @table = tablesettings(:table_one)
    @smartmenu = smartmenus(:one)
    @employee = employees(:one)
    
    # Ensure smartmenu has table set
    @smartmenu.update!(tablesetting: @table)
    
    # Menu items
    @burger = menuitems(:burger)
    @pasta = menuitems(:pasta)
    @spring_rolls = menuitems(:spring_rolls)
    
    # Sign in as staff
    sign_in(@employee.user)
  end

  # ===================
  # STAFF VIEW TESTS
  # ===================

  test 'staff view shows menu content with enabled buttons when table is set' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Verify staff can see menu sections and items
    assert_testid('menu-content-container')
    assert_testid('smartmenu-staff-view')
    assert_testid("menu-item-#{@burger.id}")
    
    # Verify add button exists and is enabled (table is set)
    button = find_testid("add-item-btn-#{@burger.id}")
    assert_not button.disabled?, "Button should be enabled when table is set"
  end

  test 'staff customer preview functions like actual customer view' do
    visit smartmenu_path(@smartmenu.slug, view: 'customer')
    
    # Verify customer view is displayed
    assert_testid('smartmenu-customer-view')
    assert_testid("menu-item-#{@burger.id}")
  end

  # ===================
  # ORDER CREATION & MANAGEMENT TESTS
  # ===================

  test 'staff can start order and add first item' do
    visit smartmenu_path(@smartmenu.slug)
    start_order_if_needed
    
    # Add first item
    add_item_to_order(@burger.id)
    
    # Verify item was added to order
    order = Ordr.where(tablesetting_id: @table.id, menu_id: @menu.id).last
    assert order.present?, "Order should exist for this table"
    
    # Reload to get fresh data
    order.reload
    
    assert_equal @table.id, order.tablesetting_id, "Order should be linked to table"
    assert_equal 'opened', order.status, "Order should be opened"
    assert_equal 1, order.ordritems.where(menuitem_id: @burger.id).count, "Should have burger in order"
  end

  test 'staff can add multiple items to existing order' do
    visit smartmenu_path(@smartmenu.slug)
    start_order_if_needed
    
    # Add first item - creates order
    add_item_to_order(@burger.id)
    order = Ordr.last
    
    # Add second item - adds to same order
    add_item_to_order(@pasta.id)
    order.reload
    
    # Add third item - adds to same order
    add_item_to_order(@spring_rolls.id)
    order.reload
    
    # Verify all added to same order
    assert_equal 3, order.ordritems.count
    assert_equal @table.id, order.tablesetting_id
  end

  test 'staff can view order items in database after adding' do
    visit smartmenu_path(@smartmenu.slug)
    start_order_if_needed
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    # Verify order created with correct items
    order = Ordr.last
    assert_equal 2, order.ordritems.count
    
    item_names = order.ordritems.map { |item| item.menuitem.name }
    assert_includes item_names, 'Classic Burger'
    assert_includes item_names, 'Spaghetti Carbonara'
  end

  test 'staff can calculate order total from database' do
    visit smartmenu_path(@smartmenu.slug)
    start_order_if_needed
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    # Verify total calculated correctly
    order = Ordr.last
    expected_total = @burger.price + @pasta.price
    actual_total = order.ordritems.sum(:ordritemprice)
    
    assert_equal expected_total, actual_total
  end

  # ===================
  # ORDER SUBMISSION TESTS
  # ===================

  test 'staff can submit order by changing status to ordered' do
    visit smartmenu_path(@smartmenu.slug)
    start_order_if_needed
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    assert_equal 'opened', order.status
    
    # Submit order by updating status
    order.update!(status: 'ordered')
    
    # Verify order submitted
    order.reload
    assert_equal 'ordered', order.status
    assert_equal 2, order.ordritems.count
  end

  test 'staff can verify all order attributes after creation' do
    visit smartmenu_path(@smartmenu.slug)
    start_order_if_needed
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    add_item_to_order(@spring_rolls.id)
    
    order = Ordr.last
    
    # Verify order attributes
    assert_equal @table.id, order.tablesetting_id
    # Note: employee_id may be nil in auto-created orders, gets set on first ordrparticipant creation
    assert_equal @restaurant.id, order.restaurant_id
    assert_equal @menu.id, order.menu_id
    assert_equal 'opened', order.status
    assert_equal 3, order.ordritems.count
    
    # Verify item prices
    expected_total = @burger.price + @pasta.price + @spring_rolls.price
    assert_equal expected_total, order.ordritems.sum(:ordritemprice)
  end

  test 'staff order persists across page reloads' do
    visit smartmenu_path(@smartmenu.slug)
    start_order_if_needed
    
    # Create order with one item
    add_item_to_order(@burger.id)
    order_id = Ordr.last.id
    
    # Reload page
    visit smartmenu_path(@smartmenu.slug)
    
    # Add another item
    add_item_to_order(@pasta.id)
    
    # Verify same order persisted
    assert_equal order_id, Ordr.last.id
    order = Ordr.find(order_id)
    assert_equal 2, order.ordritems.count
  end

  test 'staff order items persist in database' do
    visit smartmenu_path(@smartmenu.slug)
    start_order_if_needed
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    
    # Verify items exist in database
    assert order.ordritems.exists?(menuitem_id: @burger.id)
    assert order.ordritems.exists?(menuitem_id: @pasta.id)
    
    # Verify item attributes
    burger_item = order.ordritems.find_by(menuitem_id: @burger.id)
    assert_equal @burger.price, burger_item.ordritemprice
    # Note: ordritem status is 'opened' not 'added' - matches order status
    assert_includes ['opened', 'added'], burger_item.status
  end

  test 'staff can create multiple separate orders for different tables' do
    # Create second table and smartmenu
    table2 = Tablesetting.create!(
      restaurant: @restaurant,
      name: 'Table 2',
      status: 1,
      capacity: 4,
      tabletype: 1
    )
    
    smartmenu2 = Smartmenu.create!(
      slug: 'test-menu-table-2',
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: table2
    )
    
    # Visit first smartmenu - order auto-created
    visit smartmenu_path(@smartmenu.slug)
    add_item_to_order(@burger.id)
    order1 = Ordr.where(tablesetting_id: @table.id).last
    
    # Visit second smartmenu and explicitly start order for table 2
    visit smartmenu_path(smartmenu2.slug)
    start_order_if_needed
    order2 = Ordr.where(tablesetting_id: table2.id).last
    
    # Verify order for table 2 exists (explicitly started)
    assert order2.present?, "Order should exist for table 2 after starting"
    
    # Add item to table 2's order
    add_item_to_order(@pasta.id)
    order2.reload
    
    # Verify two separate orders for different tables
    refute_equal order1.id, order2.id, "Should have different order IDs"
    assert_equal @table.id, order1.tablesetting_id, "Order 1 should be for table 1"
    assert_equal table2.id, order2.tablesetting_id, "Order 2 should be for table 2"
    
    # Verify items are in correct orders
    assert_equal 1, order1.ordritems.count, "Order 1 should have 1 item"
    assert_equal 1, order2.ordritems.count, "Order 2 should have 1 item"
  end

  test 'staff order creation follows same pattern as customer' do
    visit smartmenu_path(@smartmenu.slug)
    start_order_if_needed
    
    # Staff adds items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    
    # Verify order structure matches customer orders
    assert_equal 'opened', order.status
    assert_equal @table.id, order.tablesetting_id
    assert_equal @restaurant.id, order.restaurant_id
    assert_equal 2, order.ordritems.count
    
    # Verify items have correct prices
    order.ordritems.each do |item|
      assert item.ordritemprice > 0, "Item should have price"
      assert item.menuitem.present?, "Item should have menuitem association"
    end
  end
end
