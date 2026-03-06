# Restaurant Edit Page - Localization Gaps

## Summary
Audit of hardcoded English text in `/restaurants/:id/edit` pages that need to be extracted into locale files for Italian (IT) translation.

---

## 1. ARIA Labels (Accessibility)

### File: `app/views/restaurants/edit_2025.html.erb`
- **Line 26**: `aria-label="Toggle navigation"`
  - **Location**: Mobile sidebar toggle button
  - **Suggested key**: `restaurants.edit_2025.toggle_navigation`
  - **IT translation**: "Attiva/disattiva navigazione"

### File: `app/views/restaurants/_sidebar_2025.html.erb`
- **Line 22**: `aria-label="Close menu"`
  - **Location**: Mobile sidebar close button
  - **Suggested key**: `restaurants.sidebar_2025.close_menu`
  - **IT translation**: "Chiudi menu"

### Files: Multiple old views
- **Pattern**: `aria-label="Button group with nested dropdown"`
  - **Location**: All action button groups in legacy views
  - **Files affected**: `_showMenus.html.erb`, `_showEmployees.html.erb`, `_showTables.html.erb`, etc.
  - **Suggested key**: `restaurants.common.button_group_label`
  - **IT translation**: "Gruppo di pulsanti con menu a discesa"

---

## 2. Title Attributes (Tooltips)

### File: `app/views/restaurants/sections/_menus_2025.html.erb`
- **Line 89**: `title="<%= t('.drag_to_reorder', default: 'Drag to reorder') %>"`
  - ✅ Already localized

- **Line 148**: `title="<%= t('.no_preview', default: 'Menu not published yet') %>"`
  - ✅ Already localized

### File: `app/views/restaurants/sections/_tables_2025.html.erb`
- **Line 79, 163**: `title="<%= t('.view_qr_code', default: 'View QR Code for this table') %>"`
  - ✅ Already localized

- **Line 85, 169**: `title="<%= t('.no_smartmenu', default: 'No QR code generated yet') %>"`
  - ✅ Already localized

---

## 3. Placeholder Text

### File: `app/views/restaurants/sections/_settings_2025.html.erb`
All placeholders are already using `t()` helper:
- **Line 169**: `placeholder: t('.ssid_placeholder', default: 'Enter your WiFi network name')`
  - ✅ Already localized
- **Line 184**: `prompt: t('.select_encryption', default: 'Select encryption...')`
  - ✅ Already localized
- **Line 200**: `placeholder: t('.password_placeholder', default: 'Enter WiFi password')`
  - ✅ Already localized

---

## 4. JavaScript Comments (Developer-facing, Low Priority)

### File: `app/views/restaurants/sections/_details_2025.html.erb`
- **Line 334**: `// Add marker for restaurant location (use legacy Marker for compatibility)`
- **Line 342**: `// Add info window`
- **Line 304**: `console.log('[RestaurantMap] Loading Google Maps API...');`
- **Line 311**: `throw new Error('Google Maps API did not initialize in time');`
- **Line 314**: `throw new Error('Google Maps loader not available');`

**Note**: These are developer-facing messages and typically don't need localization.

### File: `app/views/restaurants/sections/_hours_2025.html.erb`
Multiple console.log statements:
- **Line 345**: `console.log('[HoursEditor] noUiSlider is available, proceeding with initialization');`
- **Line 350**: `console.error('[HoursEditor] Auto-save form NOT found!');`

**Note**: Developer debugging messages - low priority for localization.

---

## 5. Google Maps Configuration (Technical)

### Files: `_details_2025.html.erb`, `_address_2025.html.erb`
```javascript
mapTypeControl: true,
streetViewControl: true,
fullscreenControl: true
```

**Note**: These are Google Maps API configuration values, not user-facing text. Don't need localization.

---

## 6. HTML Comments (Already Localized Structure)

All major section comments are structural and don't need localization:
- `<!-- Page Header -->`
- `<!-- Sidebar Navigation -->`
- `<!-- Main Content Area -->`
- `<!-- Quick Actions Card -->`
- `<!-- QR Code Types -->`
- `<!-- Mobile Header -->`

---

## 7. Status - Already Fully Localized ✅

### Sections with Complete Localization:
All user-facing text in the following sections is already using `t()` helper:

1. **Details Section** (`_details_2025.html.erb`)
   - All form labels, help text, placeholders ✅
   - Map messages ✅
   - Overview stats ✅

