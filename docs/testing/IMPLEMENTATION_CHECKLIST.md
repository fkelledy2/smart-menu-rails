# Test Automation Implementation Checklist

Track your progress implementing test-friendly UI across SmartMenu.

## ✅ Phase 1: Foundation (COMPLETED)

- [x] **Create Testable helper module** → `app/helpers/concerns/testable.rb`
- [x] **Create test ID helper methods** → `test/support/test_id_helpers.rb`
- [x] **Include Testable in ApplicationHelper**
- [x] **Update first view (Import section)** → `app/views/restaurants/sections/_import_2025.html.erb`
- [x] **Create demonstration test** → `test/system/import_automation_test.rb`
- [x] **Document strategy** → `docs/testing/UI_TEST_AUTOMATION_PLAN.md`
- [x] **Create quick start guide** → `docs/testing/QUICK_START_GUIDE.md`

**Status:** ✅ Complete - Ready to expand!

---

## 🚀 Phase 2: Critical Path Views (IN PROGRESS)

Priority areas for test ID implementation:

### Authentication Flow
- [ ] **Login Page** → `app/views/devise/sessions/new.html.erb`
  - [ ] Email input: `test_field('login', 'email')`
  - [ ] Password input: `test_field('login', 'password')`
  - [ ] Submit button: `test_button('login')`
  - [ ] Forgot password link: `test_link('forgot-password')`
  
- [ ] **Signup Page** → `app/views/devise/registrations/new.html.erb`
  - [ ] Email input: `test_field('signup', 'email')`
  - [ ] Password input: `test_field('signup', 'password')`
  - [ ] Password confirmation: `test_field('signup', 'password-confirmation')`
  - [ ] Submit button: `test_button('signup')`

### Restaurant Management
- [ ] **Restaurant List** → `app/views/restaurants/index.html.erb`
  - [ ] Restaurant list container: `test_id('restaurants-list')`
  - [ ] Each restaurant row: `test_item('restaurant', restaurant.id)`
  - [ ] Edit links: `test_link("edit-restaurant-#{id}")`
  - [ ] Delete buttons: `test_button("delete-restaurant-#{id}")`
  
- [ ] **Restaurant Edit - Details** → `app/views/restaurants/sections/_details_2025.html.erb`
  - [ ] Details form: `test_id('restaurant-details-form')`
  - [ ] Name input: `test_field('restaurant', 'name')`
  - [ ] Description input: `test_field('restaurant', 'description')`
  - [ ] Save button: `test_button('save-details')`
  
- [ ] **Restaurant Edit - Sidebar** → `app/views/restaurants/_sidebar_2025.html.erb`
  - [ ] Sidebar container: `test_section('restaurant-sidebar')`
  - [ ] Details link: `test_link('details-tab')`
  - [ ] Menus link: `test_link('menus-tab')`
  - [ ] Import link: `test_link('import-tab')` ✅ Already done
  - [ ] Settings link: `test_link('settings-tab')`

### Menu CRUD
- [ ] **Menu List** → `app/views/restaurants/sections/_menus_2025.html.erb`
  - [ ] Menus container: `test_id('menus-list')`
  - [ ] Each menu row: `test_item('menu', menu.id)`
  - [ ] Add menu button: `test_button('add-menu')`
  - [ ] Edit menu links: `test_link("edit-menu-#{id}")`
  - [ ] Delete menu buttons: `test_button("delete-menu-#{id}")`
  
- [ ] **Menu Form** → `app/views/menus/_form.html.erb`
  - [ ] Menu form: `test_id('menu-form')`
  - [ ] Name input: `test_field('menu', 'name')`
  - [ ] Description input: `test_field('menu', 'description')`
  - [ ] Active checkbox: `test_field('menu', 'active')`
  - [ ] Submit button: `test_button('save-menu')`

### Menu Items
- [ ] **Menu Item List**
  - [ ] Items container: `test_id('menu-items-list')`
  - [ ] Each item row: `test_item('menu-item', item.id)`
  - [ ] Add item button: `test_button('add-item')`
  - [ ] Edit item links: `test_link("edit-item-#{id}")`
  
- [ ] **Menu Item Form**
  - [ ] Item form: `test_id('menu-item-form')`
  - [ ] Name input: `test_field('item', 'name')`
  - [ ] Price input: `test_field('item', 'price')`
  - [ ] Description input: `test_field('item', 'description')`
  - [ ] Submit button: `test_button('save-item')`

### OCR Import Flow (✅ DONE)
- [x] **Import Form** → `app/views/restaurants/sections/_import_2025.html.erb`
  - [x] Info banner: `test_id('import-info-banner')`
  - [x] Form card: `test_id('import-form-card')`
  - [x] Form: `test_id('import-form')`
  - [x] Name input: `test_field('import', 'name')`
  - [x] PDF input: `test_field('import', 'pdf')`
  - [x] Submit button: `test_button('import-submit')`
  - [x] Recent imports: `test_id('recent-imports-card')`
  - [x] Import rows: `test_item('import-row', id)`
  
- [ ] **Import Review** → `app/views/ocr_menu_imports/show.html.erb`
  - [ ] Review container: `test_id('import-review')`
  - [ ] Publish button: `test_button('publish-import')`
  - [ ] Edit section buttons: `test_button("edit-section-#{id}")`
  - [ ] Edit item buttons: `test_button("edit-item-#{id}")`

