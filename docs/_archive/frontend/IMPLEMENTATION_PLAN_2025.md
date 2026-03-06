# **UI/UX Redesign - Implementation Plan**

**Timeline:** 12 weeks  
**Team:** 2-3 developers + 1 designer  
**Start Date:** November 2025

---

## **Phase 1: Foundation (Weeks 1-3)**

### **Week 1: Design System**

#### **1.1 Create Base Styles**
**File:** `app/assets/stylesheets/design_system_2025.scss`

```scss
// Design System 2025
// Based on industry standards: Shopify Polaris, Tailwind, Linear

// ============================================
// COLORS
// ============================================
:root {
  // Primary
  --color-primary: #2563EB;
  --color-primary-hover: #1D4ED8;
  --color-primary-light: #DBEAFE;
  
  // Semantic
  --color-success: #10B981;
  --color-warning: #F59E0B;
  --color-danger: #EF4444;
  --color-info: #3B82F6;
  
  // Neutrals
  --color-gray-50: #F9FAFB;
  --color-gray-100: #F3F4F6;
  --color-gray-200: #E5E7EB;
  --color-gray-300: #D1D5DB;
  --color-gray-500: #6B7280;
  --color-gray-700: #374151;
  --color-gray-900: #111827;
  
  // Spacing (8px grid)
  --space-1: 0.25rem;  // 4px
  --space-2: 0.5rem;   // 8px
  --space-4: 1rem;     // 16px
  --space-6: 1.5rem;   // 24px
  --space-8: 2rem;     // 32px
  
  // Typography
  --font-family: 'Inter', -apple-system, sans-serif;
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-2xl: 1.5rem;
  
  // Shadows
  --shadow-sm: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  
  // Border radius
  --radius-md: 8px;
  --radius-lg: 12px;
}
```

#### **1.2 Button System**
**File:** `app/assets/stylesheets/components/_buttons_2025.scss`

```scss
.btn-2025 {
  // Base button
  font-family: var(--font-family);
  font-weight: 500;
  border-radius: var(--radius-md);
  transition: all 0.2s;
  border: none;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  
  &:active {
    transform: scale(0.98);
  }
  
  // Sizes
  &-sm {
    padding: var(--space-2) var(--space-4);
    font-size: var(--text-sm);
    min-height: 36px;
  }
  
  &-md {
    padding: var(--space-3) var(--space-6);
    font-size: var(--text-base);
    min-height: 44px;  // Touch-friendly
  }
  
  // Variants
  &-primary {
    background: var(--color-primary);
    color: white;
    &:hover { background: var(--color-primary-hover); }
  }
  
  &-secondary {
    background: white;
    border: 1.5px solid var(--color-gray-300);
    color: var(--color-gray-700);
    &:hover { background: var(--color-gray-50); }
  }
  
  &-danger {
    background: var(--color-danger);
    color: white;
    &:hover { background: #DC2626; }
  }
}
```

#### **1.3 Form Controls**
**File:** `app/assets/stylesheets/components/_forms_2025.scss`

```scss
.form-control-2025 {
  font-family: var(--font-family);
  padding: var(--space-3) var(--space-4);
  border: 1.5px solid var(--color-gray-300);
  border-radius: var(--radius-md);
  font-size: var(--text-base);
  min-height: 44px;
  transition: all 0.2s;
  width: 100%;
  
  &:focus {
    outline: none;
    border-color: var(--color-primary);
    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
  }
  
  &:disabled {
    background: var(--color-gray-50);
    color: var(--color-gray-500);
    cursor: not-allowed;
  }
}

.form-label-2025 {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--color-gray-700);
  margin-bottom: var(--space-2);
  display: block;
}
```

---

### **Week 2: Core Components**

#### **2.1 Resource List Component**
**File:** `app/components/resource_list_component.rb`

```ruby
class ResourceListComponent < ViewComponent::Base
  def initialize(items:, columns:, title:, actions: [])
    @items = items
    @columns = columns
    @title = title
    @actions = actions
  end
  
  # Renders consistent list view for any entity
  # Used by: Menus, Menu Sections, Menu Items, Employees, Tables, etc.
end
```

**Template:** `app/components/resource_list_component.html.erb`

```erb
<div class="resource-list-2025">
  <div class="resource-list-header">
    <h2><%= @title %></h2>
    <div class="resource-list-actions">
      <input type="search" placeholder="Search..." class="form-control-2025">
      <% @actions.each do |action| %>
        <%= link_to action[:label], action[:path], class: action[:class] %>
      <% end %>
    </div>
  </div>
  
  <div class="resource-list-filters">
    <!-- Filters go here -->
  </div>
  
  <div class="resource-list-table">
    <% @items.each do |item| %>
      <div class="resource-list-row">
        <div class="checkbox">
          <input type="checkbox" value="<%= item.id %>">
        </div>
        <% @columns.each do |column| %>
          <div class="resource-list-cell">
            <%= render_cell(item, column) %>
          </div>
        <% end %>
        <div class="resource-list-actions-cell">
          <%= render 'shared/quick_actions_menu', item: item %>
        </div>
      </div>
    <% end %>
  </div>
  
  <div class="resource-list-footer">
    <span><%= pluralize(@items.count, 'item') %></span>
  </div>
</div>
```

