# Menu Localization Quick Action

## Overview
Added a quick action panel on the menu edit page to trigger automatic localization of menu content to all configured restaurant locales.

## Location
- **URL:** `http://localhost:3000/restaurants/:restaurant_id/menus/:id/edit`
- **UI Position:** Between page header and tabs section

## Features

### UI Panel
- **Visibility:** Only displays when restaurant has active locales configured
- **Design:** Modern card with shadow, consistent with 2025 design system
- **Content:**
  - Title: "Menu Localization" with translate icon
  - Description: Shows which languages are configured (e.g., "EN, IT, ES")
  - Button: Primary action button with globe icon

### Functionality
When user clicks "Localize Menu":
1. **Confirmation Dialog:** Asks user to confirm translation to N language(s)
2. **Job Trigger:** Enqueues `MenuLocalizationJob` with `('menu', menu_id)`
3. **Feedback:** Shows flash notice about job being queued
4. **Redirect:** Returns to menu edit page

### Backend Job
The job (`MenuLocalizationJob`) handles:
- Translating menu name and description to all active locales
- Translating all menu sections (names and descriptions)
- Translating all menu items (names and descriptions)
- Using AI translation service (OpenAI GPT)
- Creating/updating locale records in database

## Files Modified

### 1. Routes (`config/routes.rb`)
```ruby
resources :menus do
  member do
    post :localize  # Added
    # ... other actions
  end
end
```

**Route Generated:**
- Path: `POST /restaurants/:restaurant_id/menus/:id/localize`
- Helper: `localize_restaurant_menu_path(restaurant, menu)`

### 2. Controller (`app/controllers/menus_controller.rb`)
Added `localize` action:
- Authorizes user with Pundit (requires update permission)
- Checks for active restaurant locales
- Triggers `MenuLocalizationJob.perform_async('menu', menu_id)`
- Provides user feedback via flash messages
- Redirects back to edit page

### 3. View (`app/views/menus/edit.html.erb`)
Added localization panel:
- Queries active restaurant locales
- Conditionally renders panel if locales exist
- Uses 2025 design system classes
- Includes Turbo confirmation dialog
- Displays locale count and codes

## Usage Example

### For Restaurant with IT and ES Locales

**Panel Text:**
> **Menu Localization**
> Translate this menu to all configured languages (IT, ES)

**Button:** "🌐 Localize Menu"

**Confirmation:**
> This will translate all menu sections and items to 2 language(s). Continue?

**Success Message:**
> Menu localization to 2 locale(s) has been queued. This may take a few moments.

### Background Processing
1. Job fetches menu and all active restaurant locales
2. For each locale:
   - Translates menu metadata
   - Translates all sections
   - Translates all items
3. Creates/updates localization records:
   - `Menulocale`
   - `Menusectionlocale`
   - `Menuitemlocale`

## Translation Logic

The job uses `LocalizeMenuService` which:
1. Skips default locale (no translation needed)
2. Batches API calls to OpenAI
3. Preserves formatting and structure
4. Handles errors gracefully
5. Logs progress and statistics

## User Experience Flow

1. **Admin visits menu edit page**
   - Sees localization panel if locales configured
   
2. **Clicks "Localize Menu"**
   - Confirmation dialog appears
   
3. **Confirms action**
   - Job is queued
   - Flash notice appears
   - Page refreshes
   
4. **Job runs in background**
   - Translations are created
   - Takes a few seconds to minutes depending on menu size
   
5. **Translations available**
   - Smartmenu now displays in multiple languages
   - Users can switch locales via flag buttons

## Testing

### Manual Test
```bash
# 1. Ensure restaurant has active locales
rails console
restaurant = Restaurant.find(1)
Restaurantlocale.create!(restaurant: restaurant, locale: 'IT', status: 'active')
Restaurantlocale.create!(restaurant: restaurant, locale: 'ES', status: 'active')

# 2. Visit menu edit page
# http://localhost:3000/restaurants/1/menus/16/edit

# 3. Click "Localize Menu" button

# 4. Check Sidekiq dashboard for job
# http://localhost:3000/sidekiq

# 5. Verify translations created
menu = Menu.find(16)
Menulocale.where(menu: menu, locale: 'it').count
Menusectionlocale.where(menusection_id: menu.menusections.first.id, locale: 'it').first
```

### Automated Test
```ruby
# test/controllers/menus_controller_test.rb
test "should trigger localization job" do
  # Setup
  restaurant = restaurants(:one)
  menu = menus(:one)
  Restaurantlocale.create!(restaurant: restaurant, locale: 'IT', status: 'active')
  
  # Sign in
  sign_in users(:one)
  
  # Trigger localization
  assert_enqueued_with(job: MenuLocalizationJob, args: ['menu', menu.id]) do
    post localize_restaurant_menu_path(restaurant, menu)
  end
  
  # Verify redirect and flash
  assert_redirected_to edit_restaurant_menu_path(restaurant, menu)
  assert_match /queued/, flash[:notice]
end
```

## Security

### Authorization
- Uses Pundit for authorization
- Requires `update?` permission on menu
- Same permissions as other menu edit actions

### Data Validation
- Checks for active locales before proceeding
- Validates menu exists
- Job handles missing records gracefully

## Performance Considerations

### API Calls
- Translation uses OpenAI API (costs money)
- Rate limits apply
- Job retries on failure (3 attempts)

### Database
- Creates many locale records
- Uses transactions where appropriate
- Indexes on locale columns

### User Impact
- Action is async (no page blocking)
- Flash message provides feedback
- Job queue can be monitored

## Future Enhancements

### Potential Improvements
1. **Progress indicator** - Real-time progress via ActionCable
2. **Selective translation** - Choose specific sections/items
3. **Re-translate** - Button to re-run translations
4. **Translation preview** - Review before saving
5. **Cost estimate** - Show API cost before running
6. **Batch operations** - Localize multiple menus at once

## Related Documentation
- `app/jobs/menu_localization_job.rb`
- `app/services/localize_menu_service.rb`
- `test/LOCALE_SWITCHING_TEST_PLAN.md`
