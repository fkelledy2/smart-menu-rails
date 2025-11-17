# Smartmenu Locale Switching - Test Plan & Fixes

## Problem Summary

Locale switching on smartmenus was not working properly after the first switch due to two main issues:

1. **Event Handler Issue**: Direct jQuery event binding (`.setparticipantlocale().on('click')`) lost handlers when DOM was updated via ActionCable
2. **Cache Issue**: Menu content was cached without considering the user's preferred locale, so switching locale served stale cached content

## Fixes Applied

### 1. Event Delegation (JavaScript)
**Files Modified:**
- `app/javascript/ordrs.js`
- `app/javascript/channels/ordr_channel.js`

**Change:**
```javascript
// Before (direct binding - breaks after DOM update)
$('.setparticipantlocale').on('click', function (event) { ... });

// After (event delegation - survives DOM updates)
$(document).on('click', '.setparticipantlocale', function (event) { ... });
```

**Why This Fixes It:**
- Event delegation attaches handlers to `document` which never changes
- Clicks bubble up from dynamically-added elements to the document
- Handlers work for both existing and future elements
- No need to re-attach handlers after ActionCable updates

### 2. Cache Keys Include Locale (Backend)
**File Modified:**
- `app/controllers/menuparticipants_controller.rb`

**Changes:**

#### Added locale to cache keys:
```ruby
Rails.cache.fetch([
  :menu_content_customer,
  menu.try(:cache_key_with_version),
  allergyns.maximum(:updated_at),
  restaurant_currency.code,
  menuparticipant.try(:id),
  menuparticipant.try(:preferredlocale), # ✅ ADDED
  tablesetting.try(:id),
]) do
  # ... render partial
end
```

#### Render partials with correct locale:
```ruby
def broadcastPartials
  # ... setup code
  
  # Use menuparticipant's preferred locale for rendering
  participant_locale = menuparticipant.preferredlocale.presence&.to_sym || I18n.default_locale

  partials = I18n.with_locale(participant_locale) do
    {
      menuContentStaff: compress_string(...),
      menuContentCustomer: compress_string(...),
      # ... other partials
    }
  end
  
  ActionCable.server.broadcast("ordr_#{smartmenu.slug}_channel", partials)
end
```

**Why This Fixes It:**
- Cache keys now include locale, so each locale has its own cache entry
- Switching locale generates a cache miss and re-renders content
- Partials are rendered with `I18n.with_locale` using the participant's preferred locale
- Translations are applied correctly based on the locale

### 3. Added tablesetting to partials
**File Modified:**
- `app/controllers/menuparticipants_controller.rb`

**Change:**
Added missing `tablesetting` local variable to `menuContentStaff` and `menuContentCustomer` partials to prevent NameError.

## Test Coverage

### Integration Test
**File:** `test/integration/smartmenu_locale_switching_integration_test.rb`

**Test Cases:**
1. ✅ Updating menuparticipant locale should work
2. ✅ Cache keys should include menuparticipant preferredlocale
3. ✅ broadcastPartials should use menuparticipant locale
4. ✅ Multiple locale switches should each generate unique cache entries

### System Test
**File:** `test/system/smartmenu_locale_switching_test.rb`

**Test Scenarios:**
1. ✅ Should display default locale on first visit
2. ✅ Should switch to Italian locale and persist without page reload
3. ✅ Should switch between multiple locales without page reload
4. ✅ Should maintain locale preference across ActionCable updates
5. ✅ Should not cause duplicate event handlers on locale switch

## Expected Behavior

### Scenario 1: First Visit
1. User visits smartmenu
2. Default restaurant locale ('en') is displayed
3. Menu content rendered in English

### Scenario 2: First Locale Switch
1. User clicks Italian locale button
2. PATCH request sent to update menuparticipant preferredlocale to 'it'
3. Server updates menuparticipant, generates new cache entry for Italian
4. Server renders partials with I18n.locale = 'it'
5. ActionCable broadcasts updated partials to client
6. Client receives update, replaces DOM content with Italian menu
7. Event handlers remain active (due to event delegation)

### Scenario 3: Subsequent Locale Switch
1. User clicks Spanish locale button (no page reload needed)
2. PATCH request sent to update menuparticipant preferredlocale to 'es'
3. Server updates menuparticipant, generates new cache entry for Spanish
4. Server renders partials with I18n.locale = 'es'
5. ActionCable broadcasts updated partials to client
6. Client receives update, replaces DOM content with Spanish menu
7. Process repeats seamlessly for any additional switches

## Manual Testing Steps

1. **Setup:**
   - Create a menu with items in EN, IT, ES locales
   - Ensure translations exist in database or I18n files
   - Start Rails server: `rails s`

2. **Test Default Locale:**
   - Visit: `http://localhost:3000/smartmenus/{slug}`
   - Verify menu displays in default locale (EN)

3. **Test First Switch:**
   - Click Italian locale button
   - Wait 1-2 seconds for ActionCable update
   - Verify menu content changes to Italian
   - Check browser console for no errors

4. **Test Subsequent Switches:**
   - Click Spanish locale button (WITHOUT page reload)
   - Wait 1-2 seconds
   - Verify menu content changes to Spanish
   - Click Italian again
   - Verify it still works

5. **Test Cache Behavior:**
   - Open Rails console: `rails c`
   - Check cache keys include locale:
     ```ruby
     Rails.cache.redis.keys("*menu_content_customer*")
     ```
   - Should see separate entries for each locale

## Debugging Tips

### If locale switching still doesn't work:

1. **Check JavaScript Console:**
   - Look for PATCH request to `/restaurants/{id}/menus/{id}/menuparticipants/{id}`
   - Should return 200 OK
   - Check for ActionCable message: "Connected to OrdrChannel"

2. **Check Server Logs:**
   - Look for "Locale switching error" messages
   - Verify `broadcastPartials` is called after PATCH
   - Check I18n.locale value during partial rendering

3. **Check Cache:**
   - Clear Rails cache: `Rails.cache.clear`
   - Retry locale switching
   - Monitor cache keys being created

4. **Check Event Handlers:**
   - In browser console: `$._data(document, 'events')`
   - Should show 'click' handler for document
   - Try clicking locale button and check Network tab for PATCH request

## Performance Considerations

- **Cache Multiplication**: Each locale creates separate cache entries
  - 3 locales × 2 views (staff/customer) = 6 cache entries per menu
  - Monitor cache size and set appropriate TTL
  
- **Broadcast Size**: Locale switches trigger full partial re-broadcast
  - Consider implementing diff-based updates for large menus
  - Monitor ActionCable message sizes

## Future Improvements

1. **Optimistic Updates**: Update UI immediately, rollback on error
2. **Loading States**: Show spinner during locale switch
3. **Locale Persistence**: Store in localStorage as backup
4. **Performance**: Implement incremental DOM updates instead of full replacement
5. **Testing**: Add Cypress/Playwright tests for real browser testing
