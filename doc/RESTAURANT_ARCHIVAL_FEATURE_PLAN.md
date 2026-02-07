# Restaurant Archiving Feature Implementation Plan

## Executive Summary

This document outlines a comprehensive plan for implementing a clear and consistent approach to archiving restaurants and propagating that archival request to all entities under the restaurant. The feature will also allow for individual menus within a restaurant to be archived independently. Once archived, the objects and their children will be non-visible in the UI.

## Current State Analysis

### Existing Archive Infrastructure

The application already has significant infrastructure in place for archiving:

1. **SoftDeletable Concern** (`app/models/concerns/soft_deletable.rb`):
   - Provides `archive!`, `restore!`, `archived?`, `active?` methods
   - Includes scopes: `active`, `archived`, `not_archived`
   - Supports `archived_at` timestamp and optional `archived_reason`, `archived_by_id` fields
   - Provides `archive_all` and `restore_all` class methods

2. **Existing Models with Archive Support**:
   - `Restaurant` - has `archived` boolean, `archived_at` datetime, `status` enum with `archived: 2`
   - `Menu` - has `archived` boolean, `archived_at` datetime, `status` enum with `archived: 2`
   - `Menusection` - has `archived` boolean, `status` enum with `archived: 2`
   - `Menuitem` - has `archived` boolean, `status` enum with `archived: 2`
   - `Tax` - has `archived` boolean, `status` enum with `archived: 2`
   - `Tip` - has `archived` boolean, `status` enum with `archived: 2`
   - `Employee` - has `archived` boolean, `status` enum with `archived: 2`
   - `Allergyn` - has `archived` boolean, `status` enum with `archived: 2`
   - `Size` - has `archived` boolean, `status` enum with `archived: 2`
   - `Tablesetting` - has `archived` boolean, `status` enum with `archived: 2`
   - `Restaurantlocale` - has `archived` boolean, `status` enum with `archived: 2`
   - `RestaurantMenu` - has `archived` boolean, `status` enum with `archived: 2`
   - `Inventory` - has `archived` boolean, `status` enum with `archived: 2`

3. **Existing Controller Patterns**:
   - Most controllers already have `destroy` actions that set `archived: true`
   - Examples: `employees_controller.rb`, `taxes_controller.rb`, `tips_controller.rb`, `sizes_controller.rb`, etc.
   - Index actions filter by `archived: false` by default

4. **Existing Scopes**:
   - `Menu.for_customer_display` - filters `archived: false`
   - `Menu.for_management_display` - filters `archived: false`
   - Most index controllers filter by `archived: false`

### Entity Relationship Hierarchy

```
Restaurant (1) → has_many → Menus (N)
    → has_many → Menusections (through Menus)
    → has_many → Menuitems (through Menusections)
    → has_many → RestaurantMenus (N)
    → has_many → Shared Menus (through RestaurantMenus)
    → has_many → Tablesettings
    → has_many → Employees
    → has_many → Taxes
    → has_many → Tips
    → has_many → Restaurantavailabilities
    → has_many → Restaurantlocales
    → has_many → Allergyns
    → has_many → Sizes
    → has_many → Ordrs
    → has_many → OcrMenuImports
    → has_many → Tracks
    → has_one → AlcoholPolicy
    → has_one → PaymentProfile
    → has_one → RestaurantSubscription
    → has_one → Genimage
```

## Proposed Architecture

### 1. Core Service: RestaurantArchivalService

Create a new service `app/services/restaurant_archival_service.rb` that handles:

```ruby
class RestaurantArchivalService < BaseService
  # Archive a restaurant and all its children
  # Options:
  #   :cascade - Whether to archive all child entities (default: true)
  #   :archive_reason - Optional reason for archiving
  #   :archived_by - User who performed the archive
  #   :async - Whether to perform asynchronously (default: true for large datasets)
  def archive(restaurant, cascade: true, archive_reason: nil, archived_by: nil, async: true)
  end

  # Unarchive a restaurant and optionally its children
  def unarchive(restaurant, cascade: true, archived_by: nil, async: true)
  end

  # Archive only menus (independent of restaurant archival)
  def archive_menus(menus, cascade: true, archive_reason: nil, archived_by: nil)
  end

  # Unarchive only menus
  def unarchive_menus(menus, cascade: true, archived_by: nil)
  end
end
```