#### **2.2 Side Drawer Component**
**File:** `app/components/side_drawer_component.rb`

```ruby
class SideDrawerComponent < ViewComponent::Base
  def initialize(title:, width: '500px')
    @title = title
    @width = width
  end
end
```

**Template:** `app/components/side_drawer_component.html.erb`

```erb
<div class="side-drawer-2025" 
     data-controller="side-drawer" 
     style="--drawer-width: <%= @width %>">
  <div class="side-drawer-overlay" data-action="click->side-drawer#close"></div>
  <div class="side-drawer-content">
    <div class="side-drawer-header">
      <h3><%= @title %></h3>
      <button type="button" 
              class="btn-icon" 
              data-action="side-drawer#close"
              aria-label="Close">
        <i class="bi bi-x-lg"></i>
      </button>
    </div>
    <div class="side-drawer-body">
      <%= content %>
    </div>
  </div>
</div>
```

---

### **Week 3: Auto-save & Validation**

#### **3.1 Universal Form Helper**
**File:** `app/helpers/form_helper_2025.rb`

```ruby
module FormHelper2025
  # Universal form helper that works for ANY entity
  def unified_form_with(model, **options, &block)
    entity_type = model.class.name.underscore
    
    defaults = {
      data: {
        controller: 'auto-save unified-form',
        'auto-save-url-value': polymorphic_path(model),
        'auto-save-method-value': model.persisted? ? 'patch' : 'post',
        'unified-form-entity-value': entity_type
      },
      class: 'unified-form-2025'
    }
    
    form_with(model: model, **options.deep_merge(defaults), &block)
  end
  
  # Enhanced select with consistent styling
  def unified_select(form, attribute, options, html_options = {})
    html_options[:class] = "form-control-2025 #{html_options[:class]}"
    html_options[:data] ||= {}
    html_options[:data][:controller] = 'tom-select'
    
    form.select(attribute, options, 
      { prompt: 'Select...' }, 
      html_options
    )
  end
end
```

#### **3.2 Auto-save Stimulus Controller**
**File:** `app/javascript/controllers/auto_save_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"
import { debounce } from "lodash-es"

export default class extends Controller {
  static values = {
    url: String,
    method: String
  }
  
  static targets = ["status"]
  
  connect() {
    this.save = debounce(this.save.bind(this), 1000)
    this.element.querySelectorAll('input, textarea, select').forEach(el => {
      el.addEventListener('input', () => this.save())
      el.addEventListener('change', () => this.save())
    })
  }
  
  async save() {
    this.showSaving()
    
    const formData = new FormData(this.element)
    const response = await fetch(this.urlValue, {
      method: this.methodValue,
      body: formData,
      headers: {
        'X-CSRF-Token': this.csrfToken(),
        'Accept': 'application/json'
      }
    })
    
    if (response.ok) {
      this.showSaved()
    } else {
      this.showError()
    }
  }
  
  showSaving() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = 'Saving...'
      this.statusTarget.className = 'status-saving'
    }
  }
  
  showSaved() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = '✓ Saved'
      this.statusTarget.className = 'status-saved'
      setTimeout(() => {
        this.statusTarget.textContent = ''
      }, 2000)
    }
  }
  
  showError() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = '⚠️ Save failed'
      this.statusTarget.className = 'status-error'
    }
  }
  
  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
```

---

## **Phase 2: Paper-to-Digital (Weeks 4-6)**

### **Week 4: OCR Upload Redesign**

#### **4.1 New Upload Page**
**File:** `app/views/ocr_menu_imports/new.html.erb`

```erb
<div class="onboarding-container-2025">
  <div class="onboarding-header">
    <h1>Upload Your Menu</h1>
    <p>We'll scan and digitize it in minutes</p>
  </div>
  
  <div class="upload-zone-2025" 
       data-controller="file-upload"
       data-action="drop->file-upload#handleDrop
                    dragover->file-upload#handleDragOver
                    dragleave->file-upload#handleDragLeave">
    
    <div class="upload-zone-icon">
      <i class="bi bi-cloud-upload"></i>
    </div>
    
    <h3>Drag PDF here or click to browse</h3>
    <p class="text-muted">We support scanned PDFs and photos (up to 20 pages)</p>
    
    <%= form_with(model: [@restaurant, @ocr_menu_import], 
                  html: { class: 'upload-form' }) do |f| %>
      <%= f.file_field :pdf_file, 
          accept: 'application/pdf,image/*',
          data: { 'file-upload-target': 'input' },
          class: 'd-none' %>
      
      <button type="button" 
              class="btn-2025 btn-2025-primary"
              onclick="this.previousElementSibling.click()">
        Choose File
      </button>
    <% end %>
    
    <div class="upload-tips">
      <h4>💡 Tips for best results:</h4>
      <ul>
        <li>Use your phone camera for quick upload</li>
        <li>Ensure text is clear and well-lit</li>
        <li>Multiple pages? Scan as one PDF</li>
      </ul>
    </div>
  </div>
</div>
```

