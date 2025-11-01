# Complex Model Validations Testing Plan
## Smart Menu Rails Application

**Created**: November 1, 2025  
**Status**: 🚧 **IN PROGRESS**  
**Priority**: HIGH  

---

## 🎯 **Objective**

Implement comprehensive validation testing for models with complex business rules, edge cases, and conditional validations to ensure data integrity and business logic correctness.

---

## 📊 **Current State Analysis**

### **Existing Model Test Coverage**
- ✅ **Basic model tests**: 57/57 models have basic tests
- ✅ **Association testing**: All relationships validated
- ❌ **Complex validations**: Limited coverage of edge cases and business rules
- ❌ **Conditional validations**: Not systematically tested
- ❌ **Custom validators**: Minimal coverage

### **Models with Complex Validations Identified**

#### **Tier 1: Critical Business Models** (High Priority)
1. **Menuitem** - Core product model with pricing, inventory, and business rules
2. **Ordr** - Order state machine with complex transitions
3. **User** - Authentication, authorization, and onboarding logic
4. **Restaurant** - Multi-tenant root model with business rules
5. **Menu** - Menu management with status and visibility rules

#### **Tier 2: Important Supporting Models** (Medium Priority)
6. **Inventory** - Stock management with numerical constraints
7. **Employee** - Role-based access with status management
8. **PerformanceMetric** - Monitoring with range validations
9. **HeroImage** - URL validation and sequencing
10. **PushSubscription** - Unique endpoint validation

#### **Tier 3: Supporting Models** (Lower Priority)
11. **OcrMenuImport** - State machine validation
12. **Announcement** - Type and date validations
13. **UserSession** - Status and uniqueness validation
14. **SlowQuery** - Performance monitoring validation
15. **MemoryMetric** - Numerical validation

---

## 🏗️ **Implementation Strategy**

### **Phase 1: Critical Business Models** (Priority 1)

#### **1. Menuitem Validation Tests**
**File**: `test/models/menuitem_test.rb` (enhance existing)

**Validation Coverage**:
- ✅ **Presence validations**
  - `name` must be present
  - `itemtype` must be present
  - `status` must be present
  - `preptime` must be present
  - `price` must be present
  - `calories` must be present

- ✅ **Numericality validations**
  - `preptime` must be integer
  - `price` must be float
  - `calories` must be integer
  - `price` must be >= 0
  - `preptime` must be >= 0
  - `calories` must be >= 0

- ✅ **Edge cases**
  - Zero price items (free items)
  - Maximum price boundary
  - Maximum prep time
  - Maximum calories
  - Negative values rejection
  - Non-numeric values rejection
  - Decimal prep time rejection
  - Integer price rejection (must be float)

- ✅ **Business rules**
  - Status transitions
  - Inventory relationship
  - Image attachment validation
  - Localization handling

**Estimated**: 25-30 new tests

#### **2. Ordr Validation Tests**
**File**: `test/models/ordr_test.rb` (enhance existing)

**Validation Coverage**:
- ✅ **State machine validations**
  - Valid state transitions
  - Invalid state transitions
  - Initial state (opened)
  - Terminal states (closed, paid)

- ✅ **Association validations**
  - Required associations
  - Optional associations
  - Cascade behavior

- ✅ **Business rules**
  - Order total calculation
  - Status change broadcasting
  - Item cascade on status change
  - Bill request conditions
  - Payment conditions

- ✅ **Edge cases**
  - Empty orders
  - Orders with deleted items
  - Concurrent status changes
  - Invalid state transitions

**Estimated**: 20-25 new tests

#### **3. User Validation Tests**
**File**: `test/models/user_test.rb` (enhance existing)

**Validation Coverage**:
- ✅ **Devise validations**
  - Email presence
  - Email format
  - Email uniqueness
  - Password presence
  - Password length
  - Password confirmation

- ✅ **Business rules**
  - Default plan assignment
  - Onboarding session creation
  - Onboarding completion check
  - Onboarding progress calculation

- ✅ **Edge cases**
  - Invalid email formats
  - Duplicate emails
  - Short passwords
  - Long passwords
  - Special characters in passwords
  - Unicode in names

**Estimated**: 20-25 new tests

#### **4. Restaurant Validation Tests**
**File**: `test/models/restaurant_test.rb` (enhance existing)

**Validation Coverage**:
- ✅ **Presence validations**
  - `name` must be present
  - `status` must be present

