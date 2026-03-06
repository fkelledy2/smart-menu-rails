# **🎨 Edit Pages Redesign - Visual Mockups**

**Purpose:** Detailed visual specifications for implementing the redesigned edit pages

---

## **🏗️ 1. Restaurant Edit Page - Sidebar Layout**

### **Desktop Layout (> 1024px)**

```
┌────────────────────────────────────────────────────────────────────────┐
│  🍕 Pizza Place                            [👤 Profile] [📊 Analytics]  │
│                                           [Preview Site] [• • •]        │
├─────────────┬──────────────────────────────────────────────────────────┤
│             │                                                            │
│ 📋 CORE     │  ⚡ QUICK ACTIONS                                         │
│             │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
│ ✓ Details   │  │  🍽️          │ │  ✨          │ │  📱          │    │
│   Address   │  │  New Menu    │ │  Bulk Import │ │  QR Code     │    │
│   Hours     │  │              │ │              │ │              │    │
│   Contact   │  └──────────────┘ └──────────────┘ └──────────────┘    │
│             │                                                            │
│ 🍽️ MENUS    │  📊 OVERVIEW                                              │
│             │  ┌────────────────────────────────────────────────────┐  │
│   All (12)  │  │  📈 This Month                                     │  │
│   Active(9) │  │  3 Menus  │  147 Items  │  $2,450 Revenue       │  │
│   Draft (3) │  │  ─────────────────────────────────────────────────│  │
│             │  │  🔥 Popular: Margherita Pizza (124 orders)        │  │
│ 👥 TEAM     │  └────────────────────────────────────────────────────┘  │
│             │                                                            │
│   Staff (8) │  📝 RESTAURANT DETAILS                                    │
│   Roles     │  ┌────────────────────────────────────────────────────┐  │
│             │  │                                                     │  │
│ ⚙️ SETUP    │  │  Name *        [Pizza Place                    ]   │  │
│             │  │  Cuisine       [Italian              ▼]             │  │
│   Catalog   │  │  Phone         [+1 555 0100            ]            │  │
│   Tables    │  │  Email         [info@pizzaplace.com    ]            │  │
│   Ordering  │  │  Website       [www.pizzaplace.com     ]            │  │
│   Advanced  │  │                                                     │  │
│             │  │  Description                                        │  │
│             │  │  ┌──────────────────────────────────────────────┐  │  │
│             │  │  │ Authentic Italian pizzeria serving Naples-  │  │  │
│             │  │  │ style wood-fired pizzas since 2015...       │  │  │
│             │  │  └──────────────────────────────────────────────┘  │  │
│             │  │                                                     │  │
│             │  │  📍 ADDRESS                                         │  │
│             │  │  [123 Main Street                      ]  🗺️       │  │
│             │  │  [                                      ]            │  │
│             │  │  [New York, NY 10001                   ]            │  │
│             │  │                                                     │  │
│             │  │  ✓ Auto-saved 2 seconds ago                        │  │
│             │  └────────────────────────────────────────────────────┘  │
│             │                                                            │
│             │                                                            │
└─────────────┴──────────────────────────────────────────────────────────┘
      240px                         ~1000px+
```

### **Sidebar Structure**

```scss
// Sidebar styles
.restaurant-sidebar {
  width: 240px;
  background: var(--color-gray-50);
  border-right: 1px solid var(--color-gray-200);
  height: 100vh;
  position: sticky;
  top: 0;
  overflow-y: auto;
}

.sidebar-section {
  padding: var(--space-4) 0;
  border-bottom: 1px solid var(--color-gray-200);
  
  &:last-child {
    border-bottom: none;
  }
}

.sidebar-section-title {
  padding: var(--space-2) var(--space-4);
  font-size: var(--text-xs);
  font-weight: var(--font-semibold);
  color: var(--color-gray-500);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.sidebar-link {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  color: var(--color-gray-700);
  text-decoration: none;
  transition: all var(--transition-base);
  
  &:hover {
    background: var(--color-gray-100);
    color: var(--color-gray-900);
  }
  
  &.active {
    background: var(--color-primary-light);
    color: var(--color-primary);
    border-left: 3px solid var(--color-primary);
    font-weight: var(--font-semibold);
  }
}

.sidebar-link-badge {
  margin-left: auto;
  background: var(--color-gray-200);
  color: var(--color-gray-700);
  font-size: var(--text-xs);
  padding: 2px 8px;
  border-radius: var(--radius-full);
}
```