#### **4.2 Processing Page with Progress**
**File:** `app/views/ocr_menu_imports/show.html.erb` (simplified)

```erb
<% if @ocr_menu_import.processing? %>
  <div class="processing-container-2025">
    <div class="processing-animation">
      🤖
    </div>
    
    <h2>Reading your menu...</h2>
    
    <div class="progress-bar-2025">
      <div class="progress-bar-fill" 
           style="width: <%= @ocr_menu_import.progress %>%"></div>
    </div>
    <p class="progress-text"><%= @ocr_menu_import.progress %>% complete</p>
    
    <div class="processing-stats">
      <div class="stat">
        <span class="stat-icon">✓</span>
        <span class="stat-label">Sections found</span>
        <span class="stat-value"><%= @ocr_menu_import.ocr_menu_sections.count %></span>
      </div>
      <div class="stat">
        <span class="stat-icon">✓</span>
        <span class="stat-label">Items extracted</span>
        <span class="stat-value"><%= @ocr_menu_import.ocr_menu_items.count %></span>
      </div>
    </div>
    
    <p class="text-muted">~<%= time_remaining %> remaining</p>
    
    <%= turbo_stream_from @ocr_menu_import %>
  </div>
<% end %>
```

### **Week 5: Review/Approve Redesign**

#### **5.1 Improved Review Interface**
```erb
<div class="review-container-2025">
  <div class="review-header">
    <h2>Review Your Menu</h2>
    <p>Click any item to edit • Drag to reorder</p>
    
    <div class="review-actions">
      <label class="checkbox-2025">
        <input type="checkbox" data-action="change->review#toggleAll">
        <span>Approve all (<%= @total_items %>)</span>
      </label>
      
      <button class="btn-2025 btn-2025-primary btn-2025-lg"
              data-action="review#publish">
        Publish Menu →
      </button>
    </div>
  </div>
  
  <div class="sections-list-2025">
    <% @ocr_menu_import.ocr_menu_sections.ordered.each do |section| %>
      <%= render 'section_card', section: section %>
    <% end %>
  </div>
</div>
```

---

## **Phase 3: Unified CRUD (Weeks 7-9)**

### **Week 7-8: Update All List Pages**

**Files to Update:**
- `app/views/menus/index.html.erb`
- `app/views/menusections/index.html.erb`
- `app/views/menuitems/index.html.erb`
- `app/views/employees/index.html.erb`
- `app/views/tablesettings/index.html.erb`

**Pattern:**
```erb
<%= render ResourceListComponent.new(
  items: @menus,
  title: "Menus",
  columns: [
    { key: :name, label: "Name", primary: true },
    { key: :status, label: "Status", type: :badge },
    { key: :updated_at, label: "Modified", type: :date }
  ],
  actions: [
    { label: "+ New Menu", path: new_restaurant_menu_path(@restaurant), class: "btn-2025 btn-2025-primary" }
  ]
) %>
```

### **Week 9: Side Drawer Implementation**

**Files to Update:**
- Create `app/views/menus/_edit_drawer.html.erb`
- Update `app/views/menus/edit.html.erb`
- Similar for all entities

---

## **Phase 4: Power Features (Weeks 10-12)**

### **Week 10: Command Palette**
**File:** `app/javascript/controllers/command_palette_controller.js`

```javascript
// Cmd+K to search everything
// Fuzzy search across menus, items, sections, etc.
```

### **Week 11: Bulk Operations**
**File:** `app/javascript/controllers/bulk_actions_controller.js`

```javascript
// Checkbox selection
// Action bar when items selected
// Bulk activate/deactivate/delete
```

### **Week 12: Polish & Testing**
- Loading skeletons
- Empty states
- Error states
- Mobile testing
- User acceptance testing

---

## **📋 Checklist**

### **Phase 1**
- [ ] Design system stylesheet
- [ ] Button components
- [ ] Form controls
- [ ] Resource list component
- [ ] Side drawer component
- [ ] Auto-save functionality
- [ ] Component showcase page

### **Phase 2**
- [ ] OCR upload redesign
- [ ] Processing visualization
- [ ] Review/approve interface
- [ ] Mobile camera support
- [ ] Error handling

### **Phase 3**
- [ ] All list pages updated
- [ ] Side drawer for edits
- [ ] Breadcrumb navigation
- [ ] Consistent status badges
- [ ] Mobile responsive

### **Phase 4**
- [ ] Command palette
- [ ] Keyboard shortcuts
- [ ] Bulk operations
- [ ] Loading states
- [ ] Empty states
- [ ] User testing (5 managers)

---

## **🎯 Success Metrics**

Track these weekly:
- [ ] Time to first menu (target: <10 min)
- [ ] Mobile traffic % (target: 60%+)
- [ ] Support tickets (target: -70%)
- [ ] Task completion rate (target: 95%+)
- [ ] NPS score (target: 50+)

---

**Ready to start Phase 1!** 🚀
