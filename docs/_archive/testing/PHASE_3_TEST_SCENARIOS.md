# Phase 3: Smartmenu Test Scenarios - Quick Reference

## 🎯 Testing Matrix

| # | Scenario | Customer Path | Staff Path | Priority |
|---|----------|---------------|------------|----------|
| **1** | **Starting Orders** | | | |
| 1.1 | New order creation | ✅ | ✅ | 🔴 Critical |
| 1.2 | Reopen existing order | ✅ | ✅ | 🔴 Critical |
| 1.3 | Order persistence | ✅ | ✅ | 🟡 High |
| **2** | **Customer Name** | | | |
| 2.1 | Add customer name | ✅ | ✅ | 🟡 High |
| 2.2 | Update customer name | ✅ | ✅ | 🟢 Medium |
| **3** | **Adding Items** | | | |
| 3.1 | Add single item | ✅ | ✅ | 🔴 Critical |
| 3.2 | Add with quantity | ✅ | ✅ | 🔴 Critical |
| 3.3 | Add multiple items | ✅ | ✅ | 🔴 Critical |
| 3.4 | Add duplicate item | ✅ | ✅ | 🟡 High |
| **4** | **Removing Items** | | | |
| 4.1 | Remove single item | ✅ | ✅ | 🔴 Critical |
| 4.2 | Remove all items | ✅ | ✅ | 🟡 High |
| 4.3 | Remove from multi-item | ✅ | ✅ | 🟡 High |
| **5** | **Order Submission** | | | |
| 5.1 | Submit valid order | ✅ | ✅ | 🔴 Critical |
| 5.2 | Submit validation | ✅ | ✅ | 🔴 Critical |
| 5.3 | Submit confirmation | ✅ | ✅ | 🟡 High |
| **6** | **Modify Submitted** | | | |
| 6.1 | Add to submitted order | ✅ | ✅ | 🟡 High |
| 6.2 | Add during prep | ✅ | ✅ | 🟢 Medium |
| 6.3 | Modify order item | ✅ | ✅ | 🟢 Medium |

**Total Scenarios:** 18  
**Critical Priority:** 10  
**High Priority:** 6  
**Medium Priority:** 2

---

## 📋 Scenario Details

### 🔴 Critical Priority (Must Pass)

#### 1.1 New Order Creation - Customer
```ruby
test 'customer can create new order by adding first item' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Verify customer view
  assert_testid('smartmenu-customer-view')
  assert_no_selector('[data-testid="staff-controls"]')
  
  # Add first item
  click_testid("add-item-btn-#{@item1.id}")
  
  # Verify order created
  assert_testid('order-summary-container')
  assert_text @item1.name
  assert_text "$#{@item1.price}"
  
  # Verify database
  order = Ordr.last
  assert_equal 'opened', order.status
  assert_equal 1, order.ordritems.count
end
```

#### 1.2 Reopen Existing Order
```ruby
test 'customer can reopen existing order in same session' do
  # Create order with item
  visit smartmenu_path(@smartmenu.slug)
  click_testid("add-item-btn-#{@item1.id}")
  order_id = Ordr.last.id
  
  # Leave and return (same session)
  visit root_path
  visit smartmenu_path(@smartmenu.slug)
  
  # Verify order loaded
  assert_testid('order-summary-container')
  assert_text @item1.name
  
  # Verify same order
  assert_equal order_id, Ordr.last.id
end
```

#### 3.1 Add Single Item
```ruby
test 'customer can add single item to order' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Add item
  click_testid("add-item-btn-#{@item1.id}")
  
  # Verify UI update
  within_testid('order-items-list') do
    assert_testid("order-item-#{Ordritem.last.id}")
    assert_text @item1.name
  end
  
  # Verify total
  within_testid('order-total') do
    assert_text "$#{@item1.price}"
  end
end
```

#### 3.2 Add Item with Quantity
```ruby
test 'customer can add item with quantity greater than 1' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Open item details
  click_testid("menu-item-#{@item1.id}")
  assert_testid('item-details-modal')
  
  # Increase quantity
  3.times { click_testid('item-quantity-increase') }
  assert_equal '3', find_testid('item-quantity-input').value
  
  # Add to order
  click_testid('item-add-to-order-btn')
  
  # Verify total
  expected_total = @item1.price * 3
  within_testid('order-total') do
    assert_text "$#{expected_total}"
  end
end
```

#### 3.3 Add Multiple Different Items
```ruby
test 'customer can add multiple different items' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Add three different items
  click_testid("add-item-btn-#{@item1.id}")
  click_testid("add-item-btn-#{@item2.id}")
  click_testid("add-item-btn-#{@item3.id}")
  
  # Verify all items in order
  within_testid('order-items-list') do
    assert_text @item1.name
    assert_text @item2.name
    assert_text @item3.name
  end
  
  # Verify item count
  within_testid('order-item-count') do
    assert_text '3'
  end
  
  # Verify total
  expected_total = @item1.price + @item2.price + @item3.price
  within_testid('order-total') do
    assert_text "$#{sprintf('%.2f', expected_total)}"
  end
end
```

