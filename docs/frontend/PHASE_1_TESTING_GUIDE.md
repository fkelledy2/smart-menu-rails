# **Phase 1 Testing Guide - Complete Sidebar Navigation System**

**Date:** November 2, 2025  
**Status:** Ready for Testing  
**Access:** `http://localhost:3000/restaurants/1/edit?new_ui=true`

---

## **🎯 Testing Overview**

This guide covers comprehensive testing of the complete sidebar navigation system with all 12 sections.

---

## **✅ Pre-Testing Checklist**

Before starting tests, ensure:
- [ ] Rails server is running (`rails s` or `bin/dev`)
- [ ] You have at least one restaurant in the database
- [ ] You're logged in as the restaurant owner
- [ ] Browser console is open (F12) to check for errors

---

## **📋 Section-by-Section Testing**

### **CORE Section**

#### **1. Details Section** (`?section=details`)

**What to Test:**
- [ ] Restaurant name field auto-saves
- [ ] Description textarea works
- [ ] Currency selector (TomSelect) displays correctly
- [ ] Phone/Email/Website fields editable
- [ ] Quick action buttons functional

**Expected Behavior:**
- Auto-save notification appears after editing
- TomSelect dropdown has search functionality
- All fields preserve values on page refresh
- Quick action buttons navigate correctly

**Test Data:**
```
Restaurant Name: Test Restaurant
Description: A test description
Currency: USD
Phone: +1 234-567-8900
```

---

#### **2. Address Section** (`?section=address`)

**What to Test:**
- [ ] Street address field required
- [ ] City/State/Postal code fields work
- [ ] Coordinates display (if available)
- [ ] Delivery zones section (if enabled)

**Expected Behavior:**
- Form validation on required fields
- Auto-save after field changes
- Location verified message if coordinates exist

**Test Data:**
```
Address: 123 Main Street
City: New York
State: NY
Postal Code: 10001
```

---

#### **3. Hours Section** (`?section=hours`)

**What to Test:**
- [ ] Time pickers for each day
- [ ] "Closed" checkbox disables time fields
- [ ] "Copy to all days" button works
- [ ] Special hours table displays (if data exists)

**Expected Behavior:**
- Time pickers show on click
- Closed checkbox disables hours for that day
- Special hours load if any exist

**Test Times:**
```
Monday: 09:00 - 22:00
Tuesday: Closed
Wednesday-Sunday: 09:00 - 22:00
```

---

### **MENUS Section**

#### **4. All Menus** (`?section=menus`)

**What to Test:**
- [ ] Menu cards display in grid
- [ ] Published/Draft badges correct
- [ ] Section and item counts accurate
- [ ] Edit button navigates correctly
- [ ] View button opens in new tab
- [ ] Dropdown actions (Duplicate, Export, Delete)

**Expected Behavior:**
- Empty state shows if no menus
- Cards show correct statistics
- All buttons and dropdowns functional

---

#### **5. Active Menus** (`?section=menus_active`)

**What to Test:**
- [ ] Only published menus show
- [ ] Badge count matches filter
- [ ] Tab highlighting correct

**Expected Behavior:**
- Filter works correctly
- Active tab highlighted

---

#### **6. Draft Menus** (`?section=menus_draft`)

**What to Test:**
- [ ] Only unpublished menus show
- [ ] Badge count matches filter
- [ ] Tab highlighting correct

**Expected Behavior:**
- Filter works correctly
- Draft tab highlighted

---

### **TEAM Section**

#### **7. Staff Section** (`?section=staff`)

**What to Test:**
- [ ] Staff table displays all employees
- [ ] Avatar circles show correct initials
- [ ] Role badges color-coded correctly
- [ ] Active/Inactive status accurate
- [ ] Edit and Delete buttons work
- [ ] Roles & Permissions cards display

**Expected Behavior:**
- Empty state if no staff
- Table sorts correctly
- Permission lists show for each role

---

### **SETUP Section**

#### **8. Catalog Section** (`?section=catalog`)

**What to Test:**
- [ ] All 6 catalog items display with counts
- [ ] Manage buttons navigate correctly
- [ ] Quick Add cards functional
- [ ] Common Templates section loads

**Expected Behavior:**
- Counts accurate for each catalog type
- All links navigate to correct pages
- Template buttons interactive

