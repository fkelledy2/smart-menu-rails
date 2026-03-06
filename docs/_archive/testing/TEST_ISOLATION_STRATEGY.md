# Test Isolation Strategy

## Problem: Test Pollution

Tests were failing in the full suite but passing in isolation due to **test pollution** - shared state from previous tests affecting subsequent tests.

## ❌ Bad Approach: Cache-Busting Workarounds

```ruby
# DON'T DO THIS (masks the problem)
visit smartmenu_path(@smartmenu.slug, t: Time.now.to_i)
```

**Why it's bad:**
- Masks the real problem instead of fixing it
- Creates brittle tests dependent on implementation details
- Doesn't address root cause (shared browser/database state)
- Makes tests harder to understand

## ✅ Good Approach: Proper Test Isolation

### 1. Use Teardown to Reset Browser State

```ruby
class SmartmenuOrderStateTest < ApplicationSystemTestCase
  setup do
    # Set up fixtures and instance variables
    @smartmenu = smartmenus(:one)
    @burger = menuitems(:burger)
  end
  
  teardown do
    # Reset browser session between tests to prevent pollution
    # This clears cookies, cache, and any JavaScript state
    Capybara.reset_sessions!
  end
  
  test 'some test' do
    visit smartmenu_path(@smartmenu.slug)  # Clean state, no cache-bust needed!
    # ... test logic ...
  end
end
```

**What `Capybara.reset_sessions!` does:**
- Clears all cookies (including session cookies)
- Resets browser cache
- Clears JavaScript state (variables, event listeners)
- Forces fresh page loads
- Gives each test a clean browser environment

### 2. Database Transactions (Already Handled by Rails)

Rails automatically wraps each test in a database transaction and rolls it back, so database state is automatically clean between tests.

```ruby
# config/environments/test.rb
config.action_controller.allow_forgery_protection = true  # We have this

# test/test_helper.rb  
fixtures :all  # Rails handles transaction rollback automatically
```

### 3. When Cache-Busting IS Appropriate

**Only use cache-bust when testing HTTP caching behavior specifically:**

```ruby
test 'order persists for same session across page reloads' do
  visit smartmenu_path(@smartmenu.slug)
  
  # Create order
  add_item_to_order(@burger.id)
  order_id = Ordr.last.id
  
  # Reload page (cache-bust needed here because we're TESTING that
  # the controller doesn't serve a cached 304 response)
  visit smartmenu_path(@smartmenu.slug, t: Time.now.to_i)
  
  # Verify order persisted
  assert_equal order_id, Ordr.last.id
end
```

**Why it's OK here:**
- We're explicitly testing HTTP cache behavior
- The cache-bust is part of what we're testing
- It's intentional, not a workaround

## Benefits of Proper Isolation

### Before (with cache-bust workarounds):
```ruby
test 'check badge' do
  visit smartmenu_path(@smartmenu.slug, t: Time.now.to_i)  # Why timestamp?
  # ... test ...
end

test 'check total' do
  visit smartmenu_path(@smartmenu.slug, t: Time.now.to_i)  # Why timestamp?
  # ... test ...
end
```
- Unclear intent
- Fragile
- Doesn't actually fix pollution

### After (with teardown):
```ruby
teardown do
  Capybara.reset_sessions!  # Clear intent: reset between tests
end

test 'check badge' do
  visit smartmenu_path(@smartmenu.slug)  # Clean and clear
  # ... test ...
end

test 'check total' do
  visit smartmenu_path(@smartmenu.slug)  # Clean and clear
  # ... test ...
end
```
- Clear intent
- Robust
- Actually prevents pollution

## Implementation Checklist

- [x] Add `teardown` with `Capybara.reset_sessions!` to all system test classes
- [x] Remove cache-bust parameters except where testing HTTP caching
- [x] Verify tests pass in isolation
- [x] Verify tests pass in full suite
- [x] Document the strategy

## Test Files Updated

1. ✅ `test/system/smartmenu_order_state_test.rb` - Added teardown
2. ✅ `test/system/smartmenu_customer_ordering_test.rb` - Added teardown
3. ✅ Removed cache-bust from tests not testing HTTP caching

## Results

**Before:**
- Tests passing in isolation but failing in suite
- 8+ cache-bust workarounds scattered across tests
- Unclear why timestamps were needed

**After:**
- Tests pass reliably in both isolation and full suite
- 2 teardown methods providing clear isolation
- Only 1 intentional cache-bust (testing HTTP caching)
- Clear, maintainable test code

## Key Principle

> **Fix the root cause (shared state) rather than masking symptoms (cache issues)**

Proper test isolation through `teardown` ensures each test starts with a clean browser environment, preventing pollution without workarounds.

---

**Last Updated:** November 15, 2024  
**Status:** ✅ Implemented and working
