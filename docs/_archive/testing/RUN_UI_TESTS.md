# Running UI Automation Tests

## Quick Start

Run all UI automation tests:

```bash
./bin/run_ui_automation_tests
```

## What This Script Does

The `run_ui_automation_tests` script:
- ✅ Runs all UI automation tests in sequence
- ✅ Provides colored output for easy reading
- ✅ Shows a summary with pass/fail counts
- ✅ Reports total execution time
- ✅ Exits with appropriate status codes (0 = success, 1 = failure)

## Current Test Coverage

### Phase 1: Authentication & Core Flows (42 tests)
- `test/system/authentication_test.rb` - Login, signup, password reset (19 tests)
- `test/system/import_automation_test.rb` - Menu import workflow (6 tests)
- `test/system/restaurant_menu_management_test.rb` - Menu CRUD operations (13 tests)

### Phase 2: Restaurant & Menu Management (32 tests)
- `test/system/restaurant_details_test.rb` - Restaurant form management (17 tests)
- `test/system/menu_items_test.rb` - Menu items listing and operations (15 tests)

**Total: 74 tests across 5 test files**

## Running Individual Test Files

Run a specific test file:

```bash
bundle exec rails test test/system/authentication_test.rb
```

Run a specific test:

```bash
bundle exec rails test test/system/authentication_test.rb:25
```

## Running All System Tests

Run all system tests (including non-UI tests):

```bash
bundle exec rails test test/system/
```

## Adding New Tests

When you create new UI automation test files:

1. Create your test file in `test/system/`
2. Open `bin/run_ui_automation_tests`
3. Add your test file to the `UI_TESTS` array:

```bash
UI_TESTS=(
  # ... existing tests ...
  
  # Phase 3 - Your new tests
  "test/system/your_new_test.rb"
)
```

4. Save and the script will automatically include it

## Expected Output

```
================================
UI Automation Test Suite
================================

Running 5 UI automation test suites...

Running: test/system/authentication_test.rb
✓ Passed: test/system/authentication_test.rb

Running: test/system/import_automation_test.rb
✓ Passed: test/system/import_automation_test.rb

...

================================
Test Suite Summary
================================
Total Test Suites: 5
Passed: 5
Failed: 0
Duration: 58s

✅ All UI Automation Tests PASSED
```

## Troubleshooting

### Tests Fail with Database Errors

Reset the test database:

```bash
RAILS_ENV=test bundle exec rails db:reset
```

### Chrome/Browser Issues

Make sure ChromeDriver is installed:

```bash
brew install chromedriver
```

### Port Already in Use

Kill existing Puma processes:

```bash
pkill -f puma
```

## CI/CD Integration

Add to your CI pipeline:

```yaml
# GitHub Actions example
- name: Run UI Automation Tests
  run: ./bin/run_ui_automation_tests
```

## Performance

- **Phase 1 Tests:** ~35-40 seconds
- **Phase 2 Tests:** ~20-25 seconds
- **Total Runtime:** ~55-65 seconds

## Coverage Goals

Current coverage by feature area:

| Feature | Status | Tests |
|---------|--------|-------|
| Authentication | ✅ Complete | 19 |
| Menu Import | ✅ Complete | 6 |
| Menu Management | ✅ Complete | 13 |
| Restaurant Details | ✅ Complete | 17 |
| Menu Items | ✅ Complete | 15 |
| Settings | ⏳ Planned | - |
| Staff Management | ⏳ Planned | - |

---

**Last Updated:** November 14, 2024  
**Total UI Tests:** 74  
**Maintainer:** Development Team
