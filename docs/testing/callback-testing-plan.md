# Callback Testing Implementation Plan
## Smart Menu Rails Application

**Created**: November 1, 2025  
**Status**: 🚧 **IN PROGRESS**  
**Priority**: HIGH  

---

## 🎯 **Objective**

Implement comprehensive testing for ActiveRecord callbacks (before_*, after_*, around_*) across critical models to ensure lifecycle hooks execute correctly, maintain data integrity, and prevent regression bugs.

---

## 📊 **Current State Analysis**

### **Models with Callbacks Identified**

#### **1. User Model** (3 callbacks)
- `before_validation :assign_default_plan, on: :create`
- `after_create :setup_onboarding_session`
- `after_update :invalidate_user_caches`

**Business Impact**: HIGH - User creation and plan assignment critical for onboarding

#### **2. Ordr Model** (3 callbacks)
- `after_create :broadcast_new_order`
- `after_update :broadcast_status_change, if: :saved_change_to_status?`
- `after_update :cascade_status_to_items, if: :saved_change_to_status?`

**Business Impact**: CRITICAL - Order lifecycle and kitchen communication

#### **3. Menu Model** (3 callbacks)
- `after_update :invalidate_menu_caches`
- `after_destroy :invalidate_menu_caches`
- `after_commit :enqueue_localization, on: :create`

**Business Impact**: HIGH - Menu management and localization

#### **4. Restaurant Model** (2 callbacks - disabled)
- `# after_update :invalidate_restaurant_caches` (commented out)
- `# after_destroy :invalidate_restaurant_caches` (commented out)

**Business Impact**: MEDIUM - Cache invalidation disabled for performance

#### **5. Menuitem Model** (2 callbacks - disabled)
- `# after_update :invalidate_menuitem_caches` (commented out)
- `# after_destroy :invalidate_menuitem_caches` (commented out)

**Business Impact**: MEDIUM - Cache invalidation disabled for performance

#### **6. Employee Model** (2 callbacks - disabled)
- `# after_update :invalidate_employee_caches` (commented out)
- `# after_destroy :invalidate_employee_caches` (commented out)

**Business Impact**: MEDIUM - Cache invalidation disabled for performance

#### **7. Announcement Model** (1 callback)
- `after_create_commit :notify_users`

**Business Impact**: MEDIUM - User notifications

#### **8. OcrMenuItem & OcrMenuSection** (callbacks in concerns)
- Various state machine callbacks

**Business Impact**: MEDIUM - OCR import workflow

---

## 🎯 **Testing Strategy**

### **Phase 1: Critical Business Callbacks** (Priority: HIGH)

Focus on callbacks that directly impact business operations, data integrity, and user experience.

#### **1.1 User Model Callbacks**
**File**: `test/models/user_test.rb`

**Callbacks to Test**:
- ✅ `before_validation :assign_default_plan, on: :create`
  - Test default plan assignment on new user
  - Test plan preservation when already set
  - Test behavior when no plans exist
  
- ✅ `after_create :setup_onboarding_session`
  - Test onboarding session creation
  - Test session initial status
  - Test association setup
  
- ⚠️ `after_update :invalidate_user_caches`
  - Test cache invalidation is called
  - Test cache service receives correct user_id
  - Mock cache service to verify behavior

**Test Count**: ~12 tests

#### **1.2 Ordr Model Callbacks**
**File**: `test/models/ordr_test.rb`

**Callbacks to Test**:
- ⚠️ `after_create :broadcast_new_order`
  - Test broadcast for kitchen-relevant statuses (ordered, preparing, ready)
  - Test no broadcast for non-kitchen statuses (opened, closed)
  - Mock KitchenBroadcastService
  
- ⚠️ `after_update :broadcast_status_change, if: :saved_change_to_status?`
  - Test broadcast on status change
  - Test no broadcast when status unchanged
  - Test broadcast only for kitchen-relevant statuses
  - Test old_status and new_status parameters
  