### **Mobile Layout (< 768px)**

```
┌────────────────────────────────┐
│  ☰  Pizza Place    [👤] [•••]  │
├────────────────────────────────┤
│                                 │
│  📊 OVERVIEW                    │
│  ┌──────────────────────────┐  │
│  │ 3 Menus │ 147 Items      │  │
│  └──────────────────────────┘  │
│                                 │
│  📝 DETAILS                     │
│  Name:  [Pizza Place      ]    │
│  Phone: [+1 555 0100      ]    │
│  ...                            │
│                                 │
└────────────────────────────────┘

// Sidebar becomes hamburger menu
☰ (tap) → Slide-out navigation
```

---

## **🍽️ 2. Menu Edit Page - Single Page Layout**

### **Complete Layout**

```
┌──────────────────────────────────────────────────────────────────────┐
│  ← Menus                                              [Save] [Publish] │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  📝 MENU DETAILS                                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Name *         [Summer Menu 2024                         ]    │ │
│  │  Description    [Fresh seasonal dishes featuring local...  ]   │ │
│  │                 [                                          ]    │ │
│  │                                                                 │ │
│  │  🏷️ Menu Type     ⚪ Regular  ⚪ Seasonal  ⚫ Special          │ │
│  │  💰 Price Range   [$12] to [$45]                              │ │
│  │                                                                 │ │
│  │  ✓ Auto-saved 5 seconds ago                                   │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  🕐 AVAILABILITY                                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  ☑️ All Day                                                     │ │
│  │  ☐ Lunch Only (11:00 AM - 3:00 PM)                            │ │
│  │  ☐ Dinner Only (5:00 PM - 10:00 PM)                           │ │
│  │  ☐ Custom Schedule  [Configure ▼]                             │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  🗂️ MENU SECTIONS (4)                            [+ Add Section]     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  ▼ ⋮⋮ Appetizers                          12 items   [⚙️ Edit] │ │
│  │     ┌──────────────────────────────────────────────────────┐   │ │
│  │     │  ⋮⋮ Bruschetta al Pomodoro            $8.00  [✏️]    │   │ │
│  │     │     Fresh tomatoes, basil, garlic...               │   │ │
│  │     │  ⋮⋮ Calamari Fritti                  $12.00  [✏️]    │   │ │
│  │     │     Lightly fried calamari rings...                │   │ │
│  │     │  ⋮⋮ Caprese Salad                    $10.00  [✏️]    │   │ │
│  │     │     Fresh mozzarella, tomatoes...                  │   │ │
│  │     │                                                      │   │ │
│  │     │  [+ Add Item to Appetizers]                         │   │ │
│  │     └──────────────────────────────────────────────────────┘   │ │
│  │                                                                 │ │
│  │  ▶ ⋮⋮ Main Courses                        18 items   [⚙️ Edit] │ │
│  │  ▶ ⋮⋮ Desserts                             8 items   [⚙️ Edit] │ │
│  │  ▶ ⋮⋮ Beverages                           15 items   [⚙️ Edit] │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  📊 MENU STATISTICS                                                  │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐         │
│  │   4         │   53        │  $12 - $45  │   $850/wk   │         │
│  │ Sections    │ Total Items │ Price Range │  Revenue    │         │
│  └─────────────┴─────────────┴─────────────┴─────────────┘         │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

### **Expandable Section Component**

```html
<div class="menu-section-card-2025" data-controller="expandable">
  <!-- Section Header -->
  <div class="menu-section-header"
       data-action="click->expandable#toggle">
    <div class="flex items-center gap-3 flex-1">
      <!-- Expand/Collapse Icon -->
      <i class="bi bi-chevron-down expand-icon"
         data-expandable-target="icon"></i>
      
      <!-- Drag Handle -->
      <i class="bi bi-grip-vertical drag-handle"></i>
      
      <!-- Section Name -->
      <h3 class="section-name">Appetizers</h3>
      
      <!-- Item Count Badge -->
      <span class="badge badge-info-2025">12 items</span>
      
      <!-- Actions -->
      <div class="ml-auto flex gap-2">
        <button class="btn-2025 btn-2025-ghost btn-2025-sm"
                data-action="click->menu#editSection">
          <i class="bi bi-gear"></i> Settings
        </button>
        <button class="btn-2025 btn-2025-ghost btn-2025-sm"
                data-action="click->menu#addItem">
          <i class="bi bi-plus"></i> Add Item
        </button>
      </div>
    </div>
  </div>
  
  <!-- Section Content (Collapsible) -->
  <div class="menu-section-content"
       data-expandable-target="content"
       style="display: none;">
    <!-- Menu Items List -->
    <div class="menu-items-list">
      <!-- Individual items here -->
    </div>
  </div>
