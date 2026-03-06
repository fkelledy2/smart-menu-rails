# Quick Coverage Wins Implementation Plan

## 🎯 **Goal**: Increase coverage from 39.22% to 50%+ in 2 weeks

### **Phase 1: Model Tests (Week 1 - 8 hours)**

#### **Day 1-2: Simple Models (4 hours)**
1. **Allergyn** (30 min) - Validations, enums, associations
2. **Tag** (20 min) - Basic validations
3. **Size** (20 min) - Simple model
4. **Ingredient** (20 min) - Basic structure
5. **Tax** (30 min) - Validations and calculations
6. **Tip** (20 min) - Simple model
7. **Inventory** (30 min) - Associations
8. **Service** (30 min) - Basic model

**Expected Coverage Gain**: +6-8%

#### **Day 3-4: Complex Models (4 hours)**
9. **Employee** (1 hour) - Enums, validations, roles, associations
10. **Menuitem** (1.5 hours) - Complex associations, image upload, localization
11. **Menusection** (1 hour) - Business logic, ordering, associations
12. **Ordrparticipant** (30 min) - Ordering logic, allergies

**Expected Coverage Gain**: +4-6%

### **Phase 2: Association & Validation Tests (Week 2 - 6 hours)**

#### **Day 1-2: Remaining Models (3 hours)**
13. **Tablesetting** (45 min) - QR codes, restaurant settings
14. **Restaurantavailability** (45 min) - Business hours logic
15. **Menuavailability** (45 min) - Menu scheduling
16. **Ordritem** (45 min) - Order item logic

#### **Day 3: Edge Cases & Callbacks (3 hours)**
17. **Model callbacks testing** - Cache invalidation, status changes
18. **Complex validations** - Cross-model validations
19. **Enum edge cases** - Invalid states, transitions

**Expected Coverage Gain**: +3-5%

### **Phase 3: Service & Controller Gaps (Ongoing)**

#### **Missing Service Tests**
- **ExternalApiClient** (1 hour) - API integration patterns
- **StructuredLogger** enhancements (30 min) - Logging scenarios

#### **Controller Action Coverage**
- Identify missing controller actions via coverage report
- Focus on authentication, authorization, error handling

**Expected Coverage Gain**: +2-4%

## 📊 **Total Expected Results**

- **Time Investment**: 14-16 hours over 2 weeks
- **Coverage Increase**: 39.22% → 52-58% (13-19% gain)
- **Models with Tests**: 8 → 25+ models
- **ROI**: Very High (1% coverage per hour)

## 🛠️ **Implementation Strategy**

### **Test Template Pattern**
```ruby
require 'test_helper'

class ModelNameTest < ActiveSupport::TestCase
  # 1. Validation Tests (5-10 tests)
  # 2. Association Tests (3-5 tests)  
  # 3. Enum Tests (2-4 tests)
  # 4. Method Tests (2-5 tests)
  # 5. Edge Case Tests (2-3 tests)
end
```

### **Daily Workflow**
1. **Pick 2-3 models** from priority list
2. **Write basic validation tests** (presence, format, uniqueness)
3. **Add association tests** (belongs_to, has_many)
4. **Test enums** if present (valid values, invalid values)
5. **Run coverage** to verify gains
6. **Commit and move to next**

### **Success Metrics**
- **Daily**: +2-3% coverage increase
- **Weekly**: +8-12% coverage increase  
- **Final**: 50%+ total coverage achieved

## 🚀 **Getting Started**

### **Step 1: Set Up Coverage Tracking**
```bash
# Run tests with coverage
bundle exec rails test

# Check current coverage
open coverage/index.html
```

### **Step 2: Start with Allergyn Model**
```bash
# Edit the test file
code test/models/allergyn_test.rb

# Run specific test
bundle exec rails test test/models/allergyn_test.rb

# Check coverage impact
bundle exec rails test && open coverage/index.html
```

### **Step 3: Follow the Template**
Use the model test template for consistent, comprehensive coverage.

---

**Remember**: Focus on **breadth over depth** initially. Basic validation and association tests provide the highest coverage ROI.
