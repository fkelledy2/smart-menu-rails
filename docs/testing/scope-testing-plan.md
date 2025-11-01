# Scope Testing Implementation Plan
## Smart Menu Rails Application

**Created**: November 1, 2025  
**Status**: 🚧 **IN PROGRESS**  
**Priority**: HIGH  

---

## 🎯 **Objective**

Implement comprehensive testing for ActiveRecord scopes across critical models to ensure query methods return correct results, maintain performance, and prevent regression bugs in data filtering logic.

---

## 📊 **Current State Analysis**

### **Models with Scopes Identified**

#### **1. Menu Model** (3 scopes)
- `scope :with_availabilities_and_sections` - Eager loading for N+1 prevention
- `scope :for_customer_display` - Active, non-archived menus with associations
- `scope :for_management_display` - Non-archived menus with associations

**Business Impact**: HIGH - Customer-facing menu display and management interface

#### **2. Ordr Model** (2 scopes)
- `scope :with_complete_items` - Eager loading for order details
- `scope :for_restaurant_dashboard` - Restaurant-specific orders with sorting

**Business Impact**: CRITICAL - Order management and kitchen dashboard

#### **3. DietaryRestrictable Concern** (5 scopes)
- `scope :vegetarian` - Vegetarian items
- `scope :vegan` - Vegan items
- `scope :gluten_free` - Gluten-free items
- `scope :dairy_free` - Dairy-free items
- `scope :with_dietary_restrictions` - Items with any dietary restrictions
- **Class method**: `matching_dietary_restrictions(restrictions)` - Complex filtering

**Business Impact**: HIGH - Customer dietary filtering, critical for safety

#### **4. OcrMenuImport Model** (5 scopes)
- `scope :recent` - Ordered by created_at desc
- `scope :pending` - Pending imports
- `scope :processing` - Currently processing
- `scope :completed` - Completed imports
- `scope :failed` - Failed imports

**Business Impact**: MEDIUM - OCR import workflow management

#### **5. SoftDeletable Concern** (4 scopes)
- `scope :active` - Non-deleted records
- `scope :deleted` - Soft-deleted records
- `scope :with_deleted` - All records including deleted
- `scope :only_deleted` - Only deleted records

**Business Impact**: MEDIUM - Soft delete functionality across models

#### **6. MenuPerformanceMv Model** (7 scopes)
- `scope :by_restaurant` - Filter by restaurant
- `scope :by_menu` - Filter by menu
- `scope :top_revenue` - Highest revenue items
- `scope :top_ordered` - Most ordered items
- `scope :low_performers` - Low-performing items
- `scope :recent_period` - Recent time period
- `scope :with_minimum_orders` - Minimum order threshold

**Business Impact**: HIGH - Analytics and reporting

#### **7. RestaurantAnalyticsMv Model** (4 scopes)
- `scope :by_restaurant` - Filter by restaurant
- `scope :recent_period` - Recent time period
- `scope :with_minimum_revenue` - Revenue threshold
- `scope :active_restaurants` - Active restaurant analytics

**Business Impact**: HIGH - Restaurant performance tracking

#### **8. SystemAnalyticsMv Model** (5 scopes)
- `scope :recent` - Recent analytics
- `scope :by_metric_type` - Filter by metric type
- `scope :above_threshold` - Threshold filtering
- `scope :critical_metrics` - Critical system metrics
- `scope :performance_trends` - Performance trend analysis

**Business Impact**: MEDIUM - System monitoring and health

---

## 🎯 **Testing Strategy**

### **Phase 1: Critical Business Scopes** (Priority: HIGH)

Focus on scopes that directly impact customer experience, business operations, and data filtering.

#### **1.1 Menu Model Scope Tests**
**File**: `test/models/menu_test.rb` (enhance existing)

**Scopes to Test**:
- ✅ `with_availabilities_and_sections`
  - Test eager loading of associations
  - Verify no N+1 queries
  - Test with multiple menus
  
- ✅ `for_customer_display`
  - Test filters archived menus
  - Test filters inactive menus
  - Test includes associations
  - Test returns only active, non-archived
  
- ✅ `for_management_display`
  - Test includes archived menus
  - Test filters only archived=false
  - Test includes associations
  - Test returns all non-archived

**Test Count**: ~9 tests

#### **1.2 Ordr Model Scope Tests**
**File**: `test/models/ordr_test.rb` (enhance existing)

**Scopes to Test**:
- ✅ `with_complete_items`
  - Test eager loading of associations
  - Verify no N+1 queries
  - Test with multiple orders
  
- ✅ `for_restaurant_dashboard`
  - Test filters by restaurant_id
  - Test includes associations
  - Test orders by created_at desc
  - Test returns correct orders

**Test Count**: ~6 tests

#### **1.3 DietaryRestrictable Concern Scope Tests**
**File**: `test/models/concerns/dietary_restrictable_test.rb` (new)

**Scopes to Test**:
- ✅ `vegetarian`
  - Test returns only vegetarian items
  - Test excludes non-vegetarian
  
