# **2025 Design System - Component Usage Guide**

Quick reference for using the new design system components.

---

## **🎨 Design System Basics**

### **Import in your views:**
The design system is automatically imported via `application.bootstrap.scss`. All components are available globally.

### **CSS Variables:**
Access design tokens anywhere:
```scss
.my-component {
  color: var(--color-primary);
  padding: var(--space-4);
  border-radius: var(--radius-md);
}
```

---

## **🔘 Buttons**

### **Basic Usage:**

```erb
<!-- Primary button (main CTAs) -->
<button class="btn-2025 btn-2025-primary btn-2025-md">
  Save Changes
</button>

<!-- Secondary button (supporting actions) -->
<button class="btn-2025 btn-2025-secondary btn-2025-md">
  Cancel
</button>

<!-- Ghost button (tertiary actions) -->
<button class="btn-2025 btn-2025-ghost btn-2025-md">
  Learn More
</button>

<!-- Danger button (destructive) -->
<button class="btn-2025 btn-2025-danger btn-2025-md">
  Delete
</button>
```

### **Sizes:**

```erb
<!-- Small (36px min-height) -->
<button class="btn-2025 btn-2025-primary btn-2025-sm">Small</button>

<!-- Medium (44px min-height - touch-friendly) -->
<button class="btn-2025 btn-2025-primary btn-2025-md">Medium</button>

<!-- Large (52px min-height) -->
<button class="btn-2025 btn-2025-primary btn-2025-lg">Large</button>
```

### **With Icons:**

```erb
<button class="btn-2025 btn-2025-primary btn-2025-md">
  <i class="bi bi-plus"></i>
  Add Menu
</button>
```

### **Loading State:**

```erb
<button class="btn-2025 btn-2025-primary btn-2025-md btn-2025-loading">
  Saving...
</button>
```

### **Full Width:**

```erb
<button class="btn-2025 btn-2025-primary btn-2025-md btn-2025-block">
  Continue
</button>
```

---

## **📝 Forms**

### **Unified Form Helper:**

```erb
<%= unified_form_with(@menu) do |form| %>
  <%= unified_text_field(form, :name, label: 'Menu Name', required: true) %>
  <%= unified_text_area(form, :description, label: 'Description', rows: 4) %>
  <%= unified_select(form, :status, Menu.statuses.keys, label: 'Status') %>
  <%= unified_checkbox(form, :active, label: 'Active') %>
  <%= unified_form_actions(cancel_path: menus_path) %>
<% end %>
```

**Features:**
- ✅ Auto-save after 1 second
- ✅ Consistent styling
- ✅ TomSelect on dropdowns
- ✅ Proper ARIA labels
- ✅ Touch-friendly (44px minimum)

### **Text Field:**

```erb
<%= unified_text_field(form, :name, 
  label: 'Menu Name',
  placeholder: 'Enter menu name...',
  help: 'This will be shown to customers',
  required: true
) %>
```

### **Text Area:**

```erb
<%= unified_text_area(form, :description, 
  label: 'Description',
  rows: 6,
  placeholder: 'Describe your menu...',
  help: 'Maximum 500 characters'
) %>
```

### **Select (with TomSelect):**

```erb
<%= unified_select(form, :status, 
  ['active', 'inactive', 'draft'],
  label: 'Status',
  prompt: 'Select status...',
  help: 'Change menu visibility'
) %>
```

**With Hash:**

```erb
<%= unified_select(form, :status, 
  Menu.statuses,  # { active: 0, inactive: 1, draft: 2 }
  label: 'Status'
) %>
```

### **Checkbox:**

```erb
<%= unified_checkbox(form, :featured, 
  label: 'Feature this menu',
  help: 'Featured menus appear first'
) %>
```

### **Form Actions:**

```erb
<!-- Right-aligned with cancel -->
<%= unified_form_actions(
  submit: 'Save Menu',
  cancel_path: menus_path,
  alignment: 'end'
) %>

<!-- Space between -->
<%= unified_form_actions(
  submit: 'Continue',
  cancel_path: back_path,
  alignment: 'between'
) %>
```

