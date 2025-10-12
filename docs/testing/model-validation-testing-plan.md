# Model Validation Testing Implementation Plan

## 🎯 **Objective**
Implement comprehensive model validation tests to ensure complete model behavior coverage and improve overall test reliability.

## 📊 **Current State Analysis**

### **Models WITH Validation Tests (Good Coverage)**
- ✅ **Restaurant** - Comprehensive validation tests (name, status, optional fields)
- ✅ **Menuitem** - Extensive validation tests (name, itemtype, status, preptime, price, calories)
- ✅ **Menu** - Basic validation tests
- ✅ **Menusection** - Basic validation tests
- ✅ **Employee** - Basic validation tests
- ✅ **Plan** - Comprehensive tests with business logic
- ✅ **Contact** - Basic validation tests

### **Models WITH Validations BUT Missing/Incomplete Tests**
- ❌ **OcrMenuItem** - Has validations (name, sequence, price) but basic tests
- ❌ **OcrMenuSection** - Has validations (name, sequence) but basic tests
- ❌ **Tax** - Has validations (name, taxpercentage) but basic tests
- ❌ **Ordraction** - Has validations (action) but basic tests
- ❌ **Allergyn** - Has validations (name, symbol) but basic tests
- ❌ **Ingredient** - Has validations (name) but basic tests
- ❌ **Tip** - Has validations (percentage) but basic tests
- ❌ **Feature** - Has validations (key, descriptionKey) but basic tests
- ❌ **Size** - Has validations (name, size) but basic tests
- ❌ **Smartmenu** - Has validations (slug) but basic tests
- ❌ **OcrMenuImport** - Has validations (name, status) but basic tests
- ❌ **FeaturesPlan** - Has validations (uniqueness) but basic tests
- ❌ **Tablesetting** - Has validations (tabletype, name, capacity, status) but basic tests
- ❌ **Ordrparticipant** - Has validations (sessionid) but basic tests
- ❌ **Tag** - Has validations (name) but basic tests
- ❌ **Announcement** - Has validations (multiple fields) but basic tests
- ❌ **MenuitemIngredientMapping** - Has validations (uniqueness) but basic tests
- ❌ **Inventory** - Has validations (multiple numeric fields) but basic tests
- ❌ **MenuitemTagMapping** - Has validations (uniqueness) but basic tests

### **Models WITHOUT Validations (Expected)**
- ✅ **User** - Uses Devise validations (email, password)
- ✅ **ApplicationRecord** - Base class
- ✅ **Current** - Thread-local storage
- ✅ **DwOrdersMv** - Materialized view

## 🎯 **Implementation Strategy**

### **Phase 1: Critical Business Models (High Priority)**
Focus on models that handle core business logic and user data:

1. **Tax** - Financial calculations
2. **Tip** - Financial calculations  
3. **Inventory** - Stock management
4. **Tablesetting** - Restaurant capacity
5. **Allergyn** - Health/safety information
6. **Feature** - Subscription management

### **Phase 2: Content Management Models (Medium Priority)**
Models that handle menu content and structure:

1. **OcrMenuItem** - Menu import functionality
2. **OcrMenuSection** - Menu structure
3. **OcrMenuImport** - Import process
4. **Ingredient** - Menu composition
5. **Size** - Menu variants
6. **Tag** - Menu categorization

### **Phase 3: System Models (Lower Priority)**
Models that handle system functionality:

1. **Smartmenu** - Public menu system
2. **Ordraction** - Order tracking
3. **Ordrparticipant** - Order participation
4. **Announcement** - System notifications
5. **FeaturesPlans** - Subscription relationships
6. **Mapping Models** - Association tables

## 🧪 **Test Patterns to Implement**

### **1. Presence Validations**
```ruby
test "should require [field_name]" do
  @model.[field_name] = nil
  assert_not @model.valid?
  assert_includes @model.errors[:field_name], "can't be blank"
end

test "should require [field_name] not empty" do
  @model.[field_name] = ""
  assert_not @model.valid?
  assert_includes @model.errors[:field_name], "can't be blank"
end
```

