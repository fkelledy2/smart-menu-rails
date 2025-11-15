# Phase 2 Test Automation - Implementation Plan

## 🎯 Overview

This document outlines the plan for implementing the next 4 test automation areas:
1. Menu Items CRUD
2. Restaurant Details Form
3. Settings Pages
4. Staff Management

## ✅ Phase 1 Completed

- [x] Authentication (19 tests)
- [x] Import Flow (6 tests)
- [x] Restaurant Navigation (4 tests)
- [x] Menu Management (13 tests)
- **Total:** 42 tests, 100% passing

## 📋 Phase 2 Scope

### 1. Menu Items CRUD (Priority: High)

**Views to Update:**
- `app/views/menus/sections/_items_2025.html.erb`
- `app/views/menuitems/_form.html.erb` (if exists)

**Test IDs Needed:**
```
✓ menu-items-list
✓ menu-item-{id}
✓ add-item-btn
✓ edit-item-{id}-btn
✓ delete-item-{id}-btn
✓ item-name-input
✓ item-price-input
✓ item-description-input
```

**Tests to Create:**
- List displays items correctly
- Add new item
- Edit existing item
- Delete item
- Drag to reorder items
- Item form validation

**Estimated:** 8-10 tests

### 2. Restaurant Details Form (Priority: High)

**View:** `app/views/restaurants/sections/_details_2025.html.erb` ✓ (already open)

**Test IDs Needed:**
```
✓ restaurant-details-form
✓ restaurant-name-input
✓ restaurant-description-input
✓ restaurant-currency-select
✓ restaurant-phone-input
✓ restaurant-email-input
✓ restaurant-website-input
✓ save-details-btn (if not auto-save)
```

**Tests to Create:**
- Form displays current data
- Update restaurant name
- Update description
- Update contact info
- Form validation (required fields)
- Auto-save functionality

**Estimated:** 6-8 tests

### 3. Settings Pages (Priority: Medium)

**Views to Update:**
- `app/views/restaurants/sections/_settings_2025.html.erb`
- Other settings partials

**Test IDs Needed:**
```
✓ settings-card
✓ setting-{name}-toggle
✓ setting-{name}-input
✓ save-settings-btn
```

**Tests to Create:**
- Settings page displays
- Toggle settings on/off
- Update text settings
- Save settings
- Settings persist

**Estimated:** 5-6 tests

### 4. Staff Management (Priority: Medium)

**Views to Update:**
- `app/views/restaurants/sections/_staff_2025.html.erb`
- Staff form partials

**Test IDs Needed:**
```
✓ staff-list
✓ staff-member-{id}
✓ add-staff-btn
✓ edit-staff-{id}-btn
✓ delete-staff-{id}-btn
✓ staff-email-input
✓ staff-role-select
```

**Tests to Create:**
- Staff list displays
- Add new staff member
- Edit staff member
- Delete staff member
- Role assignment
- Staff permissions

**Estimated:** 6-8 tests

## 📊 Phase 2 Targets

### Test Count Goals
- Menu Items: 10 tests
- Restaurant Details: 8 tests
- Settings: 6 tests
- Staff Management: 8 tests
- **Total New Tests:** ~32 tests
- **Grand Total:** ~74 tests

### Test ID Goals
- Menu Items: 15 test IDs
- Restaurant Details: 10 test IDs
- Settings: 8 test IDs
- Staff Management: 12 test IDs
- **Total New Test IDs:** ~45 test IDs
- **Grand Total:** ~107 test IDs

## 🔄 Implementation Strategy

### Step-by-Step Approach

#### Week 1: Menu Items (Days 1-2)
1. ✓ Update `_items_2025.html.erb` with test IDs
2. ✓ Create item form test IDs
3. ✓ Write 10 menu item tests
4. ✓ Run and verify all pass

#### Week 1: Restaurant Details (Days 3-4)
1. ✓ Update `_details_2025.html.erb` with test IDs
2. ✓ Write 8 restaurant details tests
3. ✓ Test auto-save functionality
4. ✓ Run and verify all pass

#### Week 2: Settings (Days 1-2)
1. ✓ Update settings views with test IDs
2. ✓ Write 6 settings tests
3. ✓ Test toggle functionality
4. ✓ Run and verify all pass

#### Week 2: Staff Management (Days 3-4)
1. ✓ Update staff views with test IDs
2. ✓ Write 8 staff management tests
3. ✓ Test role assignments
4. ✓ Run and verify all pass

## 🎯 Quick Start Template

### For Each New Test File

```ruby
require 'application_system_test_case'

class [FeatureName]Test < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user) if @restaurant.user != @user
    
    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  # Tests go here
end
```

### Test ID Pattern

```erb
<!-- In Views -->
<div data-testid="element-name">
<%= link_to path, data: { testid: 'action-btn' } %>
<%= f.text_field :field, data: { testid: 'field-input' } %>
```

```ruby
# In Tests
assert_testid('element-name')
click_testid('action-btn')
fill_testid('field-input', 'value')
```

## 📈 Success Criteria

### Phase 2 Complete When:
- [ ] All 4 areas have test IDs
- [ ] ~32 new tests created
- [ ] 100% pass rate maintained
- [ ] Documentation updated
- [ ] Execution time < 90 seconds
- [ ] Code coverage > 50%

## 🚀 Expected Outcomes

### After Phase 2:
- **Total Tests:** ~74
- **Total Test IDs:** ~107
- **Coverage:** All critical CRUD operations
- **Execution Time:** ~60-90 seconds
- **Pass Rate:** 100%

## 📚 Documentation Updates Needed

- [ ] Update COMPLETE_TEST_SUMMARY.md
- [ ] Update IMPLEMENTATION_CHECKLIST.md
- [ ] Create PHASE_2_SUMMARY.md
- [ ] Update test count in README (if exists)

## 💡 Notes

### Key Considerations

1. **Auto-Save Forms** - Test that changes persist without submit
2. **Validation** - Test both client and server-side validation
3. **Permissions** - Test role-based access where applicable
4. **Data Cleanup** - Always clean up test data
5. **Turbo Frames** - Account for async updates

### Common Patterns

```ruby
# Create test data
item = MenuItem.create!(menu: @menu, name: 'Test Item', price: 10.00)

# Navigate to page
visit edit_restaurant_menu_path(@restaurant, @menu, section: 'items')

# Interact with elements
click_testid('add-item-btn')
fill_testid('item-name-input', 'New Item')

# Assert changes
assert_testid("menu-item-#{item.id}")
assert_text 'New Item'

# Cleanup
item.destroy
```

## ⚡ Quick Commands

```bash
# Run all new tests
bundle exec rails test test/system/menu_items_test.rb
bundle exec rails test test/system/restaurant_details_test.rb
bundle exec rails test test/system/settings_test.rb
bundle exec rails test test/system/staff_management_test.rb

# Run all tests
bundle exec rails test test/system/

# Run with coverage
COVERAGE=true bundle exec rails test test/system/
```

## 🎉 When Complete

Phase 2 will provide:
- ✅ Complete CRUD coverage for menu items
- ✅ Restaurant configuration testing
- ✅ Settings management testing
- ✅ Team management testing
- ✅ ~74 total tests covering all major workflows
- ✅ Rock-solid test foundation for future development

---

**Ready to Start:** Yes! Begin with Menu Items CRUD.  
**Estimated Duration:** 2 weeks  
**Complexity:** Medium  
**Priority:** High