#### 4.1 Remove Single Item
```ruby
test 'customer can remove item from order' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Add two items
  click_testid("add-item-btn-#{@item1.id}")
  click_testid("add-item-btn-#{@item2.id}")
  
  ordritem_id = Ordritem.last.id
  original_total = @item1.price + @item2.price
  
  # Remove second item
  click_testid("order-item-remove-#{ordritem_id}")
  
  # Verify item removed
  assert_no_selector("[data-testid='order-item-#{ordritem_id}']")
  
  # Verify total updated
  within_testid('order-total') do
    assert_text "$#{@item1.price}"
    assert_no_text "$#{sprintf('%.2f', original_total)}"
  end
  
  # Verify database
  assert_nil Ordritem.find_by(id: ordritem_id)
end
```

#### 5.1 Submit Valid Order
```ruby
test 'customer can submit order successfully' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Add items
  click_testid("add-item-btn-#{@item1.id}")
  click_testid("add-item-btn-#{@item2.id}")
  
  # Submit order
  click_testid('order-submit-btn')
  
  # Confirm if prompted
  if has_selector?('[data-testid="confirm-submit-btn"]')
    click_testid('confirm-submit-btn')
  end
  
  # Verify confirmation
  assert_testid('order-submitted-confirmation')
  assert_text 'submitted', wait: 5
  
  # Verify order status
  order = Ordr.last
  assert_equal 'ordered', order.status
  
  # Verify UI locked
  assert_no_selector('[data-testid="order-submit-btn"]')
end
```

#### 5.2 Submit Order Validation
```ruby
test 'cannot submit empty order' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Try to submit without items
  assert_no_selector('[data-testid="order-submit-btn"]')
  
  # OR if button exists but disabled
  if has_selector?('[data-testid="order-submit-btn"]')
    btn = find_testid('order-submit-btn')
    assert btn[:disabled] || btn[:class].include?('disabled')
  end
end
```

---

### 🟡 High Priority (Important)

#### 1.3 Order Persistence
```ruby
test 'order persists across page reloads' do
  visit smartmenu_path(@smartmenu.slug)
  click_testid("add-item-btn-#{@item1.id}")
  
  order_id = Ordr.last.id
  ordritem_id = Ordritem.last.id
  
  # Reload page
  visit current_path
  
  # Verify order still loaded
  assert_testid("order-item-#{ordritem_id}")
  assert_equal order_id, Ordr.last.id
end
```

#### 2.1 Add Customer Name
```ruby
test 'customer can add their name to order' do
  visit smartmenu_path(@smartmenu.slug)
  click_testid("add-item-btn-#{@item1.id}")
  
  # Open name modal
  click_testid('add-customer-name-btn')
  assert_testid('customer-name-modal')
  
  # Enter name
  fill_testid('customer-name-input', 'John Doe')
  click_testid('customer-name-submit-btn')
  
  # Verify name saved
  participant = Ordrparticipant.last
  assert_equal 'John Doe', participant.name
  
  # Verify name displays
  assert_text 'John Doe'
end
```

#### 3.4 Add Duplicate Item
```ruby
test 'adding same item twice increases quantity or creates separate items' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Add same item twice
  click_testid("add-item-btn-#{@item1.id}")
  click_testid("add-item-btn-#{@item1.id}")
  
  # Verify total doubled
  expected_total = @item1.price * 2
  within_testid('order-total') do
    assert_text "$#{sprintf('%.2f', expected_total)}"
  end
  
  # Verify item count
  within_testid('order-item-count') do
    assert_text '2'
  end
end
```

#### 4.2 Remove All Items
```ruby
test 'removing all items leaves order in opened state' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Add items
  click_testid("add-item-btn-#{@item1.id}")
  click_testid("add-item-btn-#{@item2.id}")
  
  order_id = Ordr.last.id
  
  # Remove all items
  Ordritem.where(ordr_id: order_id).each do |item|
    click_testid("order-item-remove-#{item.id}")
  end
  
  # Verify empty state
  assert_testid('order-summary-empty')
  
  # Verify order still exists
  order = Ordr.find(order_id)
  assert_equal 'opened', order.status
end
```

#### 4.3 Remove from Multi-Item Order
```ruby
test 'removing item from multi-item order updates correctly' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Add three items
  click_testid("add-item-btn-#{@item1.id}")  # $10
  click_testid("add-item-btn-#{@item2.id}")  # $15
  click_testid("add-item-btn-#{@item3.id}")  # $20
  
  item2_ordritem_id = Ordritem.where(menuitem: @item2).last.id
  
  # Remove middle item
  click_testid("order-item-remove-#{item2_ordritem_id}")
  
  # Verify correct total
  expected_total = @item1.price + @item3.price  # $30
  within_testid('order-total') do
    assert_text "$#{sprintf('%.2f', expected_total)}"
  end
  
  # Verify correct items remain
  assert_testid("order-item-#{Ordritem.where(menuitem: @item1).last.id}")
  assert_testid("order-item-#{Ordritem.where(menuitem: @item3).last.id}")
  assert_no_selector("[data-testid='order-item-#{item2_ordritem_id}']")
end
```

