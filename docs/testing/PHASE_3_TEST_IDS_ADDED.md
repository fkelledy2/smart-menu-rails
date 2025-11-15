# Phase 3: Smartmenu Test IDs - Implementation Progress

## ✅ Test IDs Added (Step 1 Complete)

### Summary
- **Views Updated:** 6 files
- **Test IDs Added:** 20+
- **Status:** Core view test IDs complete ✅

---

## 📁 Files Modified

### 1. `app/views/smartmenus/show.html.erb`
**Purpose:** Main smartmenu container - differentiates customer vs staff views

| Test ID | Element | Purpose |
|---------|---------|---------|
| `smartmenu-customer-view` | Main container div | Identifies customer view |
| `smartmenu-staff-view` | Main container div | Identifies staff view |
| `menu-content-container` | Content wrapper | Main menu content area |

**Total:** 3 test IDs

---

### 2. `app/views/smartmenus/_showMenuContentCustomer.erb`
**Purpose:** Customer-facing menu display with sections and items

| Test ID | Element | Purpose |
|---------|---------|---------|
| `menu-sections-container` | Container div | Wraps all menu sections |
| `menu-section-{id}` | Section anchor div | Individual section marker |
| `menu-section-title-{id}` | Section title span | Section heading (2 locations for image/no-image paths) |
| `menu-items-row-{id}` | Items row div | Container for section's menu items |

**Total:** 4 test ID patterns (dynamically repeated per section)

---

### 3. `app/views/smartmenus/_showMenuitemHorizontal.erb`
**Purpose:** Individual menu item card display

| Test ID | Element | Purpose |
|---------|---------|---------|
| `menu-item-{id}` | Item card div | Individual menu item container |

**Total:** 1 test ID pattern (repeated per item)

---

### 4. `app/views/smartmenus/_showMenuitemHorizontalActionBar.erb`
**Purpose:** Add to order buttons and item actions

| Test ID | Element | Purpose |
|---------|---------|---------|
| `add-item-btn-{id}` | Add button | Add item to order (3 locale variations) |

**Total:** 1 test ID pattern (repeated per item, 3 code paths)

---

### 5. `app/views/smartmenus/_orderCustomer.erb`
**Purpose:** Order action buttons and customer name management

| Test ID | Element | Purpose |
|---------|---------|---------|
| `order-action-buttons` | Button group div | Container for all order actions |
| `add-customer-name-btn` | Button | Add customer name (when no name) |
| `edit-customer-name-btn` | Button | Edit existing customer name |
| `view-order-btn` | Button | Open order modal (multiple locations) |
| `request-bill-btn` | Button | Request bill from staff |
| `order-fab-container` | FAB div | Floating action button container |
| `order-fab-btn` | FAB button | Floating cart button (mobile) |
| `order-item-count-badge` | Badge span | Item count on FAB |

**Total:** 8 test IDs

---

### 6. `app/views/smartmenus/_showModals.erb`
**Purpose:** Order viewing modal and order management

| Test ID | Element | Purpose |
|---------|---------|---------|
| `view-order-modal` | Modal div | Main order modal container |
| `order-modal-body` | Modal body div | Order modal content area |
| `order-items-selected-section` | Section div | "Selected" items header |
| `order-item-{id}` | Item row div | Individual order item in cart |
| `remove-order-item-{id}-btn` | Button | Remove item from order |
| `order-total-row` | Total row div | Order total section |
| `order-total-amount` | Amount span | Total price display |
| `submit-order-btn` | Submit button | Submit order to kitchen |

**Total:** 8 test IDs (4 static + 4 dynamic patterns)

---

## 📊 Test ID Coverage Matrix

| Feature Area | Test IDs | Status |
|--------------|----------|--------|
| **View Identification** | 2 | ✅ Complete |
| **Menu Structure** | 4 patterns | ✅ Complete |
| **Menu Items** | 2 patterns | ✅ Complete |
| **Order Actions** | 8 | ✅ Complete |
| **Order Modal** | 8 | ✅ Complete |
| **Customer Name** | 2 | ✅ Complete |
| **Order Management** | 3 patterns | ✅ Complete |

---

## 🎯 Test ID Usage Examples

### Identifying View Type
```ruby
# Customer view
assert_testid('smartmenu-customer-view')

# Staff view  
assert_testid('smartmenu-staff-view')
```