---

## 📋 Phase 3: Supporting Views

### Navigation & Layout
- [ ] **Main Navigation**
  - [ ] Nav container: `test_section('main-nav')`
  - [ ] Dashboard link: `test_link('dashboard')`
  - [ ] Restaurants link: `test_link('restaurants')`
  - [ ] User menu: `test_id('user-menu')`
  - [ ] Logout button: `test_button('logout')`

### Settings & Configuration
- [ ] **Restaurant Settings**
  - [ ] Settings form: `test_id('settings-form')`
  - [ ] Currency select: `test_field('settings', 'currency')`
  - [ ] Timezone select: `test_field('settings', 'timezone')`
  - [ ] Save button: `test_button('save-settings')`

### User Profile
- [ ] **Profile Page**
  - [ ] Profile form: `test_id('profile-form')`
  - [ ] Name input: `test_field('profile', 'name')`
  - [ ] Email input: `test_field('profile', 'email')`
  - [ ] Avatar upload: `test_field('profile', 'avatar')`

### Notifications & Messages
- [ ] **Flash Messages**
  - [ ] Success message: `test_message('success')`
  - [ ] Error message: `test_message('error')`
  - [ ] Warning message: `test_message('warning')`
  - [ ] Info message: `test_message('info')`

---

## 🧪 Phase 4: Test Coverage

### Write Tests for Critical Paths
- [x] **Import flow tests** → `test/system/import_automation_test.rb`
  - [x] Page structure test
  - [x] Form validation test
  - [x] Recent imports display test
  - [x] Delete functionality test
  
- [ ] **Authentication tests**
  - [ ] Login flow
  - [ ] Signup flow
  - [ ] Logout flow
  - [ ] Password reset flow
  
- [ ] **Restaurant CRUD tests**
  - [ ] Create restaurant
  - [ ] Edit restaurant
  - [ ] Delete restaurant
  - [ ] Navigate between sections
  
- [ ] **Menu CRUD tests**
  - [ ] Create menu
  - [ ] Edit menu
  - [ ] Delete menu
  - [ ] Activate/deactivate menu
  
- [ ] **Menu Item tests**
  - [ ] Add item
  - [ ] Edit item
  - [ ] Delete item
  - [ ] Reorder items

---

## 📊 Metrics & Goals

### Coverage Targets
- [ ] **Week 2:** 30% of interactive elements have test IDs
- [ ] **Week 4:** 60% of interactive elements have test IDs
- [ ] **Week 6:** 80%+ of interactive elements have test IDs

### Quality Targets
- [ ] Test suite reliability: 95%+
- [ ] Test maintenance time: <10% of total test time
- [ ] Zero broken tests after UI refactors
- [ ] Team adoption: 90%+ of new code includes test IDs

### Success Criteria
- [ ] All critical user flows covered
- [ ] CI/CD pipeline green consistently
- [ ] Test execution time <15 minutes
- [ ] Documentation complete and up-to-date

---

## 🎯 Quick Wins (Start Here!)

If you're not sure where to start, tackle these high-value, low-effort updates:

1. **✅ DONE: Import flow** (already completed)
2. **Login page** (10 minutes) - Super critical, small scope
3. **Restaurant sidebar** (15 minutes) - Used everywhere
4. **Menu list** (20 minutes) - Core functionality
5. **Flash messages** (5 minutes) - Easy, high visibility

---

## 📝 Notes & Tips

### Naming Consistency
Always follow these patterns:
- Forms: `{name}-form`
- Inputs: `{form}-{field}-input`
- Buttons: `{action}-btn`
- Links: `{action}-link`
- Sections: `{name}-section`
- Items: `{type}-{id}`

### Testing Tips
```ruby
# ✅ DO: Use semantic names
test_button('submit')
test_field('login', 'email')

# ❌ DON'T: Use generic names
test_id('btn-1')
test_id('input-field')
```

### View Updates
```erb
<!-- ✅ DO: Use helper methods -->
<button <%= test_button('delete') %>>Delete</button>
<%= f.text_field :email, **test_field('user', 'email') %>

<!-- ❌ DON'T: Hardcode attributes -->
<button data-testid="delete-button">Delete</button>
```

---

## 🔄 Weekly Review

Track your progress each week:

### Week 1
- Views updated: ___
- Test IDs added: ___
- Tests written: ___
- Blockers: ___

### Week 2
- Views updated: ___
- Test IDs added: ___
- Tests written: ___
- Blockers: ___

### Week 3
- Views updated: ___
- Test IDs added: ___
- Tests written: ___
- Blockers: ___

---

## ✨ Current Status

**Last Updated:** November 13, 2024

**Completion:** 
- Phase 1: ✅ 100% Complete
- Phase 2: 🔄 8% Complete (1/12 items)
- Phase 3: 🔜 Not Started
- Phase 4: 🔄 8% Complete (1/12 items)

**Overall Progress:** ~10%

**Next Actions:**
1. Update login page with test IDs
2. Update restaurant sidebar with test IDs
3. Write authentication tests
4. Update menu list view

---

Keep going! Every view you update makes the entire test suite more reliable. 🚀
