# Phase 3: Smartmenu Ordering Flow - Test Automation Plan

## 🎯 Objective

Implement comprehensive UI test automation for the **core customer-facing ordering experience** through smartmenus, covering both staff-assisted and direct customer flows.

---

## 📊 Overview

### Critical Business Flow
The smartmenu ordering system is the **primary revenue-generating feature** of the application. It enables:
- Customers to browse menus and place orders
- Staff to assist customers with ordering
- Real-time order management and updates

### User Paths to Test
1. **Staff Path** (Authenticated) - Staff helping customers
2. **Customer Path** (Unauthenticated) - Customers ordering directly

---

## 🔍 Scope Definition

### In Scope (Phase 3)
✅ **Core Ordering Flows:**
- Starting a new order
- Adding customer name to order
- Adding items to order
- Removing items from order  
- Updating item quantities
- Submitting orders
- Adding items to existing orders
- Order participant management

✅ **Both User Contexts:**
- Staff view (authenticated user)
- Customer view (unauthenticated)
- Staff preview of customer view

✅ **Core UI Elements:**
- Menu display and navigation
- Item selection and configuration
- Order summary/cart
- Order participant/name capture
- Order submission

### Out of Scope (Future Phases)
⏳ Payment processing (requires staff interaction)
⏳ Bill splitting
⏳ Tip calculation
⏳ Order history
⏳ Kitchen dashboard updates
⏳ Multi-language support details
⏳ Allergy filtering

---

## 📋 Test Scenarios

### 1. Starting an Order

#### 1.1 Customer Starts New Order (Unauthenticated)
**Path:** Customer scans QR code → Opens smartmenu → No existing order

**Test Steps:**
1. Visit smartmenu URL as unauthenticated user
2. Verify menu loads with customer view
3. Verify no existing order banner
4. Verify all menu sections display
5. Verify items are clickable
6. Add first item to cart
7. Verify new order is created automatically
8. Verify order participant is created with session ID
9. Verify order status is "opened"

**Expected Outcomes:**
- Menu displays correctly
- Order auto-created on first item add
- Session-based participant tracking works
- Order summary appears

#### 1.2 Staff Starts New Order (Authenticated)
**Path:** Staff logs in → Navigates to table smartmenu → No existing order

**Test Steps:**
1. Login as staff user
2. Navigate to smartmenu for specific table
3. Verify menu loads with staff view
4. Verify staff-specific controls visible
5. Add first item to order
6. Verify order created with employee as participant
7. Verify order linked to table
8. Verify order participant has role: staff

**Expected Outcomes:**
- Staff view displays correctly
- Order created with employee linkage
- Table association maintained
- Staff controls visible

#### 1.3 Reopening Existing Order
**Path:** User returns to smartmenu with existing open order

**Test Steps:**
1. Create an order with items
2. Leave the page (simulate customer leaving/returning)
3. Return to same smartmenu URL (same session)
4. Verify existing order is loaded
5. Verify order items are displayed
6. Verify order totals are correct

**Expected Outcomes:**
- Existing order found by session/table
- Order state persists
- Can continue adding items

---

### 2. Adding Customer Name to Order

#### 2.1 Add Name as Customer
**Path:** Customer adds items → Prompted for name → Enters name

**Test Steps:**
1. Start order as customer
2. Add item to order
3. Trigger name entry modal/form
4. Enter customer name
5. Submit name
6. Verify participant name updated
7. Verify name displays in order summary

**Expected Outcomes:**
- Name capture modal appears
- Name saves to order participant
- Name displays throughout session

#### 2.2 Staff Adds Customer Name
**Path:** Staff helping customer → Enters customer name

**Test Steps:**
1. Login as staff
2. Start order for table
3. Open name entry for participant
4. Enter customer name
5. Verify participant name saved
6. Verify name visible in order

**Expected Outcomes:**
- Staff can capture customer name
- Name associates with correct participant

---

### 3. Adding Items to Order

#### 3.1 Add Single Item - Simple
**Path:** Browse menu → Select item → Add to order

