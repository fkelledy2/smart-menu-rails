# Verification Steps - Test ID Implementation

Quick steps to verify your test automation setup is working correctly.

## Step 1: Verify Helper is Loaded (30 seconds)

### Open Rails Console
```bash
rails console
```

### Test the Helper
```ruby
# Create a helper instance
helper = ApplicationController.helpers

# Test that Testable module is included
helper.test_id('test-button')
# => Should return: {"data-testid"=>"test-button"}

helper.test_field('login', 'email')
# => Should return: {"data-testid"=>"login-email-input"}

helper.test_button('submit')
# => Should return: {"data-testid"=>"submit-btn"}
```

**✅ Expected:** Methods return hash with `data-testid`
**❌ If you see errors:** Check that `Testable` is included in `ApplicationHelper`

---

## Step 2: Verify Test IDs in HTML (2 minutes)

### Start the Server
```bash
rails server
```

### Visit the Import Page
Navigate to: `http://localhost:3000/restaurants/1/edit?section=import`

### Inspect the HTML
Right-click any element → "Inspect" → Check the HTML

**You should see:**
```html
<div class="alert alert-info mb-4" data-testid="import-info-banner">
  ...
</div>

<div class="content-card-2025" data-testid="import-form-card">
  ...
</div>

<input type="text" data-testid="import-name-input" />

<button data-testid="import-submit-btn">Upload & Process</button>
```

**✅ Expected:** `data-testid` attributes are present in the HTML
**❌ If not visible:** 
- Check you're in development mode: `Rails.env.development?` should be `true`
- Verify `Testable` module has the environment check
- Clear browser cache and refresh

---

## Step 3: Verify Test Helpers Work (2 minutes)

### Run the Demo Test
```bash
rails test test/system/import_automation_test.rb -v
```

**✅ Expected Output:**
```
ImportAutomationTest#test_import_page_has_all_required_elements = 0.XX s = .
ImportAutomationTest#test_submit_button_is_disabled_until_form_is_complete = 0.XX s = .
...
6 runs, X assertions, 0 failures, 0 errors, 0 skips
```

**❌ If tests fail:**
- Check error messages for missing test IDs
- Verify you're logged in (Warden test mode)
- Ensure restaurant fixture exists

---

## Step 4: Inspect Test IDs via Browser Console (1 minute)

### Open Browser Console
On the import page, press `F12` or right-click → "Inspect" → "Console"

### Run This JavaScript
```javascript
// Find all elements with data-testid
document.querySelectorAll('[data-testid]').forEach(el => {
  console.log(el.getAttribute('data-testid'), '→', el.tagName);
});
```

**✅ Expected Output:**
```
import-info-banner → DIV
import-form-card → DIV
import-form → FORM
import-name-input → INPUT
import-pdf-input → INPUT
import-submit-btn → BUTTON
import-tips-card → DIV
recent-imports-card → DIV
import-row-1 → DIV
import-row-2 → DIV
...
```

---

## Step 5: Test in Capybara Console (Advanced)

### Open Rails Console with Capybara
```bash
rails console
```

### Load Capybara
```ruby
require 'capybara/dsl'
include Capybara::DSL
Capybara.default_driver = :selenium

# Visit the page
visit 'http://localhost:3000/restaurants/1/edit?section=import'

# Find elements by test ID
page.find('[data-testid="import-info-banner"]').text
# => Should return text from the banner

page.has_selector?('[data-testid="import-form"]')
# => Should return true

# Get all test IDs
page.all('[data-testid]').map { |e| e['data-testid'] }
# => Should return array of all test IDs
```

---

## Common Issues & Solutions

### Issue 1: `test_id` method not found
**Error:** `undefined method 'test_id'`

**Solution:**
```ruby
# Verify Testable is included
module ApplicationHelper
  include Testable  # ← Must be present
  # ...
end
```

### Issue 2: Test IDs not appearing in production
**This is intentional!**

Test IDs only appear in `test` and `development` environments to keep production HTML clean.

**Verify:**
```ruby
# In console
Rails.env.test?        # => true in test
Rails.env.development? # => true in development
Rails.env.production?  # => false (test IDs won't appear)
```

### Issue 3: Test IDs not appearing in HTML
**Check:**
1. Server is running in development mode
2. Helper is included in ApplicationHelper
3. View files are saved
4. Browser cache is cleared

### Issue 4: Tests can't find elements
**Error:** `Unable to find visible [data-testid="my-element"]`

**Solutions:**
```ruby
# Wait for element
find('[data-testid="my-element"]', wait: 10)

# Check for invisible elements
find('[data-testid="my-element"]', visible: :all)

# Use helper method
find_testid('my-element')
```

### Issue 5: Double splat operator (**) error
**Error:** `syntax error, unexpected **`

**Solution:**
Make sure helper method returns a Hash:
```ruby
# ✅ Correct
def test_id(id)
  { 'data-testid': id }
end

# Then use:
<%= f.text_field :name, **test_id('name-input') %>
```

---

## Quick Test Checklist

Use this to verify each new view:

- [ ] Test IDs visible in browser inspector?
- [ ] JavaScript console shows test IDs?
- [ ] Test helper methods work in console?
- [ ] Capybara can find elements by test ID?
- [ ] Automated tests pass?

---

## Validation Commands

### Check View Rendering
```bash
# Check for syntax errors
rails runner "ApplicationController.renderer.render(file: 'restaurants/sections/_import_2025.html.erb')"
```

### Run Specific Test
```bash
# Run one test method
rails test test/system/import_automation_test.rb::test_import_page_has_all_required_elements

# Run all import tests
rails test test/system/import_automation_test.rb
```

### Check Test Coverage
```bash
# List all data-testid attributes in a view
grep -o 'data-testid="[^"]*"' app/views/restaurants/sections/_import_2025.html.erb

# Count test IDs
grep -o 'data-testid="[^"]*"' app/views/restaurants/sections/_import_2025.html.erb | wc -l
```

---

## Success Indicators

### ✅ Everything is Working When:

1. **Console test passes**
   ```ruby
   ApplicationController.helpers.test_id('test')
   # => {"data-testid"=>"test"}
   ```

2. **HTML contains test IDs**
   - Inspect element shows `data-testid="..."`
   - Console JavaScript finds elements

3. **Tests pass**
   ```bash
   rails test test/system/import_automation_test.rb
   # => 6 runs, X assertions, 0 failures
   ```

4. **Helper methods work**
   ```ruby
   # In test
   find_testid('import-form')     # ✅ Found
   click_testid('import-submit-btn')  # ✅ Works
   fill_testid('import-name-input', 'Menu')  # ✅ Fills
   ```

---

## Next Steps After Verification

Once everything above is working:

1. ✅ **Celebrate!** Setup is complete
2. 📝 **Update another view** - Try login page next
3. 🧪 **Write more tests** - Add authentication tests
4. 📖 **Share with team** - Show them the Quick Start Guide
5. 🔄 **Iterate** - One view at a time

---

**Need Help?**
- Review: `/docs/testing/QUICK_START_GUIDE.md`
- Strategy: `/docs/testing/UI_TEST_AUTOMATION_PLAN.md`
- Progress: `/docs/testing/IMPLEMENTATION_CHECKLIST.md`

---

**Last Updated:** November 13, 2024
**Status:** Ready for verification ✅
