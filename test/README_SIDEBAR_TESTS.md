# Sidebar Mobile Tests

## Overview

Three types of tests are provided to verify the mobile sidebar functionality:

1. **System Tests** (Ruby/Capybara) - Automated browser testing
2. **JavaScript Tests** (Jest) - Unit tests for Stimulus controller
3. **Manual Tests** - Step-by-step verification guide

---

## Running System Tests

### Prerequisites
```bash
# Ensure test database is set up
rails db:test:prepare
```

### Run All Sidebar Tests
```bash
rails test:system test/system/sidebar_mobile_test.rb
```

### Run Specific Test
```bash
rails test:system test/system/sidebar_mobile_test.rb::<test_name>

# Examples:
rails test:system test/system/sidebar_mobile_test.rb::test_sidebar_toggle_works_on_mobile
rails test:system test/system/sidebar_mobile_test.rb::test_sidebar_debounce_prevents_rapid_toggles
```

### Run with Visible Browser (Headless Off)
```bash
HEADLESS=false rails test:system test/system/sidebar_mobile_test.rb
```

---

## Running JavaScript Tests

### Prerequisites
```bash
# Install JavaScript test dependencies
npm install --save-dev jest @testing-library/jest-dom
npm install --save-dev @hotwired/stimulus
```

### Run JavaScript Tests
```bash
# Run all JS tests
npm test test/javascript/sidebar_controller.test.js

# Run with coverage
npm test -- --coverage test/javascript/sidebar_controller.test.js

# Watch mode (re-run on file changes)
npm test -- --watch test/javascript/sidebar_controller.test.js
```

---

## Manual Testing

Follow the step-by-step guide in:
```
test/manual/SIDEBAR_MOBILE_TEST.md
```

This is useful for:
- Visual verification of animations
- Cross-browser testing
- Debugging specific issues
- Demonstration purposes

---

## Test Coverage

### What's Tested

#### ✅ Core Functionality
- Sidebar opens when toggle button clicked
- Sidebar closes when close button clicked
- Sidebar closes when overlay clicked
- Sidebar toggles between open/closed states

#### ✅ Debounce Logic
- Rapid clicks are ignored (400ms debounce)
- Timestamp-based rate limiting
- No flicker or multiple toggles

#### ✅ Event Handling
- Event bubbling is prevented
- `stopImmediatePropagation()` works
- Multiple event listeners don't interfere

#### ✅ Responsive Behavior
- Sidebar auto-closes on desktop resize
- Toggle button hidden on desktop
- Proper z-index stacking

#### ✅ Body Scroll Management
- Body scroll locked when sidebar open
- Body scroll restored when sidebar closed

#### ✅ Navigation Integration
- Sidebar links work with Turbo Frames
- Active state updates correctly
- URL changes properly

#### ✅ Edge Cases
- Missing sidebar target (fallback works)
- Multiple controller instances
- Turbo navigation state management

---

## Expected Results

### All Tests Passing:
```
# System Tests
5 runs, 25 assertions, 0 failures, 0 errors, 0 skips

# JavaScript Tests
PASS test/javascript/sidebar_controller.test.js
  SidebarController
    ✓ controller connects successfully (5ms)
    ✓ toggle opens sidebar (3ms)
    ✓ toggle closes sidebar when open (502ms)
    ✓ close button closes sidebar (2ms)
    ✓ overlay click closes sidebar (2ms)
    ✓ rapid toggles are debounced (1ms)
    ✓ prevents event bubbling (2ms)
    ✓ handles missing sidebar target gracefully (2ms)
    ✓ resize to desktop closes sidebar (3ms)
    ✓ timestamp-based debounce works correctly (2ms)
    
Test Suites: 1 passed, 1 total
Tests:       10 passed, 10 total
```

---

## Debugging Failed Tests

### System Test Failures

#### Sidebar not visible
```bash
# Check if element exists
assert_selector('.sidebar-2025')

# Check CSS loaded
page.evaluate_script("window.getComputedStyle(document.querySelector('.sidebar-2025')).zIndex")
# Should return "1050"
```

#### Toggle not working
```bash
# Check Stimulus controller attached
assert_selector('[data-controller="sidebar"]')

# Check console for errors
puts page.driver.browser.logs.get(:browser)
```

### JavaScript Test Failures

#### Stimulus not loading
```javascript
// Verify Stimulus Application
expect(application).toBeDefined()
expect(application.controllers).toContain('sidebar')
```

#### Debounce not working
```javascript
// Add more logging
console.log('Time since last toggle:', timeSinceLastToggle)
console.log('Debounce threshold:', 400)
```

---

## Continuous Integration

### GitHub Actions Example

```yaml
name: Sidebar Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      
      - name: Set up Node
        uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: 'npm'
      
      - name: Install JS dependencies
        run: npm install
      
      - name: Run System Tests
        run: rails test:system test/system/sidebar_mobile_test.rb
      
      - name: Run JavaScript Tests
        run: npm test test/javascript/sidebar_controller.test.js
```

---

## Performance Benchmarks

Expected performance metrics:

| Metric | Target | Acceptable |
|--------|--------|------------|
| Toggle response time | < 50ms | < 100ms |
| Animation duration | 300ms | 300ms |
| Debounce delay | 400ms | 400ms |
| Memory leak | 0 MB | < 1 MB |
| FPS during animation | 60 fps | > 50 fps |

---

## Related Documentation

- [Sidebar Component Documentation](../docs/components/sidebar_2025.md)
- [Stimulus Controller Guide](../docs/javascript/stimulus_controllers.md)
- [System Testing Guide](../docs/testing/system_tests.md)
- [Mobile UI Guidelines](../docs/design/mobile_guidelines.md)

---

## Contributing

When modifying sidebar functionality:

1. ✅ Run all tests before committing
2. ✅ Add tests for new features
3. ✅ Update manual test guide if needed
4. ✅ Check performance benchmarks
5. ✅ Test on real mobile devices

---

## Support

If tests are failing:

1. Check console logs for JavaScript errors
2. Review browser compatibility
3. Verify Stimulus version compatibility
4. Check CSS is loading correctly
5. Consult manual test guide for visual debugging