**Test Steps:**
1. Navigate to menu section
2. Click on menu item
3. Verify item details modal/panel opens
4. Click "Add to Order" button
5. Verify item appears in order summary
6. Verify order total updates
7. Verify item count badge updates

**Expected Outcomes:**
- Item added to order
- Ordritem record created
- Order total calculated correctly
- UI updates reflect change

#### 3.2 Add Item with Quantity
**Path:** Select item → Change quantity → Add to order

**Test Steps:**
1. Select menu item
2. Increase quantity to 3
3. Add to order
4. Verify 3 separate ordritems created OR
5. Verify 1 ordritem with quantity=3 created
6. Verify total reflects quantity

**Expected Outcomes:**
- Quantity selection works
- Correct number of items added
- Pricing multiplied correctly

#### 3.3 Add Multiple Different Items
**Path:** Add item A → Add item B → Add item C

**Test Steps:**
1. Add first item to order
2. Verify order summary shows 1 item
3. Add second different item
4. Verify order summary shows 2 items
5. Add third item
6. Verify order summary shows 3 items
7. Verify total = sum of all items

**Expected Outcomes:**
- Multiple items tracked separately
- Order summary updates each time
- Totals calculate correctly

#### 3.4 Add Same Item Multiple Times
**Path:** Add item → Add same item again

**Test Steps:**
1. Add item "Burger" to order
2. Navigate back to menu
3. Add "Burger" again
4. Verify behavior (2 separate items OR quantity increased)
5. Verify order total doubles

**Expected Outcomes:**
- System handles duplicate items correctly
- Total calculation accurate

---

### 4. Removing Items from Order

#### 4.1 Remove Single Item
**Path:** Order has items → Remove one item

**Test Steps:**
1. Create order with 3 items
2. Open order summary
3. Click remove/delete on middle item
4. Confirm removal if prompted
5. Verify item removed from order
6. Verify order total updated
7. Verify item count updated
8. Verify inventory adjusted (if tracked)

**Expected Outcomes:**
- Item removed from database
- UI updates immediately
- Totals recalculated
- No orphaned data

#### 4.2 Remove All Items
**Path:** Order has items → Remove each item

**Test Steps:**
1. Create order with 2 items
2. Remove first item
3. Verify order still exists
4. Remove second item
5. Verify order status remains "opened"
6. Verify empty state displayed
7. Verify order not deleted (stays open)

**Expected Outcomes:**
- Order persists even when empty
- Empty state messaging appropriate
- Can add items again

#### 4.3 Remove Item from Multi-Item Order
**Path:** Complex order → Remove specific item

**Test Steps:**
1. Create order: Item A ($10), Item B ($15), Item C ($20)
2. Verify total = $45
3. Remove Item B
4. Verify total = $30
5. Verify Item A and C remain
6. Verify correct items shown in summary

**Expected Outcomes:**
- Correct item removed
- Other items unaffected
- Calculations accurate

---

### 5. Submitting the Order

#### 5.1 Customer Submits Order
**Path:** Customer finalizes items → Submits order

**Test Steps:**
1. Create order with multiple items as customer
2. Review order summary
3. Click "Submit Order" / "Send to Kitchen"
4. Verify confirmation prompt
5. Confirm submission
6. Verify order status changes to "ordered"
7. Verify success message displayed
8. Verify order is locked from editing
9. Verify order appears in kitchen/staff view

**Expected Outcomes:**
- Order status updated
- Customer sees confirmation
- Order sent to kitchen
- UI reflects submitted state

#### 5.2 Staff Submits Order for Customer
**Path:** Staff finalizes customer order

**Test Steps:**
1. Login as staff
2. Create order for table with items
3. Click submit order button
4. Verify order status changes
5. Verify kitchen notification sent
6. Verify order details preserved

**Expected Outcomes:**
- Staff can submit orders
- Same workflow as customer
- Proper attribution maintained

#### 5.3 Submit Order Validation
**Path:** Attempt to submit invalid order

**Test Cases:**
- Empty order → Should show error
- Order without customer name → Handle appropriately
- Network failure → Show retry option

