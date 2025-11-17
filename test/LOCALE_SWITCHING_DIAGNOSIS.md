# Locale Switching Diagnosis & Fixes

## Issue Summary
Locale switching appears to work on the backend (preferredlocale is updated) but the UI doesn't update to show content in the selected language.

## Root Causes Identified

### 1. ✅ Case Sensitivity in Locale Lookups
**Problem:** 
- Frontend sends lowercase 'it'
- Model `before_save` callbacks normalize to lowercase 'it'
- Database contains uppercase 'IT' in localization tables
- Queries like `where(locale: 'it')` fail to match 'IT'

**Fix Applied:**
- Made all locale lookups case-insensitive using SQL LOWER()
- Updated models: `Menusection`, `Menuitem`, `Menu`, `Restaurant`

```ruby
# Before
Menusectionlocale.where(menusection_id: id, locale: locale).first

# After
Menusectionlocale.where(menusection_id: id)
                 .where('LOWER(locale) = ?', locale.to_s.downcase)
                 .first
```

### 2. ✅ Event Handler Loss on DOM Update
**Problem:**
- Direct jQuery binding lost when ActionCable updated DOM
- Locale buttons stopped working after first switch

**Fix Applied:**
- Changed to event delegation in `ordrs.js` and `ordr_channel.js`

```javascript
// Before (direct binding)
$('.setparticipantlocale').on('click', function() { ... });

// After (event delegation)
$(document).on('click', '.setparticipantlocale', function() { ... });
```

### 3. ✅ Cache Not Invalidated on Locale Change
**Problem:**
- Cache keys didn't include locale
- Switching locale served stale cached content

**Fix Applied:**
- Added `menuparticipant.preferredlocale` to cache keys
- Wrapped rendering in `I18n.with_locale`

### 4. ✅ Nil Reference Errors
**Problem:**
- `restaurant.getLocale()` returned nil for unconfigured locales
- Views crashed trying to access `.flag` on nil

**Fix Applied:**
- Added safe navigation operators
- Made getLocale case-insensitive
- Added defensive nil checks in views

## Testing the Fix

### Manual Testing Steps

1. **Open smartmenu:**
   ```
   http://localhost:3000/smartmenus/ba68e52e-2d6e-444c-ad3f-a9efbacd2daa
   ```

2. **Check initial state:**
   - Default locale should display
   - Check browser console for errors
   - Verify menu items display

3. **Switch to Italian:**
   - Click Italian flag button
   - Watch Network tab for PATCH request
   - Should see 200 OK response
   - Wait 1-2 seconds for ActionCable update

4. **Verify Italian content:**
   - Menu sections should show Italian names
   - Menu items should show Italian names
   - Check browser console for any errors

5. **Switch back to English:**
   - Click English/GB flag
   - Wait for update
   - Verify English content restored

6. **Test multiple switches:**
   - Switch IT → EN → IT → EN rapidly
   - Each switch should work
   - No errors in console

### Debugging Checklist

If locale switching still doesn't work:

#### Check Backend:
```bash
# In rails console
mp = Menuparticipant.last
mp.preferredlocale  # Should be lowercase 'it' or 'en'

# Check localization records
Menusectionlocale.where('LOWER(locale) = ?', 'it').count
Menuitemlocale.where('LOWER(locale) = ?', 'it').count

# Check restaurant locale config
r = Restaurant.first
r.getLocale('it')  # Should return Restaurantlocale record
```

#### Check Frontend:
```javascript
// In browser console

// Check event handler is attached
$._data(document, 'events').click  // Should show click handler

// Test PATCH manually
fetch('/restaurants/1/menus/9/menuparticipants/83', {
  method: 'PATCH',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
  },
  body: JSON.stringify({
    menuparticipant: { preferredlocale: 'it' }
  })
})
```

#### Check ActionCable:
```javascript
// In browser console
// Should see these messages when switching locale:
// - "PATCH /restaurants/1/menus/9/menuparticipants/83"
// - "Connected to OrdrChannel"
// - "Updated menuContentCustomer with X characters"
```

## Expected Behavior Now

### Scenario: Switch to Italian

1. **User Action:** Click Italian flag
2. **JavaScript:** 
   - Captures click via event delegation
   - Sends PATCH with `{ preferredlocale: 'it' }`
3. **Server:**
   - Updates `menuparticipant.preferredlocale = 'it'`
   - Calls `broadcastPartials`
   - Re-queries menuparticipant from DB (gets 'it')
   - Renders partials with `I18n.with_locale(:it)`
   - Queries localization tables with case-insensitive 'it'
   - Finds 'IT' records in database
   - Generates Italian content
4. **ActionCable:**
   - Broadcasts compressed HTML to client
5. **Client:**
   - Decompresses and replaces DOM
   - Italian content now visible
   - Flag button shows Italian flag
   - Event handlers still work (delegation)

### Scenario: Switch Back to English

1. **User Action:** Click English flag (no page reload)
2. Same flow as above with locale='en'
3. English content displayed
4. Can switch again immediately

## Files Modified

### Models (Case-insensitive lookups):
- `app/models/menusection.rb`
- `app/models/menuitem.rb`
- `app/models/menu.rb`
- `app/models/restaurant.rb`

### Models (Locale normalization):
- `app/models/menuparticipant.rb` - before_save callback
- `app/models/ordrparticipant.rb` - before_save callback
- `app/models/restaurantlocale.rb` - case-insensitive flag/language methods

### Controllers:
- `app/controllers/menuparticipants_controller.rb` - Added locale to cache keys, I18n.with_locale

### Views:
- `app/views/smartmenus/_showTableLocaleSelectorCustomer.erb` - Safe nil checks, lowercase locale

### JavaScript:
- `app/javascript/ordrs.js` - Event delegation
- `app/javascript/channels/ordr_channel.js` - Event delegation

## Performance Considerations

**N+1 Queries:**
Each `localised_name()` call makes 2 database queries. Consider:
- Eager loading locale records
- Caching locale lookups
- Batch queries for multiple items

**Cache Multiplication:**
- Each locale creates separate cache entries
- Monitor cache size
- Set appropriate TTL

**ActionCable Payload:**
- Full HTML broadcast on each switch
- Consider differential updates for large menus

## Known Limitations

1. **Localization requires database records:**
   - Menu items need Menuitemlocale records
   - Sections need Menusectionlocale records
   - If records missing, falls back to default name

2. **No optimistic UI updates:**
   - User must wait for ActionCable round-trip
   - Could add loading state

3. **Case sensitivity in database:**
   - Legacy data may have mixed case
   - SQL LOWER() queries can't use indexes efficiently
   - Consider migration to normalize all locale columns

## Next Steps

If problems persist:
1. Check if Menuitemlocale/Menusectionlocale records exist for 'IT'
2. Verify ActionCable connection is active
3. Check CSRF token is valid
4. Monitor Rails logs for errors
5. Check browser console for JavaScript errors