- ⚠️ `after_update :cascade_status_to_items, if: :saved_change_to_status?`
  - Test ordritems status updates when order status changes
  - Test no updates when status unchanged
  - Test multiple ordritems cascade
  - Test status synchronization

**Test Count**: ~15 tests

#### **1.3 Menu Model Callbacks**
**File**: `test/models/menu_test.rb`

**Callbacks to Test**:
- ⚠️ `after_update :invalidate_menu_caches`
  - Test cache invalidation on update
  - Mock cache service
  
- ⚠️ `after_destroy :invalidate_menu_caches`
  - Test cache invalidation on destroy
  - Mock cache service
  
- ⚠️ `after_commit :enqueue_localization, on: :create`
  - Test localization job enqueued on create
  - Test no job on update
  - Mock background job system

**Test Count**: ~9 tests

---

### **Phase 2: Supporting Callbacks** (Priority: MEDIUM)

#### **2.1 Announcement Model Callbacks**
**File**: `test/models/announcement_test.rb`

**Callbacks to Test**:
- ⚠️ `after_create_commit :notify_users`
  - Test user notification on announcement creation
  - Mock notification system

**Test Count**: ~3 tests

#### **2.2 Disabled Cache Callbacks** (Documentation Only)
**Models**: Restaurant, Menuitem, Employee

**Action**: Document why callbacks are disabled (performance optimization, background jobs)
**Test Count**: 0 tests (callbacks disabled intentionally)

---

## 📋 **Implementation Plan**

### **Step 1: Setup Test Infrastructure** ✅
- [x] Identify all models with callbacks
- [x] Categorize by business priority
- [x] Create testing plan document

### **Step 2: User Model Callback Tests** 🚧
- [ ] Test `before_validation :assign_default_plan`
- [ ] Test `after_create :setup_onboarding_session`
- [ ] Test `after_update :invalidate_user_caches`
- [ ] Verify all tests pass

### **Step 3: Ordr Model Callback Tests** 🚧
- [ ] Test `after_create :broadcast_new_order`
- [ ] Test `after_update :broadcast_status_change`
- [ ] Test `after_update :cascade_status_to_items`
- [ ] Verify all tests pass

### **Step 4: Menu Model Callback Tests** 🚧
- [ ] Test `after_update :invalidate_menu_caches`
- [ ] Test `after_destroy :invalidate_menu_caches`
- [ ] Test `after_commit :enqueue_localization`
- [ ] Verify all tests pass

### **Step 5: Announcement Model Callback Tests** 🚧
- [ ] Test `after_create_commit :notify_users`
- [ ] Verify all tests pass

### **Step 6: Integration & Verification** 🚧
- [ ] Run full test suite
- [ ] Fix any failing tests
- [ ] Generate coverage report
- [ ] Update documentation

---

## 🧪 **Testing Patterns**

### **Pattern 1: before_* Callback Testing**
```ruby
test 'should execute before_validation callback' do
  model = Model.new(attributes)
  
  # Verify initial state
  assert_nil model.some_field
  
  # Trigger validation (which triggers callback)
  model.valid?
  
  # Verify callback executed
  assert_not_nil model.some_field
end
```

### **Pattern 2: after_create Callback Testing**
```ruby
test 'should execute after_create callback' do
  # Mock or stub external dependencies
  service_mock = Minitest::Mock.new
  service_mock.expect :call, true, [Integer]
  
  Service.stub :some_method, service_mock do
    model = Model.create!(attributes)
    
    # Verify callback executed
    service_mock.verify
  end
end
```

### **Pattern 3: after_update Callback Testing**
```ruby
test 'should execute after_update callback on status change' do
  model = models(:one)
  
  # Mock external service
  service_mock = Minitest::Mock.new
  service_mock.expect :call, true, [Integer]
  
  Service.stub :some_method, service_mock do
    model.update!(status: 'new_status')
    
    # Verify callback executed
    service_mock.verify
  end
end
```