- ✅ **Business rules**
  - Multi-tenant isolation
  - User ownership
  - Menu relationships
  - Employee relationships
  - Localization handling

- ✅ **Edge cases**
  - Long restaurant names
  - Special characters in names
  - Unicode in addresses
  - Invalid status values

**Estimated**: 15-20 new tests

#### **5. Menu Validation Tests**
**File**: `test/models/menu_test.rb` (enhance existing)

**Validation Coverage**:
- ✅ **Presence validations**
  - `name` must be present
  - `status` must be present

- ✅ **Business rules**
  - Restaurant relationship
  - Section relationships
  - Item relationships
  - Status transitions
  - Cache invalidation

- ✅ **Edge cases**
  - Empty menus
  - Menus with no sections
  - Menus with no items
  - Status changes

**Estimated**: 15-20 new tests

---

### **Phase 2: Supporting Models** (Priority 2)

#### **6. Inventory Validation Tests**
**File**: `test/models/inventory_test.rb` (enhance existing)

**Validation Coverage**:
- ✅ **Numericality validations**
  - `startinginventory` must be integer
  - `currentinventory` must be integer
  - `resethour` must be integer
  - All must be >= 0

- ✅ **Business rules**
  - Inventory depletion
  - Inventory reset
  - Stock tracking

- ✅ **Edge cases**
  - Zero inventory
  - Negative inventory rejection
  - Large inventory numbers
  - Invalid reset hours

**Estimated**: 15-20 new tests

#### **7. Employee Validation Tests**
**File**: `test/models/employee_test.rb` (enhance existing)

**Validation Coverage**:
- ✅ **Presence validations**
  - `name` must be present
  - `eid` must be present
  - `role` must be present
  - `status` must be present

- ✅ **Enum validations**
  - Valid role values
  - Valid status values

- ✅ **Business rules**
  - Role-based permissions
  - Status transitions

**Estimated**: 15-20 new tests

#### **8. PerformanceMetric Validation Tests**
**File**: `test/models/performance_metric_test.rb` (enhance existing)

**Validation Coverage**:
- ✅ **Presence validations**
  - `endpoint` must be present
  - `response_time` must be present
  - `status_code` must be present
  - `timestamp` must be present

- ✅ **Numericality validations**
  - `response_time` must be > 0
  - `status_code` must be in range 100-599

- ✅ **Edge cases**
  - Zero response time rejection
  - Negative response time rejection
  - Invalid status codes
  - Future timestamps

**Estimated**: 15-20 new tests

#### **9. HeroImage Validation Tests**
**File**: `test/models/hero_image_test.rb` (enhance existing)

**Validation Coverage**:
- ✅ **Presence validations**
  - `image_url` must be present
  - `status` must be present

- ✅ **Format validations**
  - `image_url` must be valid URL
  - HTTP/HTTPS only

- ✅ **Numericality validations**
  - `sequence` must be integer >= 0

- ✅ **Edge cases**
  - Invalid URL formats
  - Non-HTTP URLs
  - Negative sequence
  - Duplicate sequences

**Estimated**: 15-20 new tests

#### **10. PushSubscription Validation Tests**
**File**: `test/models/push_subscription_test.rb` (enhance existing)

**Validation Coverage**:
- ✅ **Presence validations**
  - `endpoint` must be present
  - `p256dh_key` must be present
  - `auth_key` must be present

- ✅ **Uniqueness validations**
  - `endpoint` must be unique

- ✅ **Edge cases**
  - Duplicate endpoints
  - Invalid keys
  - Long keys

**Estimated**: 10-15 new tests

---

### **Phase 3: Additional Models** (Priority 3)

#### **11-15. Remaining Models**
- OcrMenuImport
- Announcement
- UserSession
- SlowQuery
- MemoryMetric

**Estimated**: 10-15 tests each (50-75 total)

---

## 📈 **Success Criteria**

### **Coverage Targets**
- ✅ **Tier 1 Models**: 100% validation coverage (all edge cases tested)
- ✅ **Tier 2 Models**: 90%+ validation coverage
- ✅ **Tier 3 Models**: 80%+ validation coverage

### **Test Quality Metrics**
- ✅ **200+ new validation tests** - Comprehensive validation coverage
- ✅ **0 test failures** - All tests passing
- ✅ **Edge case coverage** - All boundary conditions tested
- ✅ **Business rule validation** - All business logic tested