</div>
```

### **Drag-to-Reorder Interaction**

```
Initial State:
┌─────────────────────────────┐
│ ⋮⋮ Appetizers    12 items   │
│ ⋮⋮ Main Courses  18 items   │
│ ⋮⋮ Desserts       8 items   │
└─────────────────────────────┘

Dragging:
┌─────────────────────────────┐
│ ⋮⋮ Main Courses  18 items   │  ← Drop zone (blue line)
│ ╔═══════════════════════════╗
│ ║ ⋮⋮ Appetizers  12 items  ║  ← Being dragged (shadow)
│ ╚═══════════════════════════╝
│ ⋮⋮ Desserts       8 items   │
└─────────────────────────────┘

After Drop:
┌─────────────────────────────┐
│ ⋮⋮ Main Courses  18 items   │
│ ⋮⋮ Appetizers    12 items   │  ← New position
│ ⋮⋮ Desserts       8 items   │
└─────────────────────────────┘
✓ Order saved automatically
```

---

## **🥗 3. Section Edit - Slide-Over Panel**

### **Slide-Over Panel from Right**

```
┌──────────────────────────────────────────────────────────────────────┐
│  Menu: Summer 2024                                                    │
├──────────────────────────────────────────────────────────────────────┤
│                                            ┌─────────────────────────┐│
│  🗂️ SECTIONS                               │ 📝 EDIT SECTION         ││
│  ┌──────────────────────────────────┐     │ ─────────────────────── ││
│  │ ⋮⋮ Appetizers      12 items      │     │                         ││
│  │ ⋮⋮ Main Courses    18 items      │     │ Name *                  ││
│  │ ⋮⋮ Desserts         8 items      │     │ [Appetizers          ] ││
│  │ ⋮⋮ Beverages       15 items      │     │                         ││
│  └──────────────────────────────────┘     │ Description             ││
│                                            │ ┌─────────────────────┐ ││
│                                            │ │ Start your meal     │ ││
│                                            │ │ with our fresh...   │ ││
│                                            │ └─────────────────────┘ ││
│                                            │                         ││
│                                            │ 🕐 AVAILABILITY         ││
│                                            │ Available from          ││
│                                            │ [11:00 ▼] to [22:00 ▼]││
│                                            │                         ││
│                                            │ ☑️ Show on menu         ││
│                                            │ ☐ Featured section     ││
│                                            │                         ││
│                                            │ 🍽️ ITEMS (12)          ││
│                                            │ ┌─────────────────────┐││
│                                            │ │⋮⋮ Bruschetta  $8.00│││
│                                            │ │⋮⋮ Calamari   $12.00│││
│                                            │ │⋮⋮ Caprese    $10.00│││
│                                            │ │                    │││
│                                            │ │ [+ Add Item]       │││
│                                            │ └─────────────────────┘││
│                                            │                         ││
│                                            │ ─────────────────────── ││
│                                            │                         ││
│                                            │ [Delete Section]        ││
│                                            │ [Close] [Save Changes]  ││
│                                            └─────────────────────────┘│
└──────────────────────────────────────────────────────────────────────┘
        Content dimmed (overlay)                  Slide-over panel
                                                      400px wide
```

### **Animation Sequence**

```
1. User clicks "Edit Section"
   ├─ Content area dims (opacity: 0.5)
   └─ Panel slides in from right (300ms ease-out)

2. Panel fully visible
   ├─ Content scrollable
   ├─ Can edit all fields
   └─ Auto-save on changes

3. User clicks "Close" or clicks dimmed area
   ├─ Panel slides out to right (300ms ease-in)
   └─ Content brightens back to normal
```

### **Slide-Over CSS**

```scss
.slide-over-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 40;
  transition: opacity 300ms ease-out;
  
  &.hidden {
    opacity: 0;
    pointer-events: none;
  }
}