### **Pattern 4: Conditional Callback Testing**
```ruby
test 'should execute callback only when condition met' do
  model = models(:one)
  
  # Test callback executes when condition is true
  service_mock = Minitest::Mock.new
  service_mock.expect :call, true, [Integer]
  
  Service.stub :some_method, service_mock do
    model.update!(status: 'changed')
    service_mock.verify
  end
end

test 'should not execute callback when condition not met' do
  model = models(:one)
  
  # Test callback doesn't execute when condition is false
  service_mock = Minitest::Mock.new
  # No expectation set - should not be called
  
  Service.stub :some_method, service_mock do
    model.update!(other_field: 'changed')
    # If callback was called, mock would raise unexpected call error
  end
end
```

### **Pattern 5: after_commit Callback Testing**
```ruby
test 'should enqueue job after commit' do
  assert_enqueued_with(job: SomeJob) do
    Model.create!(attributes)
  end
end
```

---

## 🎯 **Success Criteria**

| Metric | Target | Status |
|--------|--------|--------|
| **Critical Models Tested** | 3+ | 🚧 **0/3** |
| **New Callback Tests** | 35+ | 🚧 **0/35** |
| **Test Success Rate** | 100% | 🚧 **TBD** |
| **Zero Errors** | Yes | 🚧 **TBD** |
| **Callback Coverage** | 100% | 🚧 **0%** |
| **Documentation** | Complete | 🚧 **IN PROGRESS** |

---

## 📈 **Expected Impact**

### **Data Integrity**
- ✅ Verify callbacks execute in correct order
- ✅ Ensure data consistency across lifecycle
- ✅ Prevent callback regression bugs
- ✅ Validate conditional callback logic

### **Business Logic**
- ✅ Verify order status cascades correctly
- ✅ Ensure kitchen broadcasts work
- ✅ Validate user onboarding setup
- ✅ Confirm cache invalidation

### **Development Quality**
- ✅ Confident callback refactoring
- ✅ Clear callback documentation
- ✅ Faster callback debugging
- ✅ Better callback design

---

## 💡 **Key Considerations**

### **Mocking & Stubbing**
- Use `Minitest::Mock` for service dependencies
- Stub external services (broadcast, cache, jobs)
- Avoid testing implementation details
- Focus on callback execution and effects

### **Database Transactions**
- Be aware of `after_commit` vs `after_save`
- Use appropriate test helpers for commit callbacks
- Consider transaction rollback in tests

### **Performance**
- Mock expensive operations (broadcasts, cache)
- Keep tests fast and focused
- Avoid unnecessary database hits

### **Maintainability**
- Clear test names describing callback behavior
- Group related callback tests together
- Document why callbacks exist
- Test both positive and negative cases

---

## 📋 **Files to Create/Modify**

### **Test Files to Enhance**
1. ✅ `test/models/user_test.rb` - Add callback tests (existing file)
2. 🚧 `test/models/ordr_test.rb` - Add callback tests (may need creation)
3. 🚧 `test/models/menu_test.rb` - Add callback tests (may need creation)
4. 🚧 `test/models/announcement_test.rb` - Add callback tests (may need creation)

### **Documentation Files**
1. ✅ `docs/testing/callback-testing-plan.md` - This document
2. 🚧 `docs/testing/callback-testing-summary.md` - Completion summary (future)

---

## 🚀 **Next Steps**

1. **Implement User callback tests** - Start with existing test file
2. **Create Ordr test file** - Add comprehensive callback tests
3. **Create Menu test file** - Add cache and localization tests
4. **Run test suite** - Verify all tests pass
5. **Generate coverage** - Measure callback coverage
6. **Update documentation** - Mark task complete

---

**Status**: 🚧 **PLAN COMPLETE - READY FOR IMPLEMENTATION**  
**Estimated Tests**: 35-40 new callback tests  
**Estimated Time**: 2-3 hours  
**Risk Level**: LOW (well-defined scope, clear patterns)

🎯 **Ready to proceed with implementation!**