2. **Menus Section** (`_menus_2025.html.erb`)
   - Quick actions ✅
   - Filter tabs ✅
   - Empty states ✅
   - Action buttons ✅

3. **Tables Section** (`_tables_2025.html.erb`)
   - All labels and messages ✅
   - Empty states ✅

4. **Allergens Section** (`_allergens_2025.html.erb`)
   - All content ✅

5. **Sizes Section** (`_sizes_2025.html.erb`)
   - All content ✅

6. **Staff Section** (`_staff_2025.html.erb`)
   - All content including role descriptions ✅
   - Empty states ✅

7. **Settings Section** (`_settings_2025.html.erb`)
   - All feature toggles ✅
   - WiFi configuration ✅
   - Help text ✅

8. **Catalog Section** (`_catalog_2025.html.erb`)
   - Taxes & Tips ✅

9. **QR Codes Section** (`_qrcodes_2025.html.erb`)
   - All descriptions ✅
   - Customization options ✅

10. **Hours Section** (`_hours_2025.html.erb`)
    - Day names ✅
    - Status options ✅

11. **Localization Section** (`_localization_2025.html.erb`)
    - All content ✅

12. **Jukebox Section** (`_jukebox_2025.html.erb`)
    - Spotify integration text ✅

13. **Ordering Section** (`_ordering_2025.html.erb`)
    - Coming soon messages ✅

---

## 8. Missing Localizations to Add

### HIGH PRIORITY - User-Facing Text

#### File: `app/views/restaurants/edit_2025.html.erb`
```yaml
# Add to restaurants.en.yml and restaurants.it.yml
restaurants:
  edit_2025:
    toggle_navigation: "Toggle navigation"  # IT: "Attiva/disattiva navigazione"
```

#### File: `app/views/restaurants/_sidebar_2025.html.erb`
```yaml
# Add to restaurants.en.yml and restaurants.it.yml
restaurants:
  sidebar_2025:
    close_menu: "Close menu"  # IT: "Chiudi menu"
```

#### Legacy Files (if still in use)
```yaml
# Add to restaurants.en.yml and restaurants.it.yml
restaurants:
  common:
    button_group_label: "Button group with nested dropdown"  # IT: "Gruppo di pulsanti con menu a discesa"
```

### LOW PRIORITY - Developer-Facing

JavaScript console messages and code comments are developer-facing and typically don't require localization unless the application has a debug mode for end users.

---

## 9. Implementation Required

### Step 1: Update English Locale File
Add to `config/locales/restaurants.en.yml`:
```yaml
en:
  restaurants:
    edit_2025:
      subtitle: Manage your restaurant configuration  # Already exists
      toggle_navigation: Toggle navigation  # NEW
    sidebar_2025:
      restaurant: RESTAURANT  # Already exists
      # ... existing keys ...
      close_menu: Close menu  # NEW
```

### Step 2: Update Italian Locale File
Add to `config/locales/restaurants.it.yml`:
```yaml
it:
  restaurants:
    edit_2025:
      subtitle: Gestisci la configurazione del tuo ristorante  # Already exists
      toggle_navigation: Attiva/disattiva navigazione  # NEW
    sidebar_2025:
      restaurant: RISTORANTE  # Already exists
      # ... existing keys ...
      close_menu: Chiudi menu  # NEW
```

### Step 3: Update Views
Replace hardcoded aria-labels with:
```erb
aria-label="<%= t('.toggle_navigation', default: 'Toggle navigation') %>"
aria-label="<%= t('.close_menu', default: 'Close menu') %>"
```

---

## 10. Conclusion

**EXCELLENT NEWS**: The restaurant edit pages (2025 redesign) are **99% localized**!

### What's Already Done ✅
- All user-facing text in all 13 sections
- All form labels, placeholders, help text
- All buttons and actions
- All empty states and descriptions
- All feature toggle descriptions
- All validation and error messages
- Complete Italian translations exist

### What Needs to Be Added (Minimal)
- **2 aria-labels** for accessibility
  - Toggle navigation button
  - Close menu button
- **Optional**: Legacy view aria-labels (if those views are still used)

### Developer Messages (Optional)
- JavaScript console.log messages
- Code comments
- These are low priority as they're not user-facing

**Estimated time to complete**: 5-10 minutes to add the 2 missing aria-label translations.

**Result**: The restaurant edit pages will be 100% localized for Italian users! 🎉