### 2. Background Jobs

Create background jobs for handling large archival operations:

```ruby
# app/jobs/archive_restaurant_job.rb
class ArchiveRestaurantJob < ApplicationJob
  queue_as :default
  
  def perform(restaurant_id, cascade: true, archive_reason: nil, archived_by_id: nil)
    restaurant = Restaurant.find(restaurant_id)
    RestaurantArchivalService.archive!(
      restaurant,
      cascade: cascade,
      archive_reason: archive_reason,
      archived_by: archived_by_id ? User.find(archived_by_id) : nil
    )
  end
end

# app/jobs/unarchive_restaurant_job.rb
class UnarchiveRestaurantJob < ApplicationJob
  queue_as :default
  
  def perform(restaurant_id, cascade: true, archived_by_id: nil)
    # Similar implementation for unarchiving
  end
end

# app/jobs/archive_menu_job.rb
class ArchiveMenuJob < ApplicationJob
  queue_as :default
  
  def perform(menu_id, cascade: true, archive_reason: nil, archived_by_id: nil)
    menu = Menu.find(menu_id)
    RestaurantArchivalService.archive_menu!(
      menu,
      cascade: cascade,
      archive_reason: archive_reason,
      archived_by: archived_by_id ? User.find(archived_by_id) : nil
    )
  end
end
```

### 3. Cascading Archive Logic

#### Restaurant-Level Archive (Full Cascade)
When archiving a restaurant:
1. Set `restaurant.archived = true`, `restaurant.status = :archived`
2. Archive all owned menus (`menu.archived = true`, `menu.status = :archived`)
3. Archive all menu sections (`menusection.archived = true`, `menusection.status = :archived`)
4. Archive all menu items (`menuitem.archived = true`, `menuitem.status = :archived`)
5. Archive all tablesettings (`tablesetting.archived = true`, `tablesetting.status = :archived`)
6. Archive all employees (`employee.archived = true`, `employee.status = :archived`)
7. Archive all taxes (`tax.archived = true`, `tax.status = :archived`)
8. Archive all tips (`tip.archived = true`, `tip.status = :archived`)
9. Archive all allergyns (`allergyn.archived = true`, `allergyn.status = :archived`)
10. Archive all sizes (`size.archived = true`, `size.status = :archived`)
11. Archive all restaurant locales (`restaurantlocale.archived = true`, `restaurantlocale.status = :archived`)
12. Archive all restaurant availabilities (`restaurantavailability.archived = true`)
13. Archive all OCR menu imports (`ocr_menu_import.archived = true`)
14. Archive all tracks (`track.archived = true`)

**Note**: Do NOT archive:
- Orders (`ordrs`) - Keep historical data
- Payment profiles and provider accounts - May be needed for billing disputes
- Restaurant menu associations for shared menus - Only archive owned menus

#### Menu-Level Archive (Independent)
When archiving a menu independently:
1. Set `menu.archived = true`, `menu.status = :archived`
2. Archive all menu sections (`menusection.archived = true`, `menusection.status = :archived`)
3. Archive all menu items (`menuitem.archived = true`, `menuitem.status = :archived`)

**Note**: Do NOT archive:
- RestaurantMenu associations (shared menu references remain for the restaurant)
- Only archive the actual menu content

### 4. Unarchiving Strategy

#### Restaurant-Level Unarchive
When unarchiving a restaurant:
1. Set `restaurant.archived = false`, `restaurant.status = :active` (or preserve original status)
2. Unarchive all menus
3. Unarchive all menusections
4. Unarchive all menuitems
5. Unarchive all dependent entities (tablesettings, employees, taxes, tips, etc.)

