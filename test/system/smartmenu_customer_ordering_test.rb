require "application_system_test_case"

class SmartmenuCustomerOrderingTest < ApplicationSystemTestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:ordering_menu)
    @table = tablesettings(:table_one)
    @smartmenu = smartmenus(:one) # test-menu-ordering slug
    
    # Menu sections
    @starters = menusections(:starters_section)
    @mains = menusections(:mains_section)
    @desserts = menusections(:desserts_section)
    
    # Menu items
    @spring_rolls = menuitems(:spring_rolls)
    @caesar_salad = menuitems(:caesar_salad)
    @burger = menuitems(:burger)
    @pasta = menuitems(:pasta)
    @salmon = menuitems(:salmon)
    @chocolate_cake = menuitems(:chocolate_cake)
    @ice_cream = menuitems(:ice_cream)
  end

  # ===================
  # MENU BROWSING TESTS
  # ===================

  test 'customer can access smartmenu and see customer view' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Verify customer view is displayed
    assert_testid('smartmenu-customer-view')
    assert_no_selector('[data-testid="smartmenu-staff-view"]')
    
    # Verify menu content loads
    assert_testid('menu-content-container')
    assert_testid('menu-sections-container')
  end

  test 'customer can see all menu sections' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Verify all sections are visible
    assert_testid("menu-section-#{@starters.id}")
    assert_testid("menu-section-title-#{@starters.id}")
    
    assert_testid("menu-section-#{@mains.id}")
    assert_testid("menu-section-title-#{@mains.id}")
    
    assert_testid("menu-section-#{@desserts.id}")
    assert_testid("menu-section-title-#{@desserts.id}")
    
    # Verify section names
    within_testid("menu-section-title-#{@starters.id}") do
      assert_text 'Starters'
    end
  end

  test 'customer can see menu items in sections' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Verify items in starters section
    assert_testid("menu-item-#{@spring_rolls.id}")
    assert_testid("menu-item-#{@caesar_salad.id}")
    
    # Verify items in mains section
    assert_testid("menu-item-#{@burger.id}")
    assert_testid("menu-item-#{@pasta.id}")
    assert_testid("menu-item-#{@salmon.id}")
    
    # Verify item names are displayed
    within_testid("menu-item-#{@burger.id}") do
      assert_text 'Classic Burger'
      assert_text '$15.99'
    end
  end

  # ===================
  # ORDER CREATION TESTS
  # ===================

  test 'customer can add first item to create new order' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Track initial order count
    initial_order_count = Ordr.where(restaurant_id: @restaurant.id).count
    
    # Add item to order
    add_item_to_order(@burger.id)
    
    # Verify new order was created in database
    assert_equal initial_order_count + 1, Ordr.where(restaurant_id: @restaurant.id).count
    
    order = Ordr.last
    assert_equal 'opened', order.status
    assert_equal @table.id, order.tablesetting_id
    assert_equal 1, order.ordritems.count
  end

  test 'modal does NOT auto-open after adding item' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add item to order
    add_item_to_order(@burger.id)
    
    # Verify modal is NOT visible (production behavior)
    assert_no_selector('#viewOrderModal.show', wait: 1)
    
    # User must manually open modal
    open_view_order_modal
    
    # Now modal should be visible
    assert_selector('#viewOrderModal.show')
    within_testid('order-modal-body') do
      assert_text 'Classic Burger'
    end
  end

  # ===================
  # ADDING ITEMS TESTS
  # ===================

  test 'customer can add multiple different items to order' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add three items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    add_item_to_order(@spring_rolls.id)
    
    # Verify all in database
    order = Ordr.last
    assert_equal 3, order.ordritems.count
    
    # Open modal to verify UI
    open_view_order_modal
    
    within_testid('order-modal-body') do
      assert_text 'Classic Burger'
      assert_text 'Spaghetti Carbonara'
      assert_text 'Spring Rolls'
    end
  end

  test 'order total updates when items are added' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add two items
    add_item_to_order(@burger.id)
    add_item_to_order(@spring_rolls.id)
    
    # Open modal to verify total
    open_view_order_modal
    
    # Check total
    expected_total = @burger.price + @spring_rolls.price
    within_testid('order-total-amount') do
      assert_text "$#{sprintf('%.2f', expected_total)}"
    end
  end

  test 'customer can add same item multiple times' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add burger twice
    add_item_to_order(@burger.id)
    add_item_to_order(@burger.id)
    
    # Verify in database
    order = Ordr.last
    assert_equal 2, order.ordritems.count
    
    # Verify in UI
    open_view_order_modal
    
    expected_total = @burger.price * 2
    within_testid('order-total-amount') do
      assert_text "$#{sprintf('%.2f', expected_total)}"
    end
  end

  # ===================
  # REMOVING ITEMS TESTS
  # ===================

  test 'customer can remove items from order' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    assert_equal 2, order.ordritems.count
    
    # Open modal
    open_view_order_modal
    
    # Remove first item
    remove_item_from_order_by_testid("order-item-#{order.ordritems.first.id}")
    
    # Verify in database
    order.reload
    assert_equal 1, order.ordritems.count
  end

  # ===================
  # ORDER PERSISTENCE TESTS
  # ===================

  test 'order persists across page reloads' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order_id = Ordr.last.id
    
    # Reload page
    visit smartmenu_path(@smartmenu.slug)
    
    # Verify order still exists
    assert_equal order_id, Ordr.last.id
    assert_equal 2, Ordr.find(order_id).ordritems.count
    
    # Verify visible in modal
    open_view_order_modal
    within_testid('order-modal-body') do
      assert_text 'Classic Burger'
      assert_text 'Spaghetti Carbonara'
    end
  end

  test 'customer can continue adding to persisted order' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add first item
    add_item_to_order(@burger.id)
    order_id = Ordr.last.id
    
    # Reload page
    visit smartmenu_path(@smartmenu.slug)
    
    # Add another item
    add_item_to_order(@pasta.id)
    
    # Verify same order
    assert_equal order_id, Ordr.last.id
    assert_equal 2, Ordr.find(order_id).ordritems.count
  end

  # ===================
  # ORDER SUBMISSION TESTS
  # ===================

  test 'customer can submit order with items' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    
    # Open modal and submit
    open_view_order_modal
    
    # Wait for submit button to be enabled
    assert_selector('[data-testid="submit-order-btn"]:not([disabled])', wait: 3)
    
    # Submit order
    find('[data-testid="submit-order-btn"]').click
    
    # Verify order status changed
    order.reload
    assert_equal 'ordered', order.status
  end

  test 'submit button is disabled when order is empty' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Create order but don't add items
    visit smartmenu_path(@smartmenu.slug)
    
    # Try to open modal - should not have submit button enabled
    open_view_order_modal
    
    # Submit button should be disabled
    assert_selector('[data-testid="submit-order-btn"][disabled]', wait: 3)
  end
end