**Catalog Items:**
- Taxes, Tips, Sizes, Allergens, Tags, Ingredients

---

#### **9. Tables Section** (`?section=tables`)

**What to Test:**
- [ ] QR code types display correctly
- [ ] Table settings table (if tables exist)
- [ ] View QR buttons open new tabs
- [ ] Add Table button works
- [ ] Edit/Delete table actions functional
- [ ] QR customization section loads

**Expected Behavior:**
- Empty state if no tables configured
- QR type cards display with icons
- Table management functional

---

#### **10. Ordering Section** (`?section=ordering`)

**What to Test:**
- [ ] Enable ordering toggle works
- [ ] Auto-accept orders toggle works
- [ ] Min order amount field accepts numbers
- [ ] Prep time field works
- [ ] Payment method checkboxes toggle
- [ ] Order type switches functional
- [ ] Notification toggles work

**Expected Behavior:**
- All form fields auto-save
- Switches toggle on/off correctly
- Payment methods selectable

---

#### **11. Advanced Section** (`?section=advanced`)

**What to Test:**
- [ ] Localization languages display
- [ ] Add Language button works
- [ ] Music tracks display (if any)
- [ ] Add Track button works
- [ ] Analytics fields editable
- [ ] Advanced feature toggles work
- [ ] Integration cards display

**Expected Behavior:**
- Languages show with default badge
- Tracks list functional
- Analytics IDs save correctly
- Feature switches toggle

---

## **🚀 Navigation Testing**

### **Turbo Frame Navigation**

Test instant section switching:

1. **Click each sidebar link**
   - [ ] No page reload (check network tab)
   - [ ] Content changes instantly
   - [ ] Sidebar stays in place
   - [ ] Active link highlights

2. **URL parameter updates**
   - [ ] `?section=` parameter changes
   - [ ] Back/Forward buttons work
   - [ ] Direct URL access works

3. **Performance**
   - [ ] Navigation feels instant
   - [ ] No flickering or flashing
   - [ ] Smooth transitions

**Expected:**
- Network tab shows only partial HTML requests
- No full page reloads
- Browser history tracks sections

---

### **Badge Counts**

Verify dynamic counts:

- [ ] **Menus badge** - Shows total menu count
- [ ] **Active badge** - Shows published menus
- [ ] **Draft badge** - Shows unpublished menus
- [ ] **Staff badge** - Shows employee count

**Test:** Add/remove items and verify counts update

---

## **📱 Mobile Testing**

Test responsive behavior on small screens (< 768px):

### **Hamburger Menu**

- [ ] Hamburger button (☰) visible
- [ ] Sidebar hidden by default
- [ ] Click hamburger opens sidebar
- [ ] Sidebar slides in from left
- [ ] Overlay appears behind sidebar
- [ ] Click overlay closes sidebar
- [ ] Sidebar closes on link click

### **Mobile Layout**

- [ ] All sections stack vertically
- [ ] Forms are touch-friendly
- [ ] Buttons large enough to tap
- [ ] Tables scroll horizontally
- [ ] Cards responsive

**Test Devices:**
- iPhone (375px width)
- iPad (768px width)
- Android phone (360px width)

---

## **🎨 Visual Testing**

### **Design System Consistency**

Check across all sections:

- [ ] **Colors** - 2025 design system colors used
- [ ] **Typography** - Consistent font sizes and weights
- [ ] **Spacing** - Uniform padding and margins
- [ ] **Borders** - Consistent border radius
- [ ] **Shadows** - Proper elevation hierarchy
- [ ] **Icons** - Bootstrap Icons throughout

### **Interactive States**

- [ ] **Hover** - Buttons show hover effects
- [ ] **Focus** - Form fields show focus rings
- [ ] **Active** - Links show active state
- [ ] **Disabled** - Disabled elements greyed out

---

## **⚡ Performance Testing**

### **Load Times**

Measure section switching speed:

1. Open DevTools Performance tab
2. Click sidebar links
3. Verify < 100ms for navigation

**Expected:**
- Initial load: < 2 seconds
- Section switch: < 100ms (Turbo Frame)
- Auto-save: < 500ms

### **Memory Usage**

Monitor in DevTools Memory tab:

- [ ] No memory leaks on navigation
- [ ] Sidebar controller cleans up properly
- [ ] Event listeners removed on destroy

---

## **🐛 Error Testing**

### **Edge Cases**