**Important**: When unarchiving, respect user choices for menu-level archival:
- A menu that was independently archived should remain archived
- A menu that was archived as part of restaurant archival should be unarchived

#### Menu-Level Unarchive
When unarchiving a menu independently:
1. Set `menu.archived = false`, `menu.status = :active` (or preserve original status)
2. Unarchive all menusections
3. Unarchive all menuitems

### 5. Scope Updates

Update all relevant scopes to consistently filter archived records:

```ruby
# In Restaurant model
scope :visible, -> { where(archived: false) }
scope :archived, -> { where(archived: true) }
scope :with_archived, -> { unscope(where: :archived) }

# In Menu model (already exists)
scope :for_customer_display, -> { where(archived: false, status: 'active') }
scope :for_management_display, -> { where(archived: false) }

# Add to other models as needed
```

### 6. Controller Actions

#### RestaurantsController
Add archive/unarchive actions:

```ruby
# PATCH /restaurants/:id/archive
def archive
  authorize @restaurant, :update?
  
  if RestaurantArchivalService.archive(@restaurant, cascade: true, archived_by: current_user)
    redirect_to restaurants_path, notice: 'Restaurant archived successfully'
  else
    redirect_to @restaurant, alert: 'Failed to archive restaurant'
  end
end

# PATCH /restaurants/:id/unarchive
def unarchive
  authorize @restaurant, :update?
  
  if RestaurantArchivalService.unarchive(@restaurant, cascade: true, archived_by: current_user)
    redirect_to @restaurant, notice: 'Restaurant restored successfully'
  else
    redirect_to @restaurant, alert: 'Failed to restore restaurant'
  end
end
```

#### MenusController
Enhance existing archive/unarchive for independent menu archival:

```ruby
# PATCH /restaurants/:restaurant_id/menus/:id/archive
def archive
  authorize @menu, :update?
  
  if RestaurantArchivalService.archive_menu(@menu, cascade: true, archived_by: current_user)
    redirect_to edit_restaurant_menu_path(@restaurant, @menu), 
                notice: 'Menu archived successfully'
  else
    redirect_to edit_restaurant_menu_path(@restaurant, @menu), 
                alert: 'Failed to archive menu'
  end
end

# PATCH /restaurants/:restaurant_id/menus/:id/unarchive
def unarchive
  authorize @menu, :update?
  
  if RestaurantArchivalService.unarchive_menu(@menu, cascade: true, archived_by: current_user)
    redirect_to edit_restaurant_menu_path(@restaurant, @menu), 
                notice: 'Menu restored successfully'
  else
    redirect_to edit_restaurant_menu_path(@restaurant, @menu), 
                alert: 'Failed to restore menu'
  end
end
```

### 7. Policy Updates

Update Pundit policies to handle archive/unarchive:

```ruby
# app/policies/restaurant_policy.rb
class RestaurantPolicy < ApplicationPolicy
  def archive?
    user.admin? || user.manager? && record.user == user
  end
  
  def unarchive?
    archive?
  end
end

# app/policies/menu_policy.rb
class MenuPolicy < ApplicationPolicy
  def archive?
    user.admin? || user.manager? && record.restaurant.user == user
  end
  
  def unarchive?
    archive?
  end
end
```

### 8. UI Components

#### Restaurant Index Page
- Add "Archive" button for each restaurant
- Add "Show Archived" filter toggle
- Show archived restaurants with visual distinction (greyed out)

#### Restaurant Show/Edit Page
- Add "Archive Restaurant" button (with confirmation dialog)
- Add "Restore Restaurant" button (if archived)

#### Menu Index/Edit Page
- Add "Archive" button for each menu
- Add "Show Archived" filter toggle
- Menus can be archived independently even if restaurant is active

#### Menu Show/Edit Page
- Add "Archive Menu" button
- Add "Restore Menu" button (if archived)

