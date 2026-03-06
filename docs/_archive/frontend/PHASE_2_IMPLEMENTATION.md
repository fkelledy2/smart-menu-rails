# **Phase 2 Implementation Plan - Menu Edit Page Redesign**

**Date:** November 2, 2025  
**Status:** Planning → Implementation  
**Goal:** Apply sidebar navigation pattern to Menu Edit page

---

## **🎯 Objective**

Redesign the Menu Edit page using the same sidebar navigation pattern from Phase 1, reducing cognitive load and improving navigation efficiency for menu management.

---

## **📊 Current State Analysis**

### **Current Menu Edit Page (Old UI)**

**Structure:**
- Horizontal tabs: Menu, Sections, Availabilities
- Full page reloads on tab switching
- No clear hierarchy
- Limited mobile responsiveness

**Sections:**
1. **Menu Tab** - Name, description, PDF upload, image settings, display options
2. **Sections Tab** - List of menu sections with items
3. **Availabilities Tab** - Schedule management for when menu is available

**Problems:**
- ❌ Horizontal tabs awkward on mobile
- ❌ Full page reload on navigation
- ❌ No room for expansion (already at capacity)
- ❌ Inconsistent with new restaurant edit UI

---

## **🎨 Proposed New Structure**

### **Sidebar Navigation Groups**

```
┌─────────────────────────────────────────┐
│ Header: Menu Name + Actions            │
├──────────┬──────────────────────────────┤
│ Sidebar  │ Content Area                 │
│          │                              │
│ CORE     │ Menu Details Form            │
│   Details│ - Name                       │
│   Design │ - Description                │
│          │ - Images                     │
│ CONTENT  │ - PDF Upload                 │
│   Sections                              │
│   Items  │                              │
│          │                              │
│ SETUP    │                              │
│   Schedule                              │
│   QR Code│                              │
│          │                              │
└──────────┴──────────────────────────────┘
```

### **Section Breakdown**

#### **CORE Section** (2 sections)
- **Details** - Name, description, status
- **Design** - Images, PDF menu, display settings

#### **CONTENT Section** (2 sections)
- **Sections** - Menu sections list and management
- **Items** - All menu items view (new!)

#### **SETUP Section** (2 sections)
- **Schedule** - Availability/schedule management
- **QR Code** - QR code generation and customization

**Total: 6 sections** (down from potential sprawl)

---

## **🗂️ Implementation Structure**

### **Files to Create**

```
app/views/menus/
├── edit_2025.html.erb                    # Main layout wrapper
├── _sidebar_2025.html.erb                # Sidebar component
├── _section_frame_2025.html.erb          # Turbo frame wrapper
└── sections/
    ├── _details_2025.html.erb            # Menu details
    ├── _design_2025.html.erb             # Images & PDF
    ├── _sections_2025.html.erb           # Menu sections
    ├── _items_2025.html.erb              # All items view
    ├── _schedule_2025.html.erb           # Availabilities
    └── _qrcode_2025.html.erb             # QR code
```

### **Controller Updates**

```ruby
# app/controllers/menus_controller.rb

def edit
  authorize @menu
  
  # Set current section for 2025 UI
  @current_section = params[:section] || 'details'
  
  # Handle new UI parameter
  if params[:new_ui] == 'true'
    # Handle Turbo Frame requests for section content
    if turbo_frame_request_id == 'menu_content'
      render partial: 'menus/section_frame_2025',
             locals: { 
               menu: @menu, 
               partial_name: section_partial_name(@current_section)
             }
    else
      render :edit_2025
    end
  end
end

private

def section_partial_name(section)
  case section
  when 'details' then 'details_2025'
  when 'design' then 'design_2025'
  when 'sections' then 'sections_2025'
  when 'items' then 'items_2025'
  when 'schedule' then 'schedule_2025'
  when 'qrcode' then 'qrcode_2025'
  else 'details_2025'
  end
end
```

---

## **📋 Section Details**

### **1. Details Section**

**Purpose:** Core menu information

**Content:**
- Menu name (text field)
- Description (textarea)
- Status selector (active/inactive)
- Sequence/order number
- Quick stats:
  - Total sections count
  - Total items count
  - Last updated timestamp

**Actions:**
- Preview menu button
- Delete menu button

---

### **2. Design Section**

**Purpose:** Visual appearance and PDF upload

**Content:**
- Menu hero image upload
- Image preview
- Image optimization options
- AI image generation button
- PDF menu upload
- PDF preview/download
- Display settings:
  - Show prices
  - Show images
  - Show descriptions
  - Grid vs list layout

---

### **3. Sections Section**

**Purpose:** Manage menu sections (categories)

**Content:**
- Sections list (draggable for reordering)
- Add new section button
- Each section card shows:
  - Section name
  - Item count
  - Visibility toggle
  - Edit button
  - Delete button