Test unusual scenarios:

1. **Empty States**
   - [ ] No menus - empty state displays
   - [ ] No staff - empty state displays
   - [ ] No tables - empty state displays
   - [ ] No tracks - empty state displays

2. **Network Errors**
   - [ ] Throttle network to "Slow 3G"
   - [ ] Test section switching
   - [ ] Verify loading states

3. **Form Validation**
   - [ ] Required fields show errors
   - [ ] Invalid data rejected
   - [ ] Validation messages clear

### **Console Errors**

Check browser console:

- [ ] No JavaScript errors
- [ ] No 404 errors for assets
- [ ] No Turbo Frame errors
- [ ] Sidebar controller logs appear

**Expected Console Output:**
```
[Sidebar] Controller connected
[Sidebar] Sidebar target found
```

---

## **🔐 Authorization Testing**

Test role-based access:

1. **Manager Role**
   - [ ] Can access all sections
   - [ ] Tables section visible
   - [ ] Ordering section visible
   - [ ] Advanced section visible

2. **Editor Role**
   - [ ] Can access CORE and MENUS
   - [ ] Cannot access SETUP sections
   - [ ] Proper authorization checks

3. **Viewer Role**
   - [ ] Read-only access
   - [ ] No edit buttons
   - [ ] Proper restrictions

---

## **✅ Acceptance Criteria**

Mark complete when all pass:

### **Functionality**
- [ ] All 12 sections load without errors
- [ ] Navigation works instantly (Turbo Frame)
- [ ] Auto-save works on all forms
- [ ] All buttons and links functional
- [ ] Badge counts accurate

### **Design**
- [ ] Consistent 2025 design system
- [ ] Mobile responsive (< 768px)
- [ ] Visual hierarchy clear
- [ ] Icons and badges correct

### **Performance**
- [ ] Section switching < 100ms
- [ ] No memory leaks
- [ ] No console errors
- [ ] Smooth animations

### **Accessibility**
- [ ] Keyboard navigation works
- [ ] Screen reader friendly
- [ ] Focus states visible
- [ ] ARIA labels correct

---

## **📊 Test Report Template**

Use this template to document test results:

```markdown
## Test Session Report

**Date:** YYYY-MM-DD
**Tester:** Your Name
**Browser:** Chrome/Firefox/Safari Version X
**Device:** Desktop/Mobile

### Sections Tested
- [ ] Details
- [ ] Address
- [ ] Hours
- [ ] All Menus
- [ ] Active Menus
- [ ] Draft Menus
- [ ] Staff
- [ ] Catalog
- [ ] Tables
- [ ] Ordering
- [ ] Advanced

### Issues Found
1. **Issue Title**
   - **Severity:** Critical/High/Medium/Low
   - **Section:** Section Name
   - **Description:** What happened
   - **Steps to Reproduce:** How to see the issue
   - **Expected:** What should happen
   - **Actual:** What actually happened

### Performance Metrics
- Initial Load Time: X seconds
- Section Switch Time: X ms
- Auto-save Time: X ms

### Overall Status
- [ ] ✅ All tests passed
- [ ] ⚠️ Minor issues found
- [ ] ❌ Major issues found

### Recommendations
- List any improvements or suggestions
```

---

## **🎯 Success Metrics**

Phase 1 is successful when:

1. **✅ Functional Requirements**
   - All 12 sections load and work correctly
   - Navigation is instant (Turbo Frame)
   - Auto-save functions properly
   - Mobile responsive works flawlessly

2. **✅ Performance Requirements**
   - Initial load < 2 seconds
   - Section switching < 100ms
   - No memory leaks
   - No console errors

3. **✅ User Experience Requirements**
   - 69% reduction in cognitive load achieved
   - Clear navigation hierarchy
   - Intuitive section grouping
   - Smooth, polished interactions

---

## **🚀 Ready to Deploy**

When all tests pass:

1. **Create deployment checklist**
2. **Document known issues**
3. **Prepare rollout plan**
4. **Set up user feedback collection**
5. **Monitor analytics for adoption**

---

**Happy Testing! 🎉**

For issues or questions, refer to:
- `docs/frontend/SIDEBAR_SECTIONS_COMPLETE.md`
- `docs/frontend/PHASE_1_IMPLEMENTATION.md`
- `docs/frontend/TESTING_NEW_UI.md`
