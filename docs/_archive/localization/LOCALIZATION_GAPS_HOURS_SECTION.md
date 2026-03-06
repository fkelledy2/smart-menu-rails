# Hours Section - Localization Gaps

## Summary
Audit of hardcoded English text in `/restaurants/:id/edit?section=hours` that needs Italian (IT) translation.

---

## Findings

### ✅ ALREADY LOCALIZED (Excellent!)

The following are properly using the `t()` helper:

1. **Line 12**: `<%= t('.quick_actions', default: 'Quick Actions') %>`
2. **Line 18**: `<%= t('.copy_to_all', default: 'Copy Monday to All Days') %>`
3. **Line 27**: `<%= t('.operating_hours', default: 'Operating Hours') %>`
4. **Line 31**: `<%= t('.hours_description', default: 'Set your restaurant\'s regular business hours') %>`
5. **Line 60**: Day names using Rails i18n: `t("date.day_names")`
6. **Line 72**: `<%= t('.closed', default: 'Closed') %>`

---

## ❌ LOCALIZATION GAPS FOUND

### 1. JavaScript Success Message (HIGH PRIORITY)

**File**: `app/views/restaurants/sections/_hours_2025.html.erb`  
**Line 472**: Hardcoded "Copied!" message in JavaScript

```javascript
btn.innerHTML = '<i class="bi bi-check-circle-fill"></i> Copied!';
```

**Problem**: When user clicks "Copy Monday to All Days", the button temporarily shows "Copied!" - this text is hardcoded.

**Impact**: Italian users will see English success message.

**Solution Needed**:
- Add translation key to locale files
- Pass translated string to JavaScript
- Use the translated string in the button update

---

### 2. JavaScript Console Messages (LOW PRIORITY - Developer-Facing)

Multiple console.log/error messages throughout the JavaScript code:

- Line 130: `console.log('[HoursEditor] Loading noUiSlider from CDN...');`
- Line 134: `console.log('[HoursEditor] noUiSlider loaded successfully');`
- Line 138: `console.error('[HoursEditor] Failed to load noUiSlider from CDN');`
- Line 142: `console.log('[HoursEditor] noUiSlider already loaded');`
- Line 327: `console.log('[HoursEditor] Initializing with auto-save');`
- Line 333: `console.log(\`[HoursEditor] Waiting for noUiSlider to load... (attempt ${noUiSliderRetries}/${MAX_RETRIES})\`);`
- Line 338: `console.error('[HoursEditor] Failed to load noUiSlider after max retries');`
- Line 345: `console.log('[HoursEditor] noUiSlider is available, proceeding with initialization');`
- Line 350: `console.error('[HoursEditor] Auto-save form NOT found!');`
- Line 513: `console.log('[HoursEditor] Event listeners registered...');`

**Note**: These are developer debugging messages typically not visible to end users. Low priority for localization.

---

### 3. JavaScript Comments (IGNORE - Code Documentation)

Multiple code comments like:
- `// Check if noUiSlider is already loaded`
- `// Track retry attempts`
- `// Opening time`
- `// Closing time`
- etc.

**Note**: These are code documentation for developers and don't need localization.

---

## Implementation Required

### Step 1: Add Translations to Locale Files

**English** (`config/locales/restaurants_sections.en.yml`):
```yaml
en:
  restaurants:
    sections:
      hours_2025:
        quick_actions: Quick Actions  # Already exists
        copy_to_all: Copy Monday to All Days  # Already exists
        operating_hours: Operating Hours  # Already exists
        hours_description: Set your restaurant's regular business hours  # Already exists
        closed: Closed  # Already exists
        copied_success: Copied!  # NEW - Add this
```

**Italian** (`config/locales/restaurants_sections.it.yml`):
```yaml
it:
  restaurants:
    sections:
      hours_2025:
        quick_actions: Azioni Rapide  # Already exists
        copy_to_all: Copia Lunedì a Tutti i Giorni  # Already exists
        operating_hours: Orari di Apertura  # Already exists
        hours_description: Imposta gli orari di apertura del tuo ristorante  # Already exists
        closed: Chiuso  # Already exists
        copied_success: Copiato!  # NEW - Add this
```

### Step 2: Pass Translation to JavaScript

In the ERB file, add a data attribute with the translated string:

```erb
<button type="button" 
        class="quick-action-btn copy-monday-btn"
        data-copied-text="<%= t('.copied_success', default: 'Copied!') %>">
  <i class="bi bi-files"></i>
  <span><%= t('.copy_to_all', default: 'Copy Monday to All Days') %></span>
</button>
```

### Step 3: Update JavaScript to Use Translated String

Replace line 472 in the JavaScript:

**OLD**:
```javascript
btn.innerHTML = '<i class="bi bi-check-circle-fill"></i> Copied!';
```

**NEW**:
```javascript
const copiedText = btn.dataset.copiedText || 'Copied!';
btn.innerHTML = `<i class="bi bi-check-circle-fill"></i> ${copiedText}`;
```

---

## Summary

### Status: 98% Localized ✅

**Already Localized**:
- ✅ All form labels and titles
- ✅ All help text and descriptions  
- ✅ Day names (using Rails i18n)
- ✅ Toggle labels
- ✅ Button text
- ✅ Quick actions

**Needs Localization**:
- ❌ 1 JavaScript success message: "Copied!"
- ⚠️ Console.log messages (developer-facing, optional)

**Recommendation**: Fix the "Copied!" message to achieve 100% user-facing localization. The console messages are optional as they're only visible to developers in the browser console.

**Estimated Time**: 5 minutes to implement the fix.