**Expected Outcomes:**
- Validation prevents invalid submissions
- Error messages are clear
- User can correct issues

---

### 6. Adding Items to Existing Order

#### 6.1 Add Item to Submitted Order (Before Kitchen Prep)
**Path:** Order submitted → Customer wants to add item

**Test Steps:**
1. Submit order with 2 items
2. Verify order status = "ordered"
3. Navigate back to menu
4. Select additional item
5. Add item to order
6. Verify item added to existing order
7. Verify order total updated
8. Verify order history/log shows addition

**Expected Outcomes:**
- Items can be added post-submission
- Order updated in real-time
- Kitchen notified of addition
- Audit trail maintained

#### 6.2 Add Item to Order in Preparation
**Path:** Kitchen preparing order → Customer adds item

**Test Steps:**
1. Create order with status "preparing"
2. Attempt to add new item
3. Verify behavior (allow with warning OR block)
4. If allowed, verify order updated
5. Verify kitchen receives update

**Expected Outcomes:**
- System handles in-progress orders
- Appropriate warnings shown
- State management correct

#### 6.3 Modify Existing Order Item
**Path:** Change quantity or details of submitted item

**Test Steps:**
1. Submit order with Item A (qty: 1)
2. Navigate to order edit
3. Change Item A quantity to 2
4. Verify update successful
5. Verify diff in order total

**Expected Outcomes:**
- Modifications tracked
- Kitchen updated
- History preserved

---

## 🎨 Test ID Strategy

### View Files to Enhance

#### 1. `/app/views/smartmenus/show.html.erb`
```ruby
# Main container
data-testid="smartmenu-container"
data-testid="smartmenu-customer-view"  # When customer
data-testid="smartmenu-staff-view"     # When staff
```

#### 2. `/app/views/smartmenus/_showMenuContentCustomer.erb`
```ruby
# Menu sections
data-testid="menu-section-<%= section.id %>"
data-testid="menu-section-title-<%= section.id %>"

# Menu items
data-testid="menu-item-<%= item.id %>"
data-testid="menu-item-name-<%= item.id %>"
data-testid="menu-item-price-<%= item.id %>"
data-testid="menu-item-image-<%= item.id %>"

# Actions
data-testid="add-item-btn-<%= item.id %>"
```

#### 3. `/app/views/smartmenus/_showMenuContentStaff.erb`
```ruby
# Same as customer view plus:
data-testid="staff-controls"
data-testid="staff-item-edit-<%= item.id %>"
```

#### 4. `/app/views/smartmenus/_showMenuitem.erb` (Item Details)
```ruby
# Item modal/panel
data-testid="item-details-modal"
data-testid="item-details-name"
data-testid="item-details-description"
data-testid="item-details-price"
data-testid="item-quantity-input"
data-testid="item-quantity-increase"
data-testid="item-quantity-decrease"
data-testid="item-add-to-order-btn"
data-testid="item-close-btn"
```

#### 5. Order Summary Component
```ruby
# Order sidebar/panel
data-testid="order-summary-container"
data-testid="order-summary-empty"  # When no items
data-testid="order-items-list"
data-testid="order-item-<%= ordritem.id %>"
data-testid="order-item-name-<%= ordritem.id %>"
data-testid="order-item-price-<%= ordritem.id %>"
data-testid="order-item-quantity-<%= ordritem.id %>"
data-testid="order-item-remove-<%= ordritem.id %>"

# Order totals
data-testid="order-subtotal"
data-testid="order-tax"
data-testid="order-total"
data-testid="order-item-count"

# Order actions
data-testid="order-submit-btn"
data-testid="order-clear-btn"
```

#### 6. Customer Name Modal
```ruby
data-testid="customer-name-modal"
data-testid="customer-name-input"
data-testid="customer-name-submit-btn"
data-testid="customer-name-cancel-btn"
```

#### 7. Order Status Display
```ruby
data-testid="order-status-badge"
data-testid="order-status-message"
data-testid="order-submitted-confirmation"
```

---

## 📝 Test File Structure

### New Test Files to Create