- ✅ `vegan`
  - Test returns only vegan items
  - Test excludes non-vegan
  
- ✅ `gluten_free`
  - Test returns only gluten-free items
  - Test excludes items with gluten
  
- ✅ `dairy_free`
  - Test returns only dairy-free items
  - Test excludes items with dairy
  
- ✅ `with_dietary_restrictions`
  - Test returns items with any restrictions
  - Test excludes items without restrictions
  
- ✅ `matching_dietary_restrictions(restrictions)`
  - Test single restriction matching
  - Test multiple restrictions (AND logic)
  - Test empty restrictions (returns all)
  - Test invalid restrictions (returns none)

**Test Count**: ~12 tests

---

### **Phase 2: Supporting Scopes** (Priority: MEDIUM)

#### **2.1 OcrMenuImport Model Scope Tests**
**File**: `test/models/ocr_menu_import_test.rb` (may need creation)

**Scopes to Test**:
- ✅ `recent` - Ordered by created_at desc
- ✅ `pending` - Status filtering
- ✅ `processing` - Status filtering
- ✅ `completed` - Status filtering
- ✅ `failed` - Status filtering

**Test Count**: ~5 tests

#### **2.2 SoftDeletable Concern Scope Tests**
**File**: `test/models/concerns/soft_deletable_test.rb` (may need creation)

**Scopes to Test**:
- ✅ `active` - Non-deleted records
- ✅ `deleted` - Soft-deleted records
- ✅ `with_deleted` - All records
- ✅ `only_deleted` - Only deleted records

**Test Count**: ~4 tests

---

### **Phase 3: Analytics Scopes** (Priority: MEDIUM)

#### **3.1 MenuPerformanceMv Scope Tests**
**File**: `test/models/menu_performance_mv_test.rb` (enhance existing)

**Scopes to Test**:
- ✅ `by_restaurant` - Restaurant filtering
- ✅ `by_menu` - Menu filtering
- ✅ `top_revenue` - Revenue sorting
- ✅ `top_ordered` - Order count sorting
- ✅ `low_performers` - Low performance filtering
- ✅ `recent_period` - Date range filtering
- ✅ `with_minimum_orders` - Order threshold

**Test Count**: ~7 tests

---

## 📋 **Implementation Plan**

### **Step 1: Setup Test Infrastructure** ✅
- [x] Identify all models with scopes
- [x] Categorize by business priority
- [x] Create testing plan document

### **Step 2: Menu Model Scope Tests** 🚧
- [ ] Test `with_availabilities_and_sections`
- [ ] Test `for_customer_display`
- [ ] Test `for_management_display`
- [ ] Verify all tests pass

### **Step 3: Ordr Model Scope Tests** 🚧
- [ ] Test `with_complete_items`
- [ ] Test `for_restaurant_dashboard`
- [ ] Verify all tests pass

### **Step 4: DietaryRestrictable Concern Scope Tests** 🚧
- [ ] Create concern test file
- [ ] Test all dietary scopes
- [ ] Test `matching_dietary_restrictions` class method
- [ ] Verify all tests pass

### **Step 5: OcrMenuImport Model Scope Tests** 🚧
- [ ] Test status-based scopes
- [ ] Test `recent` scope
- [ ] Verify all tests pass

### **Step 6: SoftDeletable Concern Scope Tests** 🚧
- [ ] Create concern test file
- [ ] Test all soft delete scopes
- [ ] Verify all tests pass

### **Step 7: Integration & Verification** 🚧
- [ ] Run full test suite
- [ ] Fix any failing tests
- [ ] Generate coverage report
- [ ] Update documentation

---

## 🧪 **Testing Patterns**

### **Pattern 1: Basic Scope Testing**
```ruby
test 'should return only active records' do
  active_record = Model.create!(name: 'Active', archived: false)
  archived_record = Model.create!(name: 'Archived', archived: true)
  
  results = Model.for_customer_display
  
  assert_includes results, active_record
  assert_not_includes results, archived_record
end
```

### **Pattern 2: Scope Chaining**
```ruby
test 'should chain scopes correctly' do
  menu1 = Menu.create!(restaurant: @restaurant, status: :active, archived: false)
  menu2 = Menu.create!(restaurant: @restaurant, status: :inactive, archived: false)
  
  results = Menu.for_customer_display
  
  assert_includes results, menu1
  assert_not_includes results, menu2
end
```

### **Pattern 3: Parameterized Scope Testing**
```ruby
test 'should filter by restaurant_id' do
  restaurant1 = restaurants(:one)
  restaurant2 = restaurants(:two)
  
  ordr1 = Ordr.create!(restaurant: restaurant1, menu: @menu, tablesetting: @tablesetting, gross: 0.0)
  ordr2 = Ordr.create!(restaurant: restaurant2, menu: @menu, tablesetting: @tablesetting, gross: 0.0)
  
  results = Ordr.for_restaurant_dashboard(restaurant1.id)
  
  assert_includes results, ordr1
  assert_not_includes results, ordr2
end
```

