require "application_system_test_case"

class SmartmenuOrderStateTest < ApplicationSystemTestCase
  setup do
    @restaurant = restaurants(:one)
    @menu = menus(:ordering_menu)
    @table = tablesettings(:table_one)
    @smartmenu = smartmenus(:one)
    
    # Menu items
    @burger = menuitems(:burger)
    @pasta = menuitems(:pasta)
    @spring_rolls = menuitems(:spring_rolls)
  end

  # ===================
  # ORDER LIFECYCLE TESTS
  # ===================

  test 'new order starts in opened status' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add item to create order
    add_item_to_order(@burger.id)
    
    order = Ordr.last
    assert_equal 'opened', order.status
  end

  test 'empty order remains in opened state' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Create order by adding and removing item
    add_item_to_order(@burger.id)
    order = Ordr.last
    
    open_view_order_modal
    remove_item_from_order_by_testid("order-item-#{order.ordritems.first.id}")
    
    order.reload
    assert_equal 'opened', order.status
    assert_equal 0, order.ordritems.count
  end

  test 'order transitions from opened to ordered on submission' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Create order
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    assert_equal 'opened', order.status
    
    # Submit order
    open_view_order_modal
    find('[data-testid="submit-order-btn"]').click
    
    order.reload
    assert_equal 'ordered', order.status
  end

  test 'cannot submit order with no items' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Try to open modal without adding items
    # If order doesn't exist, this should handle gracefully
    page.execute_script(<<~JS)
      const modalEl = document.getElementById('viewOrderModal');
      if (modalEl) {
        const modal = new bootstrap.Modal(modalEl);
        modal.show();
      }
    JS
    
    # Submit button should be disabled or not present
    if page.has_selector?('[data-testid="submit-order-btn"]', wait: 1)
      assert_selector('[data-testid="submit-order-btn"][disabled]')
    end
  end

  # ===================
  # ORDER PERSISTENCE TESTS
  # ===================

  test 'order persists for same session across page reloads' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Create order
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order_id = Ordr.last.id
    
    # Reload page
    visit smartmenu_path(@smartmenu.slug)
    
    # Verify same order
    assert_equal order_id, Ordr.last.id
    
    # Verify items persisted
    order = Ordr.find(order_id)
    assert_equal 2, order.ordritems.count
  end

  test 'order maintains items across different statuses' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Create order
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    item_ids = order.ordritems.pluck(:id).sort
    
    # Submit order (change status)
    open_view_order_modal
    find('[data-testid="submit-order-btn"]').click
    
    order.reload
    assert_equal 'ordered', order.status
    
    # Verify items still present
    assert_equal item_ids, order.ordritems.pluck(:id).sort
  end

  test 'submitted order can receive additional items' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Create and submit order
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
    
    # Verify item added
    order.reload
    assert_equal 2, order.ordritems.count
    assert_equal 'ordered', order.status
  end

  # ===================
  # ORDER CONTENT TESTS
  # ===================

  test 'order item count reflects actual items' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    add_item_to_order(@spring_rolls.id)
    
    order = Ordr.last
    assert_equal 3, order.ordritems.count
    
    # Remove one
    open_view_order_modal
    remove_item_from_order_by_testid("order-item-#{order.ordritems.first.id}")
    
    order.reload
    assert_equal 2, order.ordritems.count
  end

  test 'order items maintain correct prices' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    
    # Verify each item has correct price
    burger_item = order.ordritems.find { |item| item.menuitem_id == @burger.id }
    pasta_item = order.ordritems.find { |item| item.menuitem_id == @pasta.id }
    
    assert_equal @burger.price, burger_item.price
    assert_equal @pasta.price, pasta_item.price
  end

  test 'order total calculated correctly' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    add_item_to_order(@spring_rolls.id)
    
    order = Ordr.last
    
    # Calculate expected total
    expected_total = @burger.price + @pasta.price + @spring_rolls.price
    
    # Verify in modal
    open_view_order_modal
    within_testid('order-total-amount') do
      assert_text "$#{sprintf('%.2f', expected_total)}"
    end
  end

  test 'removing item updates order total correctly' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add items
    add_item_to_order(@burger.id)
    add_item_to_order(@pasta.id)
    
    order = Ordr.last
    first_item = order.ordritems.first
    
    # Open modal and verify initial total
    open_view_order_modal
    initial_total = @burger.price + @pasta.price
    within_testid('order-total-amount') do
      assert_text "$#{sprintf('%.2f', initial_total)}"
    end
    
    # Remove item
    remove_item_from_order_by_testid("order-item-#{first_item.id}")
    
    # Verify updated total
    order.reload
    remaining_item = order.ordritems.first
    expected_total = remaining_item.price
    
    within_testid('order-total-amount') do
      assert_text "$#{sprintf('%.2f', expected_total)}"
    end
  end

  # ===================
  # ORDER PARTICIPANT TESTS
  # ===================

  test 'order tracks participants correctly' do
    visit smartmenu_path(@smartmenu.slug)
    
    # Add item to create order
    add_item_to_order(@burger.id)
    
    order = Ordr.last
    
    # Verify participant created
    assert order.ordrparticipants.any?, "Order should have participants"
    
    participant = order.ordrparticipants.first
    assert_not_nil participant.sessionid, "Participant should have session ID"
    assert_equal 0, participant.role, "Customer participant should have role 0"
  end
end