#### 5.3 Submit Confirmation
```ruby
test 'order submission shows confirmation message' do
  visit smartmenu_path(@smartmenu.slug)
  click_testid("add-item-btn-#{@item1.id}")
  
  click_testid('order-submit-btn')
  
  # Verify confirmation UI
  assert_testid('order-submitted-confirmation')
  assert_text 'Your order has been submitted'
  assert_text 'Thank you'
  
  # Verify status badge
  within_testid('order-status-badge') do
    assert_text 'Ordered'
  end
end
```

#### 6.1 Add to Submitted Order
```ruby
test 'customer can add items to submitted order' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Create and submit order
  click_testid("add-item-btn-#{@item1.id}")
  click_testid('order-submit-btn')
  
  order = Ordr.last
  assert_equal 'ordered', order.status
  
  # Add another item
  click_testid("add-item-btn-#{@item2.id}")
  
  # Verify item added
  assert_testid("order-item-#{Ordritem.last.id}")
  
  # Verify total updated
  expected_total = @item1.price + @item2.price
  within_testid('order-total') do
    assert_text "$#{sprintf('%.2f', expected_total)}"
  end
end
```

---

### 🟢 Medium Priority (Nice to Have)

#### 2.2 Update Customer Name
```ruby
test 'customer can update their name' do
  visit smartmenu_path(@smartmenu.slug)
  click_testid("add-item-btn-#{@item1.id}")
  
  # Add initial name
  click_testid('add-customer-name-btn')
  fill_testid('customer-name-input', 'John Doe')
  click_testid('customer-name-submit-btn')
  
  # Update name
  click_testid('edit-customer-name-btn')
  fill_testid('customer-name-input', 'Jane Smith')
  click_testid('customer-name-submit-btn')
  
  # Verify updated
  participant = Ordrparticipant.last
  assert_equal 'Jane Smith', participant.name
end
```

#### 6.2 Add During Preparation
```ruby
test 'adding item during preparation shows warning' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Create and submit order
  click_testid("add-item-btn-#{@item1.id}")
  click_testid('order-submit-btn')
  
  # Change status to preparing
  order = Ordr.last
  order.update!(status: 'preparing')
  
  # Try to add item
  visit current_path
  click_testid("add-item-btn-#{@item2.id}")
  
  # Verify warning shown
  assert_text 'Order is being prepared'
  # OR verify item added with confirmation
end
```

#### 6.3 Modify Existing Order Item
```ruby
test 'can modify quantity of existing order item' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Add item
  click_testid("add-item-btn-#{@item1.id}")
  ordritem = Ordritem.last
  
  # Submit order
  click_testid('order-submit-btn')
  
  # Modify quantity
  click_testid("edit-order-item-#{ordritem.id}")
  fill_testid('item-quantity-input', '3')
  click_testid('update-order-item-btn')
  
  # Verify updated
  ordritem.reload
  assert_equal 3, ordritem.quantity
  
  # Verify total
  expected_total = @item1.price * 3
  within_testid('order-total') do
    assert_text "$#{sprintf('%.2f', expected_total)}"
  end
end
```

---

## 🔧 Helper Methods

```ruby
# In application_system_test_case.rb

def visit_smartmenu_as_customer
  visit smartmenu_path(@smartmenu.slug)
  assert_testid('smartmenu-customer-view')
end

def visit_smartmenu_as_staff
  login_as(@user, scope: :user)
  visit smartmenu_path(@smartmenu.slug)
  assert_testid('smartmenu-staff-view')
end

def add_item_to_order(item)
  click_testid("add-item-btn-#{item.id}")
  sleep 0.5 # Allow time for order creation
end

def submit_current_order
  click_testid('order-submit-btn')
  if has_selector?('[data-testid="confirm-submit-btn"]')
    click_testid('confirm-submit-btn')
  end
  assert_testid('order-submitted-confirmation', wait: 5)
end

def verify_order_total(expected_amount)
  within_testid('order-total') do
    assert_text "$#{sprintf('%.2f', expected_amount)}"
  end
end

def verify_item_in_order(item_name)
  within_testid('order-items-list') do
    assert_text item_name
  end
end
```

---

## 📊 Test Coverage Matrix

| Feature Area | Customer | Staff | Total Tests |
|--------------|----------|-------|-------------|
| Order Creation | 3 | 2 | 5 |
| Customer Name | 2 | 2 | 4 |
| Adding Items | 4 | 3 | 7 |
| Removing Items | 3 | 2 | 5 |
| Order Submission | 3 | 2 | 5 |
| Modify Submitted | 2 | 2 | 4 |
| Edge Cases | 3 | 2 | 5 |
| **Total** | **20** | **15** | **35** |

**Plus:** 10 order state/persistence tests  
**Grand Total:** ~45 tests

---

**Reference Status:** 📋 Ready to Use  
**Last Updated:** November 15, 2024  
**Test Priority:** Use this for implementation order