### **Manual Form Controls:**

```erb
<!-- Text input -->
<div class="form-group-2025">
  <label class="form-label-2025">Name</label>
  <input type="text" class="form-control-2025" placeholder="Enter name...">
</div>

<!-- Textarea -->
<div class="form-group-2025">
  <label class="form-label-2025">Description</label>
  <textarea class="form-control-2025" rows="4"></textarea>
</div>

<!-- Select -->
<div class="form-group-2025">
  <label class="form-label-2025">Status</label>
  <select class="form-control-2025">
    <option>Active</option>
    <option>Inactive</option>
  </select>
</div>

<!-- Checkbox -->
<div class="checkbox-2025">
  <input type="checkbox" id="agree">
  <label for="agree">I agree to terms</label>
</div>
```

---

## **🎴 Cards**

### **Basic Card:**

```erb
<div class="card-2025">
  <div class="card-2025-header">
    <h3 class="card-2025-title">Summer Menu</h3>
  </div>
  <div class="card-2025-body">
    <p>Seasonal offerings featuring fresh ingredients...</p>
  </div>
  <div class="card-2025-footer">
    <button class="btn-2025 btn-2025-primary btn-2025-sm">View Menu</button>
  </div>
</div>
```

### **Hoverable Card:**

```erb
<div class="card-2025 card-2025-hoverable">
  <div class="card-2025-body">
    <h4>Quick Action</h4>
    <p>Click to perform action</p>
  </div>
</div>
```

### **Card Grid:**

```erb
<div class="card-grid-2025 card-grid-2025-3">
  <div class="card-2025">...</div>
  <div class="card-2025">...</div>
  <div class="card-2025">...</div>
</div>
```

---

## **💾 Auto-Save**

### **Stimulus Controller:**

```erb
<form data-controller="auto-save"
      data-auto-save-url-value="<%= menu_path(@menu) %>"
      data-auto-save-method-value="patch"
      data-auto-save-debounce-value="1000">
  
  <input type="text" name="menu[name]" placeholder="Menu name...">
  <select name="menu[status]">
    <option value="active">Active</option>
    <option value="inactive">Inactive</option>
  </select>
</form>
```

**Features:**
- Text inputs: Debounced (1 second after typing stops)
- Selects/checkboxes: Immediate save
- Visual feedback: Floating "Saving..." indicator
- Error handling: Shows error message if save fails

### **Events:**

```javascript
// Listen for save events
document.addEventListener('auto-save:saved', (event) => {
  console.log('Saved:', event.detail)
})

document.addEventListener('auto-save:error', (event) => {
  console.log('Error:', event.detail)
})
```

---

## **🎨 Utility Classes**

### **Spacing:**

```html
<!-- Margin -->
<div class="m-4">Margin all sides (16px)</div>
<div class="mt-6">Margin top (24px)</div>
<div class="mx-8">Margin horizontal (32px)</div>

<!-- Padding -->
<div class="p-4">Padding all sides (16px)</div>
<div class="py-6">Padding vertical (24px)</div>
```

**Values:** 0, 1 (4px), 2 (8px), 3 (12px), 4 (16px), 5 (20px), 6 (24px), 8 (32px), 10 (40px), 12 (48px)

### **Typography:**

```html
<p class="text-xs">Extra small (12px)</p>
<p class="text-sm">Small (14px)</p>
<p class="text-base">Base (16px)</p>
<p class="text-lg">Large (18px)</p>
<p class="text-2xl">2XL (24px)</p>

<p class="font-normal">Normal weight</p>
<p class="font-medium">Medium weight</p>
<p class="font-semibold">Semibold weight</p>
<p class="font-bold">Bold weight</p>
```

### **Colors:**

```html
<p class="text-gray-500">Gray text</p>
<p class="text-primary">Primary color</p>
<p class="text-success">Success color</p>
<p class="text-danger">Danger color</p>

<div class="bg-white">White background</div>
<div class="bg-gray-50">Light gray background</div>
<div class="bg-primary">Primary background</div>
```

### **Flexbox:**

