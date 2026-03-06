# Menu Sorting Debugging

## Error Encountered
```
PATCH http://localhost:3000/restaurants/1/menus/update_sequence 422 (Unprocessable Content)
```

## Changes Made for Debugging

### 1. Enhanced Controller Logging
Added comprehensive logging to `MenusController#update_sequence`:
- Logs all incoming params
- Logs the order array
- Logs each item being processed
- Logs full error backtraces

### 2. Enhanced JavaScript Logging
Added detailed console logging to `sortable_controller.js`:
- Logs the URL being called
- Logs the CSRF token
- Logs the order data being sent
- Logs the full response (status and data)
- Logs errors with details

### 3. Simplified Authorization
Changed from:
```ruby
authorize Menu.new(restaurant: @restaurant)
```

To:
```ruby
unless @restaurant.user_id == current_user.id
  return render json: { status: 'error', message: 'Unauthorized' }, status: :forbidden
end
```

**Reason**: Creating a new Menu object for authorization might not work properly with Pundit policies that check `record.restaurant`.

## How to Debug

1. **Refresh the page** at `http://localhost:3000/restaurants/1/edit?section=menus`
2. **Open browser console** (F12)
3. **Drag a menu** up or down
4. **Check console output** for:
   - "Sending order to:" - Confirms URL
   - "CSRF Token:" - Verifies token exists
   - "Order data:" - Shows the data structure
   - "Response:" - Shows server response

5. **Check Rails console** (terminal running `rails s`) for:
   - "Received params:" - Shows what Rails received
   - "Order array:" - Shows the parsed array
   - "Processing item:" - Shows each menu being updated
   - Any error messages

## Common Issues to Check

### 1. CSRF Token Missing
- **Symptom**: `X-CSRF-Token` is null or undefined
- **Solution**: Ensure `<meta name="csrf-token">` exists in layout

### 2. Wrong Parameter Format
- **Symptom**: Order array is empty or malformed
- **Solution**: Check that `data-sortable-id` attributes are set correctly

### 3. Authorization Failure
- **Symptom**: "Unauthorized" message
- **Solution**: Verify user is logged in and owns the restaurant

### 4. Menu Not Found
- **Symptom**: "Menu not found" error
- **Solution**: Check that menu IDs in `data-sortable-id` are valid

## Expected Console Output (Success)

```
New order: [{id: "1", sequence: 0}, {id: "2", sequence: 1}, ...]
Sending order to: /restaurants/1/menus/update_sequence
CSRF Token: <token-string>
Order data: [{id: "1", sequence: 0}, {id: "2", sequence: 1}, ...]
Response: 200 {status: "success", message: "Menus reordered successfully"}
✓ Order saved
```

## Expected Rails Log Output (Success)

```
Received params: <ActionController::Parameters {..., "order"=>[...], ...}>
Order array: [{"id"=>"1", "sequence"=>0}, {"id"=>"2", "sequence"=>1}, ...]
Processing item: {"id"=>"1", "sequence"=>0}
Processing item: {"id"=>"2", "sequence"=>1}
...
Completed 200 OK
```

## Next Steps After Seeing Logs

1. If CSRF token is missing → Check layout for meta tag
2. If params are wrong format → Check JavaScript data structure
3. If authorization fails → Check user session
4. If specific error appears → Address that error directly
