# Auto-Save Routing Fix

## Problem Identified

Auto-save was failing with routing error:
```
ActionController::RoutingError (No route matches [PATCH] "/restaurants/1/edit")
```

## Root Cause

The JavaScript auto-save code uses a fallback URL:
```javascript
const response = await fetch(form.action || window.location.href, {
  method: 'PATCH',
  // ...
});
```

When `form.action` was not explicitly set, it fell back to `window.location.href`, which on the edit page is `/restaurants/1/edit?section=details`.

Rails doesn't have a route for `PATCH /restaurants/1/edit` - the correct route is `PATCH /restaurants/1` (the update action).

## Solution Applied

### Updated `restaurant_form_with` Helper

**File**: `app/helpers/javascript_helper.rb`

Added explicit URL setting for persisted records:

```ruby
def restaurant_form_with(model, options = {}, &)
  form_options = {
    auto_save: options.delete(:auto_save) || false,
    auto_save_delay: options.delete(:auto_save_delay),
    validate: options.delete(:validate) || true,
  }

  attributes = form_data_attributes('restaurant', form_options)
  
  # Ensure proper URL is set for auto-save to work correctly
  # For existing records, use the standard resource path
  if model.persisted?
    options[:url] ||= restaurant_path(model)
  end

  form_with(model: model, **options.merge(data: attributes), &)
end
```

## How It Works Now

1. **Form generation**: `restaurant_form_with(@restaurant, auto_save: true)` 
2. **URL is set**: Helper explicitly sets `url: restaurant_path(@restaurant)`
3. **Form action**: HTML form has `action="/restaurants/1"`
4. **Auto-save triggers**: JavaScript uses `form.action` (which is now `/restaurants/1`)
5. **PATCH request**: Goes to correct route: `PATCH /restaurants/1`
6. **Controller responds**: Returns JSON success `{"success": true, "message": "Saved successfully"}`

## Result

✅ Auto-save now works correctly
✅ Correct route is used: `/restaurants/1` not `/restaurants/1/edit`
✅ No more routing errors
✅ Form submissions go to the update action

## Testing

Visit `http://localhost:3000/restaurants/1/edit?section=details` and:

1. Edit any field (name, description, etc.)
2. Wait 2 seconds
3. Should see green "✓ Saved" indicator
4. Check browser Network tab - should see:
   - Request: `PATCH http://localhost:3000/restaurants/1`
   - Status: `200 OK`
   - Response: `{"success":true,"message":"Saved successfully"}`

## Additional Note: N+1 Query

The logs also showed an N+1 query warning for smartmenus:
```
Pattern: SELECT "smartmenus".* FROM "smartmenus" WHERE "smartmenus"."restaurant_id" = $N AND "smartmenus"."menu_id" = $N AND "smartmenus"."tablesetting_id" IS NULL
Executed 10+ times
```

This is a separate performance issue unrelated to auto-save functionality. The auto-save is now working correctly despite this warning.

To fix the N+1 in the future, eager load smartmenus associations when loading menus:
```ruby
restaurant.menus.includes(:smartmenus).where(archived: false)
```