#### 1. `test/system/smartmenu_customer_ordering_test.rb`
**Focus:** Unauthenticated customer ordering flows

**Test Count:** ~20 tests
- Menu browsing (3 tests)
- Starting orders (2 tests)
- Adding items (5 tests)
- Removing items (3 tests)
- Quantity management (2 tests)
- Order submission (3 tests)
- Adding to existing order (2 tests)

#### 2. `test/system/smartmenu_staff_ordering_test.rb`
**Focus:** Authenticated staff ordering flows

**Test Count:** ~15 tests
- Staff view access (2 tests)
- Staff-assisted ordering (3 tests)
- Customer name capture (2 tests)
- Item management (4 tests)
- Order submission (2 tests)
- Staff-specific features (2 tests)

#### 3. `test/system/smartmenu_order_state_test.rb`
**Focus:** Order state management and persistence

**Test Count:** ~10 tests
- Order creation (2 tests)
- Order persistence across sessions (2 tests)
- Order status transitions (3 tests)
- Multiple participants (2 tests)
- Order locking/unlocking (1 test)

---

## 🔧 Implementation Approach

### Step 1: Add Test IDs to Views (Week 1)
1. `_showMenuContentCustomer.erb` - Core customer view
2. `_showMenuContentStaff.erb` - Staff view
3. `_showMenuitem.erb` - Item details
4. Order summary partial (identify and update)
5. Customer name modal
6. Order status components

**Estimated Test IDs:** ~40-50

### Step 2: Create Customer Ordering Tests (Week 1-2)
1. Setup test fixtures for:
   - Restaurant with active menu
   - Menu with sections and items
   - Table settings for ordering
2. Implement core flow tests
3. Add edge case tests
4. Verify all assertions pass

**Estimated Tests:** ~20

### Step 3: Create Staff Ordering Tests (Week 2)
1. Extend fixtures for staff/employee
2. Implement staff-specific tests
3. Test staff vs customer view differences
4. Test staff assistance workflows

**Estimated Tests:** ~15

### Step 4: Create Order State Tests (Week 2)
1. Test order lifecycle
2. Test session persistence
3. Test order status management
4. Test concurrent modifications

**Estimated Tests:** ~10

### Step 5: Integration and Refinement (Week 3)
1. Run full test suite
2. Fix any failures
3. Add additional edge cases discovered
4. Performance optimization
5. Documentation updates

---

## 🎯 Success Criteria

### Technical Metrics
- ✅ 45+ new system tests created
- ✅ 40-50 test IDs added
- ✅ 100% pass rate maintained
- ✅ <90 seconds total execution time
- ✅ Zero flaky tests
- ✅ All critical paths covered

### Business Metrics
- ✅ Core ordering flow protected
- ✅ Revenue-generating features validated
- ✅ Customer experience verified
- ✅ Staff workflow tested
- ✅ Order integrity ensured

### Coverage Goals
| Flow | Target Coverage |
|------|----------------|
| Menu browsing | 100% |
| Order creation | 100% |
| Item management | 100% |
| Order submission | 100% |
| State persistence | 95% |
| Error handling | 90% |

---

## 🚧 Known Challenges & Mitigation

### Challenge 1: Session Management in Tests
**Issue:** Session-based order tracking may be complex in test environment

**Mitigation:**
- Use Capybara session helpers
- Explicitly test session persistence
- Mock session IDs where needed
- Test both same-session and new-session scenarios

### Challenge 2: Real-Time Updates
**Issue:** Order updates may use ActionCable/WebSockets

**Mitigation:**
- Focus on HTTP request/response for now
- Test that updates trigger correctly
- Verify database state changes
- Future: Add WebSocket testing if needed

### Challenge 3: Customer vs Staff View Differences
**Issue:** Same URLs serve different content based on authentication

**Mitigation:**
- Use `?view=customer` parameter for staff preview
- Test both authenticated and unauthenticated paths
- Verify view switching works correctly
- Clear separation in test files

### Challenge 4: Order Status Transitions
**Issue:** Complex state machine with business rules