.slide-over-panel {
  position: fixed;
  right: 0;
  top: 0;
  bottom: 0;
  width: 400px;
  max-width: 90vw;
  background: white;
  box-shadow: var(--shadow-2xl);
  z-index: 50;
  overflow-y: auto;
  transform: translateX(100%);
  transition: transform 300ms ease-out;
  
  &.open {
    transform: translateX(0);
  }
}

.slide-over-header {
  position: sticky;
  top: 0;
  background: white;
  border-bottom: 1px solid var(--color-gray-200);
  padding: var(--space-4);
  z-index: 10;
}

.slide-over-body {
  padding: var(--space-6);
}

.slide-over-footer {
  position: sticky;
  bottom: 0;
  background: white;
  border-top: 1px solid var(--color-gray-200);
  padding: var(--space-4);
  display: flex;
  justify-content: space-between;
  gap: var(--space-3);
}
```

---

## **🎨 4. Inline Item Editing**

### **Edit Item Modal (Alternative to Slide-Over)**

```
┌───────────────────────────────────────────────────────────────┐
│                                                                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  ✏️ EDIT MENU ITEM                              [✕]    │  │
│  │  ──────────────────────────────────────────────────────│  │
│  │                                                         │  │
│  │  📝 BASIC INFORMATION                                   │  │
│  │  Name *         [Bruschetta al Pomodoro            ]   │  │
│  │  Description    ┌─────────────────────────────────┐    │  │
│  │                 │ Fresh tomatoes, basil, garlic    │    │  │
│  │                 │ on toasted bread                 │    │  │
│  │                 └─────────────────────────────────┘    │  │
│  │                                                         │  │
│  │  💰 PRICING                                             │  │
│  │  Base Price *   [$] [8.00]                             │  │
│  │  ☐ Multiple sizes   [Configure ▼]                      │  │
│  │                                                         │  │
│  │  🏷️ DIETARY & ALLERGENS                                │  │
│  │  ☑️ Vegetarian    ☐ Vegan       ☐ Gluten-Free         │  │
│  │  ☐ Dairy-Free    ☐ Nut-Free    ☐ Spicy               │  │
│  │                                                         │  │
│  │  Allergens: [Select... ▼]                              │  │
│  │  Selected: [Gluten ✕] [Dairy ✕]                       │  │
│  │                                                         │  │
│  │  📸 IMAGE                                               │  │
│  │  ┌────────────┐                                        │  │
│  │  │  🖼️        │  [Upload New Image]                   │  │
│  │  │  Current   │  [Generate AI Image]                  │  │
│  │  │  Image     │                                        │  │
│  │  └────────────┘                                        │  │
│  │                                                         │  │
│  │  ──────────────────────────────────────────────────────│  │
│  │                                                         │  │
│  │  [Delete Item]                [Cancel]  [Save Changes] │  │
│  │                                                         │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                                │
└───────────────────────────────────────────────────────────────┘
                          600px wide
                     Centered on screen
                  Dimmed overlay behind
```

---

## **📱 5. Mobile Responsive Patterns**

### **Mobile Navigation (< 768px)**

```
Collapsed State:
┌────────────────────────────┐
│  ☰  Pizza Place      [•••] │
├────────────────────────────┤
│                             │
│  Content area               │
│                             │
└────────────────────────────┘

Expanded State (Hamburger Menu):
┌────────────────────────────┐
│  ✕                    [•••] │
│                             │
│  📋 CORE                    │
│  • Details                  │
│  • Address                  │
│  • Hours                    │
│                             │
│  🍽️ MENUS                   │
│  • All (12)                 │
│  • Active (9)               │
│  • Draft (3)                │
│                             │
│  👥 TEAM                    │
│  • Staff (8)                │
│  • Roles                    │
│                             │
│  ⚙️ SETUP                   │
│  • Catalog                  │
│  • Tables                   │
│  • Ordering                 │
│  • Advanced                 │
│                             │
└────────────────────────────┘
```

### **Mobile Form Layout**

```
Desktop (2-column):
┌──────────────────────────┐
│ Name:    [Input        ] │
│ Phone:   [Input        ] │
│ Email:   [Input        ] │
└──────────────────────────┘

Mobile (1-column, stacked):
┌────────────────┐
│ Name:          │
│ [Input       ] │
│                │
│ Phone:         │
│ [Input       ] │
│                │
│ Email:         │
│ [Input       ] │
└────────────────┘
```

---

## **🎭 6. Interaction States**

### **Button States**

```
Normal:
[Save Changes]