### 9. API Endpoints (Optional)

If needed for mobile apps or external integrations:

```ruby
# config/routes.rb
resources :restaurants do
  member do
    patch :archive
    patch :unarchive
  end
end

resources :menus do
  member do
    patch :archive
    patch :unarchive
  end
end
```

### 10. Cache Invalidation

Ensure proper cache invalidation when archiving/unarchiving:

```ruby
# In RestaurantArchivalService
after_archive do |restaurant|
  AdvancedCacheService.invalidate_restaurant_caches(restaurant.id)
  AdvancedCacheService.invalidate_menu_caches(restaurant.menus.pluck(:id))
end
```

## Implementation Phases

### Phase 1: Core Infrastructure (Days 1-2)
1. Create `RestaurantArchivalService` with basic archive/unarchive logic
2. Add background jobs for async processing
3. Update controller actions for restaurants and menus
4. Add routes for archive/unarchive endpoints
5. Write unit tests for the service

### Phase 2: Cache and Scope Updates (Day 3)
1. Update all relevant scopes to filter archived records
2. Ensure cache invalidation works correctly
3. Update `AdvancedCacheService` if needed
4. Test all display paths

### Phase 3: UI Implementation (Days 4-5)
1. Add archive buttons to restaurant index/show/edit pages
2. Add archive buttons to menu index/show/edit pages
3. Implement "Show Archived" filters
4. Add confirmation dialogs for destructive actions
5. Style archived items appropriately

### Phase 4: Testing and Polish (Days 6-7)
1. Integration tests for full archival workflow
2. Unarchive workflow testing
3. Edge case testing (shared menus, large datasets)
4. Performance testing with large restaurants
5. Documentation updates

## Edge Cases and Considerations

### 1. Shared Menus
When a menu is shared between multiple restaurants:
- Archiving the menu should only affect its content (sections, items)
- The RestaurantMenu association should remain (status: :archived)
- Other restaurants' references remain but show as unavailable

### 2. Large Restaurants
For restaurants with many entities:
- Always use background jobs for archiving
- Use `find_each` for batch updates
- Consider transaction size limits

### 3. Historical Orders
Never archive orders - they represent historical data:
- Keep orders accessible for analytics
- Orders reference archived menus/items should still display menu item details

### 4. Payment Data
Never archive payment-related data:
- Payment profiles needed for potential refunds
- Provider accounts needed for billing disputes

### 5. Concurrent Operations
Consider concurrent archive/unarchive operations:
- Use database locks for critical sections
- Implement idempotent operations
- Add status tracking to prevent conflicts

### 6. Partial Failures
Handle partial failures gracefully:
- Implement rollback for failed transactions
- Log all failures with context
- Provide user feedback on what succeeded/failed

## Migration Strategy

Add database migrations for any missing columns:

```ruby
# db/migrate/[timestamp]_add_archive_fields_to_entities.rb

# For entities that don't have archived_at
add_column :restaurants, :archived_at, :datetime
add_column :menus, :archived_at, :datetime
add_column :menusections, :archived_at, :datetime
add_column :menuitems, :archived_at, :datetime
# ... etc

# Add archived_reason and archived_by_id if needed
add_column :restaurants, :archived_reason, :string
add_column :restaurants, :archived_by_id, :bigint
```

## Rollback Strategy

1. Keep all archived data in database (soft delete only)
2. Use background jobs for long-running operations
3. Implement comprehensive logging
4. Create backup before major archive operations (optional)

## Success Metrics

1. All archive operations complete without errors
2. Archived items are hidden from UI (visible only when "Show Archived" is enabled)
3. Unarchive operations restore data correctly
4. Cache invalidation works properly
5. Performance is acceptable for large datasets

## Documentation Requirements

1. Update API documentation for new endpoints
2. Add admin documentation for archive workflow
3. Document the cascading behavior
4. Include troubleshooting guide
