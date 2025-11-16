require "application_system_test_case"

class SmartmenuStaffOrderingTest < ApplicationSystemTestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:ordering_menu)
    @table = tablesettings(:table_one)
    @smartmenu = smartmenus(:one)
    @employee = employees(:one)
    
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

  test 'staff view shows menu content like customer view' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Verify staff can see menu sections and items
    assert_testid('menu-content-container')
    assert_testid("menu-item-#{@burger.id}")
    assert_testid("add-item-btn-#{@burger.id}")
  end

  test 'staff customer preview functions like actual customer view' do
    visit smartmenu_path(@smartmenu.slug, view: 'customer')
    
    # Verify customer view is displayed
    assert_testid('smartmenu-customer-view')
    assert_testid("menu-item-#{@burger.id}")
  end

  # ===================
  # ORDER MANAGEMENT TESTS
  # ===================

  test 'staff can add items to order on behalf of customer' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    # Verify order created
    order = Ordr.last
    assert_equal 2, order.ordritems.count
    assert_equal @table.id, order.tablesetting_id
    
    # Verify in modal
    open_view_order_modal
    within_testid('order-modal-body') do
      assert_text 'Classic Burger'
      assert_text 'Spaghetti Carbonara'
    end
  end

  test 'staff can add multiple items to order' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add three items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    add_item_to_order(@spring_rolls.id)
    
    # Verify in database
    order = Ordr.last
    assert_equal 3, order.ordritems.count
  end

  test 'staff can remove items from order' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    
    # Open modal and remove item
    open_view_order_modal
    
    first_item = order.ordritems.first
    remove_item_from_order_by_testid("order-item-#{first_item.id}")
    
    # Verify removed
    order.reload
    assert_equal 1, order.ordritems.count
  end

  test 'staff can view order total while building order' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    # Open modal
    open_view_order_modal
    
    # Verify total
    expected_total = @burger.price + @pasta.price
    within_testid('order-total-amount') do
      assert_text "$#{sprintf('%.2f', expected_total)}"
    end
  end

  # ===================
  # ORDER SUBMISSION TESTS
  # ===================

  test 'staff can submit order for customer' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    
    # Open modal and submit
    open_view_order_modal
    
    assert_selector('[data-testid="submit-order-btn"]:not([disabled])', wait: 3)
    find('[data-testid="submit-order-btn"]').click
    
    # Verify order submitted
    order.reload
    assert_equal 'ordered', order.status
  end

  test 'staff can verify order contents before submission' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    add_item_to_order(@spring_rolls.id)
    
    # Open modal to verify
    open_view_order_modal
    
    within_testid('order-modal-body') do
      assert_text 'Classic Burger'
      assert_text 'Spaghetti Carbonara'
      assert_text 'Spring Rolls'
    end
    
    # Verify total
    expected_total = @burger.price + @pasta.price + @spring_rolls.price
    within_testid('order-total-amount') do
      assert_text "$#{sprintf('%.2f', expected_total)}"
    end
  end

  test 'staff can add items after order is submitted' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add and submit order
    add_item_to_order(@burger.id)
    order = Ordr.last
    
    open_view_order_modal
    find('[data-testid="submit-order-btn"]').click
    
    order.reload
    assert_equal 'ordered', order.status
    
    # Close modal
    page.execute_script("bootstrap.Modal.getInstance(document.getElementById('viewOrderModal'))?.hide()")
    sleep 0.5
    
    # Add another item
    add_item_to_order(@pasta.id)
    
    # Verify item added to same order
    order.reload
    assert_equal 2, order.ordritems.count
    assert_equal 'ordered', order.status  # Status remains ordered
  end

  # ===================
  # MULTI-TABLE TESTS
  # ===================

  test 'staff can manage orders for multiple tables' do
    skip "Multi-table switching not implemented in tests yet"
    # This would require table switching logic
  end

  # ===================
  # NAME & PERSISTENCE TESTS
  # ===================

  test 'staff can add customer name to order' do
    skip "Customer name feature not tested in system tests"
    # This would require opening name modal and entering name
  end

  test 'staff can continue working with persistent order' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Create order
    add_item_to_order(@burger.id)
    order_id = Ordr.last.id
    
    # Reload page
    visit smartmenu_path(@smartmenu.slug)
    
    # Add more items
    add_item_to_order(@pasta.id)
    
    # Verify same order
    assert_equal order_id, Ordr.last.id
    assert_equal 2, Ordr.find(order_id).ordritems.count
  end

  # ===================
  # STAFF VS CUSTOMER TESTS
  # ===================

  test 'staff order management matches customer experience' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Staff adds items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    
    # Verify order structure is same as customer would create
    assert_equal 'opened', order.status
    assert_equal @table.id, order.tablesetting_id
    assert_equal @restaurant.id, order.restaurant_id
    assert_equal 2, order.ordritems.count
    
    # Verify items have correct prices
    order.ordritems.each do |item|
      assert item.price > 0, "Item should have price"
      assert item.menuitem.present?, "Item should have menuitem association"
    end
  end
end