### Finding Menu Elements
```ruby
# Menu section
assert_testid("menu-section-#{section.id}")
assert_testid("menu-section-title-#{section.id}")

# Menu item
assert_testid("menu-item-#{item.id}")
click_testid("add-item-btn-#{item.id}")
```

### Managing Orders
```ruby
# View order
click_testid('view-order-btn')
# or from FAB
click_testid('order-fab-btn')

# Submit order
within_testid('view-order-modal') do
  click_testid('submit-order-btn')
end

# Remove item
click_testid("remove-order-item-#{ordritem.id}-btn")
```

### Customer Name
```ruby
# Add name
click_testid('add-customer-name-btn')

# Edit name
click_testid('edit-customer-name-btn')
```

### Verifying Order Details
```ruby
# Check order total
within_testid('order-total-amount') do
  assert_text '$25.99'
end

# Verify item in order
assert_testid("order-item-#{ordritem.id}")

# Count items
badge = find_testid('order-item-count-badge')
assert_equal '3', badge.text
```

---

## 🚧 Not Yet Implemented (Future Steps)

### Customer Name Modal
**File:** `app/views/smartmenus/_showModals.erb` (addNameToParticipantModal section)

Needed test IDs:
- `customer-name-modal` - Modal container
- `customer-name-input` - Name input field
- `customer-name-submit-btn` - Submit button
- `customer-name-cancel-btn` - Cancel button

### Add Item Modal
**File:** `app/views/smartmenus/_showModals.erb` (addItemToOrderModal section)

Needed test IDs:
- `add-item-modal` - Modal container
- `item-details-name` - Item name display
- `item-details-description` - Item description
- `item-details-price` - Item price
- `item-quantity-input` - Quantity field
- `item-add-to-order-btn` - Add button

### Order Status Indicators
**Location:** Various throughout smartmenu views

Needed test IDs:
- `order-status-badge` - Status display
- `order-status-message` - Status message
- `order-submitted-confirmation` - Confirmation message

### Staff View Differences
**File:** `app/views/smartmenus/_showMenuContentStaff.erb`

Needed test IDs:
- `staff-controls` - Staff-specific controls
- Similar structure to customer view

---

## 📝 Next Steps

### Immediate (This Session)
1. ✅ ~~Add test IDs to core views~~
2. ⏳ **Create test fixtures** for smartmenu testing
3. ⏳ **Begin implementing customer ordering tests**

### Short Term (Next Session)
4. Add missing test IDs to modals
5. Add test IDs to staff-specific view
6. Complete customer ordering tests
7. Implement staff ordering tests

### Medium Term
8. Implement order state tests
9. Debug and optimize
10. Update test runner script

---

## 🎉 Achievements

### What's Ready for Testing
With the test IDs added so far, we can now test:

✅ **Customer View Access**
- Verify customer view loads
- Verify correct view type displayed

✅ **Menu Browsing**
- Navigate through menu sections
- View menu items
- See item details

✅ **Adding Items to Order**
- Click add item buttons
- Items appear in order

✅ **Order Management**
- View order modal
- See order items
- Check order total
- Remove items from order

✅ **Order Submission**
- Submit order button
- (Needs modal test IDs for full flow)

✅ **Customer Name Management**
- Add name button
- Edit name button
- (Needs modal test IDs for full flow)

### What Needs More Work
⏳ **Detailed Item Configuration**
- Item quantity selection in modal
- Size/variation selection
- (Needs add item modal test IDs)

⏳ **Order Status Tracking**
- Status badges
- Confirmation messages
- (Needs status display test IDs)

⏳ **Staff-Specific Features**
- Staff view elements
- Staff-only controls
- (Needs staff view test IDs)

---

## 📈 Progress Tracker

| Milestone | Status | Completion |
|-----------|--------|------------|
| Core view test IDs | ✅ Complete | 100% |
| Modal test IDs | ⏳ Partial | 50% |
| Staff view test IDs | ⏳ Pending | 0% |
| Test fixtures | ⏳ In Progress | 0% |
| Customer tests | ⏳ Pending | 0% |
| Staff tests | ⏳ Pending | 0% |
| State tests | ⏳ Pending | 0% |

**Overall Phase 3 Progress:** ~15% complete

---

**Last Updated:** November 15, 2024  
**Status:** Test IDs foundation complete, ready for test implementation  
**Next Action:** Create test fixtures for smartmenu ordering