### **Pattern 4: Eager Loading Testing (N+1 Prevention)**
```ruby
test 'should eager load associations to prevent N+1' do
  menu = Menu.create!(restaurant: @restaurant, name: 'Test', status: :active)
  menu.menusections.create!(name: 'Section 1')
  menu.menuavailabilities.create!(day: 'monday')
  
  # Test that associations are loaded
  results = Menu.with_availabilities_and_sections
  
  # This should not trigger additional queries
  assert_queries(0) do
    results.each do |m|
      m.menusections.to_a
      m.menuavailabilities.to_a
    end
  end
end
```

### **Pattern 5: Complex Filtering Testing**
```ruby
test 'should match multiple dietary restrictions with AND logic' do
  vegan_item = Menuitem.create!(
    name: 'Vegan Salad',
    is_vegan: true,
    is_gluten_free: true,
    price: 10.0
  )
  
  vegetarian_item = Menuitem.create!(
    name: 'Vegetarian Pasta',
    is_vegetarian: true,
    is_vegan: false,
    price: 12.0
  )
  
  results = Menuitem.matching_dietary_restrictions(['vegan', 'gluten_free'])
  
  assert_includes results, vegan_item
  assert_not_includes results, vegetarian_item
end
```

### **Pattern 6: Ordering Testing**
```ruby
test 'should order by created_at desc' do
  old_import = OcrMenuImport.create!(name: 'Old', restaurant: @restaurant, created_at: 1.day.ago)
  new_import = OcrMenuImport.create!(name: 'New', restaurant: @restaurant, created_at: Time.current)
  
  results = OcrMenuImport.recent
  
  assert_equal new_import, results.first
  assert_equal old_import, results.last
end
```

---

## 🎯 **Success Criteria**

| Metric | Target | Status |
|--------|--------|--------|
| **Critical Models Tested** | 3+ | 🚧 **0/3** |
| **New Scope Tests** | 40+ | 🚧 **0/40** |
| **Test Success Rate** | 100% | 🚧 **TBD** |
| **Zero Errors** | Yes | 🚧 **TBD** |
| **Scope Coverage** | 100% | 🚧 **0%** |
| **Documentation** | Complete | 🚧 **IN PROGRESS** |

---

## 📈 **Expected Impact**

### **Data Integrity**
- ✅ Verify scopes return correct results
- ✅ Ensure filtering logic works correctly
- ✅ Prevent scope regression bugs
- ✅ Validate complex query logic

### **Business Logic**
- ✅ Verify customer-facing filters work
- ✅ Ensure dietary restrictions filter correctly
- ✅ Validate order dashboard queries
- ✅ Confirm analytics scopes accurate

### **Development Quality**
- ✅ Confident scope refactoring
- ✅ Clear scope documentation
- ✅ Faster scope debugging
- ✅ Better query design

---

## 💡 **Key Considerations**

### **Performance Testing**
- Test N+1 query prevention with eager loading
- Verify scope chaining doesn't cause performance issues
- Consider query count assertions

### **Edge Cases**
- Empty result sets
- Nil parameters
- Invalid parameters
- Scope chaining order

### **Database Transactions**
- Tests should be transactional
- Clean up test data properly
- Use fixtures or factories consistently

### **Maintainability**
- Clear test names describing scope behavior
- Group related scope tests together
- Document complex filtering logic
- Test both positive and negative cases

---

## 📋 **Files to Create/Modify**

### **Test Files to Enhance**
1. ✅ `test/models/menu_test.rb` - Add scope tests (existing file)
2. 🚧 `test/models/ordr_test.rb` - Add scope tests (existing file)
3. 🚧 `test/models/concerns/dietary_restrictable_test.rb` - Create new file
4. 🚧 `test/models/ocr_menu_import_test.rb` - May need creation
5. 🚧 `test/models/concerns/soft_deletable_test.rb` - May need creation
6. 🚧 `test/models/menu_performance_mv_test.rb` - Enhance existing

### **Documentation Files**
1. ✅ `docs/testing/scope-testing-plan.md` - This document
2. 🚧 `docs/testing/scope-testing-summary.md` - Completion summary (future)

---

## 🚀 **Next Steps**

1. **Implement Menu scope tests** - Start with existing test file
2. **Implement Ordr scope tests** - Add to existing test file
3. **Create DietaryRestrictable concern tests** - New test file
4. **Create OcrMenuImport scope tests** - May need new file
5. **Run test suite** - Verify all tests pass
6. **Generate coverage** - Measure scope coverage
7. **Update documentation** - Mark task complete

---

**Status**: 🚧 **PLAN COMPLETE - READY FOR IMPLEMENTATION**  
**Estimated Tests**: 40-45 new scope tests  
**Estimated Time**: 2-3 hours  
**Risk Level**: LOW (well-defined scope, clear patterns)

🎯 **Ready to proceed with implementation!**