**Mitigation:**
- Test each valid transition
- Test invalid transitions blocked
- Verify side effects (notifications, etc.)
- Document state machine in tests

### Challenge 5: Inventory Management
**Issue:** Adding/removing items may affect inventory

**Mitigation:**
- Mock inventory service if needed
- Focus on order flow, not inventory logic
- Verify inventory hooks are called
- Don't test inventory business logic here

---

## 📊 Risk Assessment

### High Risk Areas
🔴 **Order submission workflow** - Core revenue path
🔴 **Item addition/removal** - Data integrity critical
🔴 **Order totals calculation** - Financial accuracy required

### Medium Risk Areas
🟡 **Session persistence** - User experience impact
🟡 **Customer name capture** - Data quality issue
🟡 **Staff vs customer views** - Feature parity important

### Low Risk Areas
🟢 **Menu display** - Static content mostly
🟢 **Order status badges** - UI-only changes
🟢 **Empty states** - Edge case scenarios

---

## 🔄 Integration with Existing Tests

### Relationship to Phase 1 & 2
- **Phase 1:** Authentication + Import → **Prerequisites for smartmenu**
- **Phase 2:** Restaurant/Menu Management → **Data setup for smartmenu**
- **Phase 3:** Smartmenu Ordering → **End-to-end customer experience**

### Test Data Dependencies
```ruby
# Phase 1 provides: User authentication
# Phase 2 provides: Restaurant, Menu, MenuItems
# Phase 3 needs: Tablesettings, Smartmenus

setup do
  @user = users(:one)
  @restaurant = restaurants(:one)
  @menu = menus(:one)  # From Phase 2
  
  # Phase 3 specific:
  @tablesetting = Tablesetting.create!(
    restaurant: @restaurant,
    name: 'Table 1',
    capacity: 4
  )
  
  @smartmenu = Smartmenu.create!(
    menu: @menu,
    restaurant: @restaurant,
    tablesetting: @tablesetting,
    slug: 'test-menu-slug'
  )
  
  # Create menu items
  @section = Menusection.create!(menu: @menu, name: 'Starters', status: 'active')
  @item1 = Menuitem.create!(
    menusection: @section,
    name: 'Salad',
    price: 8.99,
    status: 'active',
    calories: 150
  )
end
```

---

## 📈 Projected Timeline

### Week 1: Foundation
- Day 1-2: Add test IDs to customer view
- Day 3: Add test IDs to staff view + modals
- Day 4-5: Create basic test structure + fixtures

### Week 2: Core Implementation
- Day 1-2: Implement customer ordering tests
- Day 3-4: Implement staff ordering tests
- Day 5: Implement order state tests

### Week 3: Refinement
- Day 1-2: Debug and fix failing tests
- Day 3: Add edge cases and error scenarios
- Day 4: Performance optimization
- Day 5: Documentation and review

**Total Estimated Time:** 15 days

---

## 🎉 Expected Deliverables

### Code Deliverables
1. ✅ 6+ view files with test IDs
2. ✅ 3 new test files (~45 tests total)
3. ✅ Updated test fixtures
4. ✅ Helper methods for common scenarios

### Documentation Deliverables
1. ✅ This implementation plan
2. ✅ Test execution guide
3. ✅ Test ID reference sheet
4. ✅ Known issues and workarounds
5. ✅ Coverage report

### Process Deliverables
1. ✅ Updated `bin/run_ui_automation_tests` script
2. ✅ CI/CD integration updates
3. ✅ Team training materials

---

## 📚 Next Steps

1. **Review & Approve Plan** - Stakeholder sign-off
2. **Setup Test Environment** - Ensure dependencies ready
3. **Begin Implementation** - Start with test IDs
4. **Iterative Testing** - Test as you build
5. **Documentation** - Update as you go

---

**Plan Status:** 📋 Draft for Review  
**Priority:** 🔴 High (Core Business Functionality)  
**Estimated Effort:** 15 days  
**Dependencies:** Phases 1 & 2 Complete  
**Risk Level:** Medium-High (Complex flows, critical path)

---

**Next Action:** Await approval to begin Step 1 (Add Test IDs)
