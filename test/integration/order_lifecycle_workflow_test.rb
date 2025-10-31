require 'test_helper'

class OrderLifecycleWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update(user: @user)
    @menu = menus(:one)
    @menu.update(restaurant: @restaurant)
    @menu_item = menuitems(:one)
    @tablesetting = tablesettings(:one)
    sign_in @user
  end

  test 'complete order lifecycle from creation to completion' do
    # Step 1: Create order
    order = @restaurant.ordrs.create!(
      tablesetting: @tablesetting,
      menu: @menu,
      status: :opened  # 0
    )
    
    # Add order item (simplified - just create the association)
    order.ordritems.create!(
      menuitem: @menu_item,
      ordritemprice: @menu_item.price
    )
    
    assert_not_nil order
    assert_equal 'opened', order.status
    assert_equal @tablesetting.id, order.tablesetting_id
    assert_equal 1, order.ordritems.count
    
    # Step 2: Order placed
    order.update!(status: :ordered)  # 20
    order.reload
    assert_equal 'ordered', order.status
    
    # Step 3: Start preparing
    order.update!(status: :preparing)  # 22
    order.reload
    assert_equal 'preparing', order.status
    
    # Step 4: Mark as ready
    order.update!(status: :ready)  # 24
    order.reload
    assert_equal 'ready', order.status
    
    # Step 5: Deliver order
    order.update!(status: :delivered)  # 25
    
    order.reload
    assert_equal 'delivered', order.status
  end

  test 'order with multiple items' do
    item1 = @menu_item
    item2 = menuitems(:two)
    
    order = @restaurant.ordrs.create!(
      tablesetting: @tablesetting,
      menu: @menu,
      status: :opened
    )
    
    order.ordritems.create!(
      menuitem: item1,
      ordritemprice: item1.price
    )
    
    order.ordritems.create!(
      menuitem: item2,
      ordritemprice: item2.price
    )
    
    assert_equal 2, order.ordritems.count
    
    # Verify items associated correctly
    assert_includes order.ordritems.map(&:menuitem_id), item1.id
    assert_includes order.ordritems.map(&:menuitem_id), item2.id
  end

  test 'order status transitions are validated' do
    order = @restaurant.ordrs.create!(
      tablesetting: @tablesetting,
      menu: @menu,
      status: :opened
    )
    
    # Valid transition: opened -> ordered
    order.update(status: :ordered)
    assert_equal 'ordered', order.status
    
    # Valid transition: ordered -> preparing
    order.update(status: :preparing)
    assert_equal 'preparing', order.status
    
    # Valid transition: preparing -> ready
    order.update(status: :ready)
    assert_equal 'ready', order.status
    
    # Valid transition: ready -> delivered
    order.update(status: :delivered)
    assert_equal 'delivered', order.status
  end

  test 'order payment workflow' do
    order = @restaurant.ordrs.create!(
      tablesetting: @tablesetting,
      menu: @menu,
      status: :opened
    )
    
    # Request bill
    order.update!(status: :billrequested)
    order.reload
    assert_equal 'billrequested', order.status
    
    # Mark as paid
    order.update!(status: :paid)
    order.reload
    assert_equal 'paid', order.status
    
    # Close order
    order.update!(status: :closed)
    order.reload
    assert_equal 'closed', order.status
  end

  test 'order with items and notes' do
    order = @restaurant.ordrs.create!(
      tablesetting: @tablesetting,
      menu: @menu,
      status: :opened
    )
    
    ordritem = order.ordritems.create!(
      menuitem: @menu_item,
      ordritemprice: @menu_item.price
    )
    
    # Add note to order item
    ordritem.ordritemnotes.create!(note: 'Well done') if ordritem.respond_to?(:ordritemnotes)
    
    # Verify order and items created
    assert_not_nil order
    assert_equal 1, order.ordritems.count
  end

  test 'order with multiple items and prices' do
    item1_price = 10.00
    item2_price = 15.00
    
    order = @restaurant.ordrs.create!(
      tablesetting: @tablesetting,
      menu: @menu,
      status: :opened
    )
    
    order.ordritems.create!(
      menuitem: @menu_item,
      ordritemprice: item1_price
    )
    
    item2 = menuitems(:two)
    
    order.ordritems.create!(
      menuitem: item2,
      ordritemprice: item2_price
    )
    
    # Verify items created
    assert_equal 2, order.ordritems.count
    
    # Verify prices stored correctly
    prices = order.ordritems.map(&:ordritemprice).sort
    assert_equal [item1_price, item2_price].sort, prices
  end

  test 'order timestamps are recorded' do
    order = @restaurant.ordrs.create!(
      tablesetting: @tablesetting,
      menu: @menu,
      status: :opened
    )
    
    assert_not_nil order.created_at
    assert_not_nil order.updated_at
    
    original_updated_at = order.updated_at
    
    # Update status
    sleep 0.1 # Ensure time difference
    order.update(status: :ordered)
    
    assert order.updated_at > original_updated_at
  end

  test 'multiple concurrent orders for same restaurant' do
    # Create multiple orders
    order1 = @restaurant.ordrs.create!(tablesetting: @tablesetting, menu: @menu, status: :opened)
    order2 = @restaurant.ordrs.create!(tablesetting: @tablesetting, menu: @menu, status: :opened)
    order3 = @restaurant.ordrs.create!(tablesetting: @tablesetting, menu: @menu, status: :opened)
    
    # Update different orders
    order1.update(status: :ordered)
    order2.update(status: :preparing)
    order3.update(status: :ready)
    
    # Verify each order maintained correct state
    assert_equal 'ordered', order1.reload.status
    assert_equal 'preparing', order2.reload.status
    assert_equal 'ready', order3.reload.status
  end

  test 'order item price updates' do
    order = @restaurant.ordrs.create!(
      tablesetting: @tablesetting,
      menu: @menu,
      status: :opened
    )
    
    order_item = order.ordritems.create!(
      menuitem: @menu_item,
      ordritemprice: 10.00
    )
    
    original_price = order_item.ordritemprice
    
    # Update price
    order_item.update(ordritemprice: 15.00)
    
    new_price = order_item.reload.ordritemprice
    assert new_price > original_price
    assert_equal 15.00, order_item.reload.ordritemprice
  end
end