- Empty state for no sections

**Features:**
- Drag-and-drop reordering
- Quick add section inline
- Bulk operations

---

### **4. Items Section** (New!)

**Purpose:** View and manage all menu items across all sections

**Content:**
- Search/filter bar
- Sortable table/grid of all items
- Filters:
  - By section
  - By price range
  - With/without images
  - With/without allergens
- Bulk operations:
  - Bulk edit prices
  - Bulk assign tags
  - Bulk hide/show
- Quick stats dashboard

---

### **5. Schedule Section**

**Purpose:** Availability management

**Content:**
- Availability rules list
- Add availability button
- Day/time selectors
- Recurring schedule options
- Special dates/holidays
- Exception rules

---

### **6. QR Code Section**

**Purpose:** QR code generation and management

**Content:**
- QR code preview
- Download QR code (PNG, SVG, PDF)
- QR code customization:
  - Size selector
  - Color customization
  - Logo overlay option
- Short URL display
- QR code analytics (scans count)

---

## **🎨 Design System**

### **Reuse from Phase 1:**
- Same color palette
- Same typography scale
- Same spacing system
- Same button styles
- Same form components
- Same card styles

### **Turbo Frame ID:**
```html
<turbo-frame id="menu_content">
  <!-- Section content here -->
</turbo-frame>
```

### **URL Structure:**
```
/restaurants/:restaurant_id/menus/:id/edit?new_ui=true&section=details
/restaurants/:restaurant_id/menus/:id/edit?new_ui=true&section=sections
/restaurants/:restaurant_id/menus/:id/edit?new_ui=true&section=items
```

---

## **✨ New Features**

### **1. All Items View**
A new section that shows all menu items from all sections in one place, with:
- Advanced filtering
- Bulk operations
- Quick stats
- Export capabilities

### **2. Enhanced QR Code Section**
Dedicated section for QR code management:
- Customization options
- Multiple export formats
- Analytics integration

### **3. Quick Actions Toolbar**
Persistent actions available from any section:
- Preview menu
- Duplicate menu
- Export data
- Delete menu

---

## **📱 Mobile Optimization**

- Hamburger menu for sidebar (same as Phase 1)
- Touch-friendly section cards
- Mobile-optimized forms
- Responsive tables with horizontal scroll
- Bottom action bar for primary actions

---

## **🚀 Implementation Phases**

### **Phase 2.1: Core Structure** (Current)
- [ ] Create edit_2025.html.erb layout
- [ ] Create sidebar_2025.html.erb component
- [ ] Create section_frame_2025.html.erb wrapper
- [ ] Update controller with section routing
- [ ] Test basic navigation

### **Phase 2.2: Core Sections**
- [ ] Create details_2025 partial
- [ ] Create design_2025 partial
- [ ] Test core sections

### **Phase 2.3: Content Sections**
- [ ] Create sections_2025 partial
- [ ] Create items_2025 partial (new!)
- [ ] Test content sections

### **Phase 2.4: Setup Sections**
- [ ] Create schedule_2025 partial
- [ ] Create qrcode_2025 partial
- [ ] Test setup sections

### **Phase 2.5: Testing & Polish**
- [ ] Comprehensive testing
- [ ] Mobile testing
- [ ] Performance optimization
- [ ] Documentation

---

## **🎯 Success Metrics**

### **User Experience**
- 60% reduction in cognitive load (from 3 tabs + complex forms)
- 95% faster navigation (Turbo Frames)
- 100% mobile-friendly

### **Technical**
- < 2s initial load time
- < 100ms section switch
- No console errors
- Works without JavaScript (graceful degradation)

### **Business**
- Faster menu creation
- Reduced support tickets
- Higher user satisfaction

---

## **📚 Related Documentation**

- `PHASE_1_FINAL_SUMMARY.md` - Restaurant edit redesign reference
- `SIDEBAR_SECTIONS_COMPLETE.md` - Sidebar pattern documentation
- `PHASE_1_TESTING_GUIDE.md` - Testing methodology

---

## **🔄 Rollout Strategy**

1. **Week 1**: Implement Phase 2.1-2.2 (core structure + core sections)
2. **Week 2**: Implement Phase 2.3-2.4 (content + setup sections)
3. **Week 3**: Testing and refinement
4. **Week 4**: Beta release with ?new_ui=true
5. **Week 5**: Gradual rollout to 100% of users
6. **Week 6**: Deprecate old UI

---

## **Next Steps**

1. ✅ Create implementation plan (this document)
2. → Create main layout (edit_2025.html.erb)
3. → Create sidebar component
4. → Implement first section (Details)
5. → Test and iterate

---

**Phase 2 will bring the same modern, efficient navigation to menu management! 🚀**
