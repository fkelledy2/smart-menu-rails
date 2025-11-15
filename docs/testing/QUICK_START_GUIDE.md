# Test-Friendly UI - Quick Start Guide

## TL;DR

Add `data-testid` attributes to make elements easily testable:

```erb
<!-- Instead of this -->
<button class="btn btn-primary">Submit</button>

<!-- Do this -->
<button class="btn btn-primary" data-testid="submit-btn">Submit</button>
```

Then in tests:
```ruby
# Instead of this
find('.btn-primary').click

# Do this
find('[data-testid="submit-btn"]').click
```

---

## 5-Minute Setup

### 1. Create the Helper (Copy-Paste)

Create `app/helpers/concerns/testable.rb`:

```ruby
module Testable
  def test_id(id)
    return {} unless Rails.env.test? || Rails.env.development?
    { 'data-testid': id }
  end
end
```

### 2. Include in ApplicationHelper

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  include Testable
  # ... rest
end
```

### 3. Use in Views

```erb
<button <%= test_id('my-button') %>>Click Me</button>
<%= f.text_field :email, **test_id('email-input') %>
```

### 4. Use in Tests

```ruby
find('[data-testid="my-button"]').click
fill_in find('[data-testid="email-input"]')[:id], with: 'test@example.com'
```

---

## Naming Cheat Sheet

| Element | Pattern | Example |
|---------|---------|---------|
| **Buttons** | `{action}-btn` | `submit-btn`, `delete-btn`, `cancel-btn` |
| **Forms** | `{name}-form` | `login-form`, `user-form`, `import-form` |
| **Inputs** | `{field}-input` | `email-input`, `password-input`, `name-input` |
| **Links** | `{action}-link` | `edit-link`, `view-link`, `delete-link` |
| **Sections** | `{name}-section` | `header-section`, `sidebar-section` |
| **Lists** | `{name}-list` | `users-list`, `menus-list` |
| **List Items** | `{name}-{id}` | `user-42`, `menu-7` |
| **Messages** | `{type}-message` | `error-message`, `success-message` |

---

## Common Patterns

### Forms

```erb
<%= form_with model: @user, **test_id('user-form') do |f| %>
  <%= f.label :email %>
  <%= f.email_field :email, **test_id('user-email-input') %>
  
  <%= f.label :password %>
  <%= f.password_field :password, **test_id('user-password-input') %>
  
  <%= f.submit 'Sign Up', **test_id('user-submit-btn') %>
<% end %>
```

### Lists with Actions

```erb
<div <%= test_id('menus-list') %>>
  <% @menus.each do |menu| %>
    <div <%= test_id("menu-#{menu.id}") %>>
      <h3><%= menu.name %></h3>
      <%= link_to 'Edit', edit_menu_path(menu), **test_id("edit-menu-#{menu.id}-link") %>
      <%= button_to 'Delete', menu, method: :delete, **test_id("delete-menu-#{menu.id}-btn") %>
    </div>
  <% end %>
</div>
```

### Navigation

```erb
<nav <%= test_id('main-nav') %>>
  <%= link_to 'Home', root_path, **test_id('home-link') %>
  <%= link_to 'Menus', menus_path, **test_id('menus-link') %>
  <%= link_to 'Settings', settings_path, **test_id('settings-link') %>
</nav>
```

### Modals

```erb
<div class="modal" <%= test_id('confirm-modal') %>>
  <h2>Are you sure?</h2>
  <button <%= test_id('modal-confirm-btn') %>>Yes</button>
  <button <%= test_id('modal-cancel-btn') %>>No</button>
</div>
```

---

## Testing Helpers

### Basic Helpers

Add to `test/test_helper.rb` or create `test/support/test_helpers.rb`:

```ruby
module TestHelpers
  def find_testid(id)
    find("[data-testid='#{id}']")
  end
  
  def click_testid(id)
    find_testid(id).click
  end
  
  def fill_testid(id, value)
    input = find_testid(id)
    fill_in input[:id], with: value
  end
  
  def within_testid(id, &block)
    within("[data-testid='#{id}']", &block)
  end
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include TestHelpers
end
```

### Usage in Tests

```ruby
test 'user can login' do
  visit login_path
  
  fill_testid('login-email-input', 'user@example.com')
  fill_testid('login-password-input', 'password')
  click_testid('login-submit-btn')
  
  assert_text 'Welcome'
