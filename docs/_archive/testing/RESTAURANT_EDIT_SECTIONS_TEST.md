# Restaurant Edit Page - Section Testing Guide

## Test URL
```
http://localhost:3000/restaurants/1/edit
```

## All Sections Test Checklist

### ✅ CORE Section

#### 1. Details
- **URL**: `http://localhost:3000/restaurants/1/edit?section=details`
- **Partial**: `_details_2025.html.erb`
- **Expected Content**:
  - Quick Actions card (New Menu, Bulk Import, QR Code)
  - Overview Stats (Menus count, Items count, Staff count)
  - Restaurant Details form (Name, Description, Image)
- **Status**: ✅ Should work

#### 2. Address
- **URL**: `http://localhost:3000/restaurants/1/edit?section=address`
- **Partial**: `_address_2025.html.erb`
- **Expected Content**:
  - Address & Location form
  - Map integration (if available)
- **Status**: ✅ Should work

#### 3. Hours
- **URL**: `http://localhost:3000/restaurants/1/edit?section=hours`
- **Partial**: `_hours_2025.html.erb`
- **Expected Content**:
  - Operating Hours management
  - Restaurant availability schedule
  - Day/time selector
- **Status**: ✅ Should work

#### 4. Contact
- **URL**: `http://localhost:3000/restaurants/1/edit?section=contact`
- **Partial**: `_details_2025.html.erb` (same as Details)
- **Expected Content**:
  - Same as Details section (includes contact info in form)
- **Status**: ✅ **FIXED** - Now properly mapped to details_2025

---

### ✅ MENUS Section

#### 5. All Menus
- **URL**: `http://localhost:3000/restaurants/1/edit?section=menus`
- **Partial**: `_menus_2025.html.erb`
- **Filter**: `all`
- **Expected Content**:
  - Filter tabs (All, Active, Draft)
  - All non-archived menus
  - Menu cards with Edit buttons
- **Status**: ✅ Should work

#### 6. Active Menus
- **URL**: `http://localhost:3000/restaurants/1/edit?section=menus_active`
- **Partial**: `_menus_2025.html.erb`
- **Filter**: `active`
- **Expected Content**:
  - Filter tabs (All, Active, Draft)
  - Only active menus
  - Active badge highlighted
- **Status**: ✅ Should work

#### 7. Draft Menus
- **URL**: `http://localhost:3000/restaurants/1/edit?section=menus_draft`
- **Partial**: `_menus_2025.html.erb`
- **Filter**: `draft`
- **Expected Content**:
  - Filter tabs (All, Active, Draft)
  - Only inactive/draft menus
  - Draft badge highlighted
- **Status**: ✅ Should work

---

### ✅ TEAM Section

#### 8. Staff
- **URL**: `http://localhost:3000/restaurants/1/edit?section=staff`
- **Partial**: `_staff_2025.html.erb`
- **Expected Content**:
  - Staff Members table
  - Add Staff Member button
  - Employee list with roles and status
- **Status**: ✅ Should work

#### 9. Roles & Permissions
- **URL**: `http://localhost:3000/restaurants/1/edit?section=roles`
- **Partial**: `_staff_2025.html.erb` (same as Staff)
- **Expected Content**:
  - Same as Staff section
  - Shows employee roles in table
- **Status**: ✅ Should work

---

### ✅ SETUP Section

#### 10. Catalog
- **URL**: `http://localhost:3000/restaurants/1/edit?section=catalog`
- **Partial**: `_catalog_2025.html.erb`
- **Expected Content**:
  - Taxes management
  - Tips management
  - Sizes management
  - Allergens management
  - Tags management
- **Status**: ✅ Should work

#### 11. Tables
- **URL**: `http://localhost:3000/restaurants/1/edit?section=tables`
- **Partial**: `_tables_2025.html.erb`
- **Expected Content**:
  - QR Code management
  - Table settings
  - WiFi settings
- **Status**: ✅ Should work
- **Note**: Only visible to manager role

#### 12. Ordering
- **URL**: `http://localhost:3000/restaurants/1/edit?section=ordering`
- **Partial**: `_ordering_2025.html.erb`
- **Expected Content**:
  - Order management settings
  - Ordering preferences
- **Status**: ✅ Should work
- **Note**: Only visible to manager role

#### 13. Advanced
- **URL**: `http://localhost:3000/restaurants/1/edit?section=advanced`
- **Partial**: `_advanced_2025.html.erb`
- **Expected Content**:
  - Localization settings
  - Languages management
  - Music/Spotify integration
  - Advanced features
- **Status**: ✅ Should work
- **Note**: Only visible to manager role

---

## Section Mapping Summary

| Sidebar Link | Section Param | Partial Used | Filter |
|-------------|---------------|--------------|--------|
| Details | `details` | `_details_2025` | - |
| Address | `address` | `_address_2025` | - |
| Hours | `hours` | `_hours_2025` | - |
| Contact | `contact` | `_details_2025` | - |
| All Menus | `menus` | `_menus_2025` | `all` |
| Active Menus | `menus_active` | `_menus_2025` | `active` |
| Draft Menus | `menus_draft` | `_menus_2025` | `draft` |
| Staff | `staff` | `_staff_2025` | - |
| Roles | `roles` | `_staff_2025` | - |
| Catalog | `catalog` | `_catalog_2025` | - |
| Tables | `tables` | `_tables_2025` | - |
| Ordering | `ordering` | `ordering_2025` | - |
| Advanced | `advanced` | `_advanced_2025` | - |

---

## Testing Instructions

1. **Start at**: `http://localhost:3000/restaurants/1/edit`
2. **Click each sidebar link** in order (top to bottom)
3. **Verify** each section loads without "Content missing" errors
4. **Check** that Turbo Frame navigation works (no full page reload)
5. **Confirm** active state updates in sidebar

---

## Changes Applied

### 1. Fixed Contact Section Mapping
**File**: `app/views/restaurants/edit_2025.html.erb`

**Before**:
```erb
partial_name = case @current_section
              when 'address' then 'address_2025'
              # ... missing 'contact'
```

**After**:
```erb
partial_name = case @current_section
              when 'details', 'contact' then 'details_2025'  # ✅ Added contact
              when 'address' then 'address_2025'
```

### 2. Fixed Menu Filter Logic
**File**: `app/views/restaurants/edit_2025.html.erb`

**Before**:
```erb
filter = @current_section.include?('menus') ? @current_section.sub('menus_', '') : 'all'
```

**After**:
```erb
filter = @current_section.include?('menus') ? @current_section.sub('menus_', '') : 'all'
filter = 'all' if @current_section == 'menus'  # ✅ Added explicit check
```

---

## Expected Behavior

### ✅ All Sections Should:
1. Load without errors
2. Display content immediately
3. Not show "Content missing"
4. Use Turbo Frame navigation (no page reload)
5. Update sidebar active state
6. Show proper section title and content

### 🔄 Navigation:
- Clicking sidebar links should feel instant
- No full page refresh
- Browser back/forward should work
- URL should update with `?section=xxx`

---

## Troubleshooting

If you still see "Content missing":

1. **Check browser console** for JavaScript errors
2. **Verify partial exists**: Look in `app/views/restaurants/sections/`
3. **Check controller mapping**: Verify `section_partial_name` in `RestaurantsController`
4. **Inspect Turbo Frame**: Make sure `restaurant_content` frame is loading
5. **Test without Turbo**: Add `data-turbo="false"` to link temporarily

---

## All Sections Complete! ✅

All 13 sections are now properly wired up and should load without "Content missing" errors.