### **2. Numericality Validations**
```ruby
test "should require numeric [field_name]" do
  @model.[field_name] = "not_a_number"
  assert_not @model.valid?
  assert_includes @model.errors[:field_name], "is not a number"
end

test "should require integer [field_name]" do
  @model.[field_name] = 10.5
  assert_not @model.valid?
  assert_includes @model.errors[:field_name], "must be an integer"
end

test "should require positive [field_name]" do
  @model.[field_name] = -1
  assert_not @model.valid?
  assert_includes @model.errors[:field_name], "must be greater than or equal to 0"
end
```

### **3. Uniqueness Validations**
```ruby
test "should require unique [field_name]" do
  duplicate = @model.dup
  duplicate.[field_name] = @model.[field_name]
  assert_not duplicate.valid?
  assert_includes duplicate.errors[:field_name], "has already been taken"
end

test "should require unique [field_name] scoped to [scope_field]" do
  duplicate = Model.new([field_name]: @model.[field_name], [scope_field]: @model.[scope_field])
  assert_not duplicate.valid?
  assert_includes duplicate.errors[:field_name], "has already been taken"
end
```

### **4. Format/Inclusion Validations**
```ruby
test "should validate [field_name] format" do
  @model.[field_name] = "invalid_format"
  assert_not @model.valid?
  assert_includes @model.errors[:field_name], "is invalid"
end

test "should validate [field_name] inclusion" do
  @model.[field_name] = "invalid_option"
  assert_not @model.valid?
  assert_includes @model.errors[:field_name], "is not included in the list"
end
```

### **5. Edge Cases and Boundary Testing**
```ruby
test "should handle edge case: zero value" do
  @model.[field_name] = 0
  assert @model.valid? # or assert_not depending on business rules
end

test "should handle edge case: maximum value" do
  @model.[field_name] = 999999
  assert @model.valid?
end

test "should handle edge case: whitespace" do
  @model.[field_name] = "   "
  assert_not @model.valid?
  assert_includes @model.errors[:field_name], "can't be blank"
end
```

## 📋 **Implementation Checklist**

### **For Each Model:**
- [ ] Identify all validation rules from model file
- [ ] Create comprehensive test file if missing
- [ ] Test all presence validations
- [ ] Test all numericality validations  
- [ ] Test all uniqueness validations
- [ ] Test all format/inclusion validations
- [ ] Test edge cases and boundary conditions
- [ ] Test valid scenarios (positive tests)
- [ ] Ensure proper fixture setup
- [ ] Verify all error messages match expectations

### **Quality Standards:**
- [ ] All tests pass consistently
- [ ] Tests are isolated and independent
- [ ] Descriptive test names indicating what's being tested
- [ ] Proper setup and teardown
- [ ] Use of existing fixtures where possible
- [ ] Coverage of both positive and negative scenarios

## 🎯 **Success Metrics**

### **Quantitative Goals:**
- **Test Coverage**: Increase model validation test coverage to 95%+
- **Test Count**: Add 150+ new validation tests
- **Model Coverage**: 100% of models with validations have comprehensive tests
- **Zero Failures**: All new tests pass consistently

### **Qualitative Goals:**
- **Comprehensive Coverage**: All validation rules tested
- **Edge Case Handling**: Boundary conditions properly tested
- **Error Message Validation**: Proper error message verification
- **Business Logic Validation**: Critical business rules enforced

## 🚀 **Implementation Timeline**

### **Phase 1 (Days 1-2): Critical Business Models**
- Tax, Tip, Inventory, Tablesetting, Allergyn, Feature
- ~60 tests

### **Phase 2 (Days 3-4): Content Management Models**  
- OcrMenuItem, OcrMenuSection, OcrMenuImport, Ingredient, Size, Tag
- ~70 tests

### **Phase 3 (Days 5-6): System Models**
- Smartmenu, Ordraction, Ordrparticipant, Announcement, etc.
- ~50 tests

### **Phase 4 (Day 7): Integration and Cleanup**
- Run full test suite
- Fix any failures
- Update documentation
- Generate coverage reports

## 📚 **Documentation Updates Required**
- [ ] Update `development_roadmap.md` to mark task complete
- [ ] Update `docs/testing/todo.md` to reflect progress
- [ ] Create this implementation plan document
- [ ] Update any model-specific documentation

This comprehensive plan ensures systematic implementation of model validation tests with clear priorities, patterns, and success metrics.