end
```

---

## Priority: What to Add First

### High Priority (Do First)
1. ✅ **Form submit buttons**
2. ✅ **Form inputs (email, password, text)**
3. ✅ **Delete/destroy actions**
4. ✅ **Navigation links**
5. ✅ **Success/error messages**

### Medium Priority (Do Second)
6. ⚠️ List items
7. ⚠️ Edit/view links
8. ⚠️ Modal dialogs
9. ⚠️ Tabs/sections
10. ⚠️ Search forms

### Low Priority (Nice to Have)
11. 📝 Informational text
12. 📝 Images/icons
13. 📝 Decorative elements

---

## Real Example: OCR Import

### Before (Fragile)

```erb
<!-- View -->
<div class="content-card-2025">
  <%= form_with model: @import do |f| %>
    <%= f.text_field :name, class: 'form-control-2025' %>
    <%= f.file_field :pdf %>
    <button type="submit" class="btn btn-danger">Upload</button>
  <% end %>
</div>

<!-- Test -->
find('.content-card-2025 .form-control-2025').fill_in with: 'Menu'
attach_file 'import[pdf]', 'menu.pdf'
find('.btn-danger').click
```

### After (Stable)

```erb
<!-- View -->
<div class="content-card-2025" <%= test_id('import-form-card') %>>
  <%= form_with model: @import, **test_id('import-form') do |f| %>
    <%= f.text_field :name, class: 'form-control-2025', **test_id('import-name-input') %>
    <%= f.file_field :pdf, **test_id('import-pdf-input') %>
    <button type="submit" class="btn btn-danger" <%= test_id('import-submit-btn') %>>
      Upload
    </button>
  <% end %>
</div>

<!-- Test -->
fill_testid('import-name-input', 'Menu')
attach_file find_testid('import-pdf-input')[:id], 'menu.pdf'
click_testid('import-submit-btn')
```

---

## Troubleshooting

### "Attribute isn't appearing in HTML"

**Problem:** Test ID not in rendered HTML
**Solution:** Check environment - test IDs only show in test/dev

```ruby
# Verify in helper
def test_id(id)
  return {} unless Rails.env.test? || Rails.env.development?
  { 'data-testid': id }
end
```

### "Can't find element"

**Problem:** Element exists but selector is wrong
**Solution:** Inspect HTML, check exact `data-testid` value

```ruby
# Debug: print all test IDs on page
page.all('[data-testid]').each do |el|
  puts el['data-testid']
end
```

### "Syntax error with **"

**Problem:** Double splat operator not working
**Solution:** Make sure method returns a Hash

```ruby
# ✅ Correct
def test_id(id)
  { 'data-testid': id }
end

# Then use:
<%= f.text_field :name, **test_id('name-input') %>
```

---

## Rules of Thumb

1. **One test ID per interactive element**
   - Buttons: Always
   - Links: Always
   - Inputs: Always
   - Divs: Only if needed for test context

2. **Use descriptive names**
   - ✅ `delete-user-btn`
   - ❌ `btn-1`

3. **Be consistent**
   - Always use `-btn` for buttons
   - Always use `-input` for inputs
   - Always use `-link` for links

4. **Keep them stable**
   - Don't change test IDs without updating tests
   - Treat them as part of the API

5. **Add to new code**
   - All new features MUST have test IDs
   - Retrofit when touching old code

---

## Next Steps

1. ✅ **Read this guide**
2. ✅ **Copy the helper module**
3. ✅ **Pick one page to update**
4. ✅ **Add 5-10 test IDs**
5. ✅ **Write/update tests to use them**
6. ✅ **Repeat**

---

## Getting Help

- **Full Plan:** See `/docs/testing/UI_TEST_AUTOMATION_PLAN.md`
- **Examples:** Check `/test/system/*_test.rb`
- **Questions:** Ask the team!

---

**Remember:** Start small, be consistent, and iterate. You don't need to update everything at once!