Hover:
[Save Changes]  ← Slightly darker, subtle shadow

Active (Pressed):
[Save Changes]  ← Pressed down effect

Loading:
[⟳ Saving...  ]  ← Spinner animation

Success:
[✓ Saved!     ]  ← Brief success state (2s)

Error:
[✕ Try Again  ]  ← Error state with retry
```

### **Form Field States**

```
Empty:
┌─────────────────────┐
│ [Enter name...    ] │  ← Placeholder text, gray border
└─────────────────────┘

Focused:
┌─────────────────────┐
│ Pizza P│            │  ← Blue border, cursor visible
└─────────────────────┘

Filled:
┌─────────────────────┐
│ Pizza Place         │  ← Gray border, black text
└─────────────────────┘

Error:
┌─────────────────────┐
│ Pi                  │  ← Red border
└─────────────────────┘
⚠️ Name must be at least 3 characters

Success (with auto-save):
┌─────────────────────┐
│ Pizza Place         │  ← Gray border
└─────────────────────┘
✓ Saved 2 seconds ago
```

---

## **🚀 7. Microinteractions**

### **Auto-Save Indicator**

```
Timeline:
0s:  User types in field
     [Input editing...        ]

1s:  Stop typing (debounce)
     [Input edited...         ] ⟳

2s:  Save starts
     [Input edited...         ] ⟳ Saving...

3s:  Save completes
     [Input edited...         ] ✓ Saved

5s:  Success message fades
     [Input edited...         ]

State transitions use 300ms ease-out
```

### **Drag-and-Drop Feedback**

```
1. Pick up item:
   - Item gets subtle shadow
   - Cursor changes to grabbing hand
   - Other items shift slightly to show reorder zones

2. Dragging:
   - Item follows cursor with spring animation
   - Drop zones highlight with blue line
   - Other items move to show new position

3. Drop:
   - Item animates to final position (200ms ease-out)
   - "Saved" indicator appears
   - Other items settle into place
```

### **Expandable Sections**

```
Expand:
▶ Section Name
     ↓ (click)
▼ Section Name
  Content slides down (300ms ease-out)
  Chevron rotates 90° (300ms)

Collapse:
▼ Section Name
     ↓ (click)
▶ Section Name
  Content slides up (300ms ease-in)
  Chevron rotates -90° (300ms)
```

---

## **💡 Implementation Notes**

### **Technologies to Use:**

**Already Available:**
✅ 2025 Design System (buttons, forms, cards)
✅ Auto-save Stimulus controller
✅ Bootstrap 5 grid system
✅ Existing color/spacing tokens

**Need to Add:**
- Sortable.js (drag-and-drop) or StimulusJS sortable controller
- Slide-over component (Stimulus controller)
- Expandable/collapsible controller
- Modal/dialog component

### **Code Structure:**

```
app/
├── javascript/
│   └── controllers/
│       ├── sidebar_controller.js       (sidebar navigation)
│       ├── expandable_controller.js    (expand/collapse sections)
│       ├── sortable_controller.js      (drag-to-reorder)
│       ├── slide_over_controller.js    (slide-over panels)
│       └── modal_controller.js         (edit modals)
│
├── views/
│   ├── restaurants/
│   │   ├── edit_2025.html.erb         (new redesigned version)
│   │   └── _sidebar.html.erb          (sidebar partial)
│   ├── menus/
│   │   ├── edit_2025.html.erb         (single-page layout)
│   │   └── _section_card.html.erb     (expandable section)
│   └── shared/
│       ├── _slide_over.html.erb       (reusable slide-over)
│       └── _edit_item_modal.html.erb  (item edit modal)
│
└── assets/stylesheets/components/
    ├── _sidebar_2025.scss
    ├── _slide_over_2025.scss
    ├── _expandable_2025.scss
    └── _drag_drop_2025.scss
```

---

## **✅ Ready to Implement!**

This mockup document provides:
- ✅ Detailed visual specifications
- ✅ Component structure
- ✅ Interaction patterns
- ✅ CSS/SCSS patterns
- ✅ Animation timings
- ✅ Mobile responsive layouts
- ✅ File organization structure

Next step: Start implementing Phase 1 (Sidebar consolidation)!