```html
<div class="flex items-center justify-between gap-4">
  <span>Left</span>
  <span>Right</span>
</div>

<div class="flex flex-col gap-2">
  <div>Item 1</div>
  <div>Item 2</div>
</div>
```

### **Borders & Radius:**

```html
<div class="border rounded-md">With border</div>
<div class="border-t">Top border only</div>
<div class="rounded-lg">Large radius (12px)</div>
<div class="rounded-full">Pill shape</div>
```

### **Shadows:**

```html
<div class="shadow-sm">Small shadow</div>
<div class="shadow-md">Medium shadow</div>
<div class="shadow-lg">Large shadow</div>
```

---

## **📱 Responsive Design**

### **Touch Targets:**

All interactive elements have minimum 44px height on mobile:
```erb
<!-- Automatically touch-friendly -->
<button class="btn-2025 btn-2025-md">Button</button>
<input type="text" class="form-control-2025">
```

### **Mobile Breakpoints:**

```scss
@media (max-width: 768px) {
  // Mobile-specific styles
}
```

---

## **♿ Accessibility**

### **Focus States:**

All interactive elements have visible focus indicators:
- Blue outline (2px)
- 2px offset
- 3px shadow

### **ARIA Labels:**

```erb
<button class="btn-2025 btn-2025-icon" aria-label="Close">
  <i class="bi bi-x-lg"></i>
</button>

<label class="form-label-2025" for="menu-name">Menu Name</label>
<input id="menu-name" class="form-control-2025">
```

---

## **🎯 Migration Path**

### **Option 1: New Pages Only**

Use new system for new features:
```erb
<!-- New feature -->
<%= unified_form_with(@new_entity) do |form| %>
  <%= unified_text_field(form, :name) %>
<% end %>
```

### **Option 2: Gradual Migration**

Update existing pages one at a time:
```erb
<!-- Old -->
<%= form_with(model: @menu) do |form| %>
  <%= form.text_field :name, class: 'form-control' %>
<% end %>

<!-- New -->
<%= unified_form_with(@menu) do |form| %>
  <%= unified_text_field(form, :name) %>
<% end %>
```

### **Option 3: Hybrid Approach**

Mix old and new:
```erb
<%= form_with(model: @menu) do |form| %>
  <!-- Use new button styles -->
  <button class="btn-2025 btn-2025-primary btn-2025-md">Save</button>
<% end %>
```

---

## **📚 Examples**

### **Complete Form Example:**

```erb
<div class="card-2025">
  <div class="card-2025-header">
    <h2 class="card-2025-title">Edit Menu</h2>
    <p class="card-2025-subtitle">Update your menu details</p>
  </div>
  
  <div class="card-2025-body">
    <%= unified_form_with(@menu) do |form| %>
      <%= unified_text_field(form, :name, 
        label: 'Menu Name',
        placeholder: 'e.g., Summer Menu 2024',
        required: true
      ) %>
      
      <%= unified_text_area(form, :description, 
        label: 'Description',
        help: 'Describe what makes this menu special',
        rows: 4
      ) %>
      
      <%= unified_select(form, :status, 
        Menu.statuses.keys,
        label: 'Status'
      ) %>
      
      <%= unified_checkbox(form, :featured, 
        label: 'Feature this menu',
        help: 'Featured menus appear first to customers'
      ) %>
      
      <%= unified_form_actions(
        submit: 'Save Menu',
        cancel_path: menus_path
      ) %>
    <% end %>
  </div>
</div>
```

---

## **🐛 Troubleshooting**

### **Auto-save not working:**

1. Check Stimulus is loaded
2. Verify `data-auto-save-url-value` is correct
3. Check browser console for errors
4. Ensure CSRF token is present

### **Styles not applying:**

1. Verify `design_system_2025.scss` is imported
2. Clear asset cache: `rails assets:clobber`
3. Check for CSS conflicts with Bootstrap

### **TomSelect not initializing:**

1. Ensure TomSelect is installed
2. Add `data-controller="tom-select"` to select
3. Check JavaScript console for errors

---

**Need help?** Check `/docs/frontend/UI_UX_REDESIGN_2025.md` for full documentation.