### **Model Coverage**
- ✅ **Menuitem**: 100% validation coverage
- ✅ **Ordr**: 100% validation coverage
- ✅ **User**: 100% validation coverage
- ✅ **Restaurant**: 100% validation coverage
- ✅ **Menu**: 100% validation coverage
- ✅ **10+ supporting models**: 80%+ validation coverage

---

## 🚧 **Implementation Timeline**

### **Week 1: Critical Models** (Days 1-3)
- Day 1: Menuitem validation tests (25-30 tests)
- Day 2: Ordr and User validation tests (40-50 tests)
- Day 3: Restaurant and Menu validation tests (30-40 tests)

### **Week 2: Supporting Models** (Days 4-5)
- Day 4: Inventory, Employee, PerformanceMetric tests (45-60 tests)
- Day 5: HeroImage, PushSubscription tests (25-35 tests)

### **Week 3: Additional Models** (Days 6-7)
- Day 6: Remaining Tier 3 models (50-75 tests)
- Day 7: Documentation and summary

**Total Estimated Time**: 7 days (1.5 weeks)

---

## 💡 **Testing Best Practices**

### **1. Test Structure**
```ruby
describe 'validations' do
  describe 'presence validations' do
    it 'requires name' do
      model = Model.new(name: nil)
      expect(model.valid?).to be false
      expect(model.errors[:name]).to include("can't be blank")
    end
  end

  describe 'numericality validations' do
    it 'requires price to be a number' do
      model = Model.new(price: 'abc')
      expect(model.valid?).to be false
      expect(model.errors[:price]).to include('is not a number')
    end
  end

  describe 'edge cases' do
    it 'rejects negative prices' do
      model = Model.new(price: -1.0)
      expect(model.valid?).to be false
      expect(model.errors[:price]).to include('must be greater than or equal to 0')
    end
  end
end
```

### **2. Edge Case Testing**
- **Boundary values**: Test 0, -1, max values
- **Invalid types**: Test strings for numbers, etc.
- **Null/nil values**: Test required fields
- **Empty strings**: Test string validations
- **Unicode**: Test special characters
- **Long values**: Test length limits

### **3. Business Rule Testing**
- **State transitions**: Test valid and invalid transitions
- **Conditional validations**: Test conditions
- **Custom validators**: Test custom validation logic
- **Callbacks**: Test before/after validation hooks

---

## 🔧 **Technical Considerations**

### **Challenges**
1. **Existing tests**: Need to enhance, not replace
2. **Fixtures**: May need additional test data
3. **Complex validations**: Conditional logic requires careful testing
4. **State machines**: AASM transitions need thorough testing
5. **Database constraints**: Some validations at DB level

### **Solutions**
1. **Add to existing files**: Enhance current test files
2. **Create fixtures**: Add necessary test data
3. **Test all paths**: Cover all conditional branches
4. **Test transitions**: Validate all state changes
5. **Test both levels**: Validate at model and DB level

---

## 📊 **Expected Benefits**

### **Data Quality**
- ✅ **Prevent invalid data** - Comprehensive validation prevents bad data
- ✅ **Catch edge cases** - Boundary testing finds hidden bugs
- ✅ **Business rule enforcement** - Logic validation ensures correctness
- ✅ **Database integrity** - Validation prevents constraint violations

### **Development Quality**
- ✅ **Confident refactoring** - Tests catch breaking changes
- ✅ **Clear documentation** - Tests document validation rules
- ✅ **Faster debugging** - Tests pinpoint validation issues
- ✅ **Better code design** - Testable validations are better validations

### **Business Impact**
- ✅ **Higher reliability** - Fewer data-related bugs
- ✅ **Better UX** - Clear validation messages
- ✅ **Reduced support** - Fewer invalid data issues
- ✅ **Compliance** - Validation ensures business rules

---

## 🔗 **Related Documentation**
- [Model Testing Enhancement Summary](model-testing-enhancement-summary.md)
- [Development Roadmap](../development_roadmap.md)
- [Testing TODO](todo.md)

---

## 🚀 **Next Steps**

1. **Review and approve plan** - Get team buy-in
2. **Start with Menuitem** - Critical model first
3. **Iterate through tiers** - One model at a time
4. **Monitor coverage** - Track progress
5. **Document learnings** - Capture best practices
6. **Update roadmap** - Mark task complete

---

**Status**: 🚧 **READY TO START**  
**Priority**: 🔥 **HIGH**  
**Estimated Effort**: 7 days  
**Expected Tests**: 200+

🎯 **Let's build comprehensive validation testing!**
