# Shared Menus (Restaurant Chains)

## Goal
Support menus that can be shared across multiple restaurants (restaurant chains), while keeping each restaurant’s operational configuration separate.

### Not shared (restaurant-specific)
- [x] Taxes
- [x] Tips
- [x] Tables
- [x] Staff
- [x] Languages
- [x] Other restaurant settings

### Shared (common)
- [x] Menu definition and content (menu, sections, items, etc.)

## Product constraints
- [x] Restaurants cannot override prices.
- [x] Restaurants can override menu availability.
- [x] A non-owner restaurant (Restaurant B) is read-only for menu content.
- [x] Taxes and tips are not part of shared menus.
- [x] Chain/org model will be added later; initial sharing is limited to restaurants owned by the same user.

## Chosen approach
### Option A
Treat `Menu` as the canonical shared object. Attach menus to restaurants using a join model.

### Availability override: Option 2
Menu-level-only overrides per restaurant using:
- [x] `availability_override_enabled` (boolean)
- [x] `availability_state` (enum)

Semantics:
- [x] If `availability_override_enabled = false`, the restaurant does not override availability (falls back to menu default behavior).
- [x] If `availability_override_enabled = true`, the restaurant’s effective availability is forced by `availability_state`.

## Data model
### New join model: `RestaurantMenu`
Create a join table between restaurants and menus.

`restaurant_menus`
- [x] `restaurant_id` (FK)
- [x] `menu_id` (FK)
- [x] `sequence` (int, nullable) — ordering in that restaurant’s UI
- [x] `status` (enum) — per restaurant: `active`, `inactive`, `archived`
- [x] `availability_override_enabled` (boolean, default: false)
- [x] `availability_state` (enum, default: available)
- [x] timestamps

Indexes:
- [x] Unique: `[:restaurant_id, :menu_id]`

### Menu ownership
Add to `menus`:
- [x] `owner_restaurant_id` (FK)

Ownership semantics:
- [x] The owner restaurant controls edits to shared menu content.
- [x] Attached restaurants cannot edit content.

## Authorization (Pundit)
### `MenuPolicy`
- [x] `update?`: allowed only if the current user owns `menu.owner_restaurant`.

### `RestaurantMenuPolicy` (new)
- [x] `update?` (sequence/status/availability override): allowed if current user owns `restaurant_menu.restaurant`.
- [x] `attach?` / `detach?`: allowed if current user owns the target restaurant AND owns the menu’s owner restaurant.

This enforces:
- [x] Restaurant B can manage attachment settings but cannot edit menu content.

## Backend endpoints
All restaurant-scoped. Attachment settings act on `RestaurantMenu` rows.

### Attach / detach
- [x] `POST /restaurants/:restaurant_id/menus/:menu_id/attach`
- [x] `DELETE /restaurants/:restaurant_id/menus/:menu_id/detach`

### Reorder (sequence persistence)
- [x] `PATCH /restaurants/:restaurant_id/restaurant_menus/reorder`
  - [x] payload: `order: [{id, sequence}]` where `id` is `restaurant_menu.id`

### Bulk status update
- [x] `PATCH /restaurants/:restaurant_id/restaurant_menus/bulk_update`
  - [x] params: `restaurant_menu_ids[]`, `status`

### Availability override
- [x] `PATCH /restaurants/:restaurant_id/restaurant_menus/:id/availability`
  - [x] params: `availability_override_enabled`, `availability_state`

Optional bulk:
- [x] `PATCH /restaurants/:restaurant_id/restaurant_menus/bulk_availability`
  - [x] params: `restaurant_menu_ids[]`, `availability_override_enabled`, `availability_state`

## UI changes
### Restaurant edit → Menus section
Replace list of menus owned by restaurant with list of attached menus (`RestaurantMenu` rows).

Per row:
- [x] Drag handle (sequence)
- [x] Checkbox (bulk status)
- [x] Menu name (from `Menu`)
- [x] Status (from `RestaurantMenu`)
- [x] Availability (computed from override settings)
- [x] Actions:
  - [x] View menu (allowed for attached restaurants)
  - [x] Edit menu (only if `policy(menu).update?`)
  - [x] Detach (allowed if `RestaurantMenuPolicy.detach?`)

Sharing flow (initial):
- [x] From owner restaurant: select another restaurant you own and attach the menu.

## Migration strategy
### Phase 1: additive (safe)
- [x] Add `restaurant_menus` and `menus.owner_restaurant_id`.
- [x] Backfill for existing data:
  - [x] Set `menus.owner_restaurant_id` from existing `menus.restaurant_id` (or equivalent).
  - [x] Create a `restaurant_menus` attachment row for the original restaurant.
  - [x] Copy existing per-restaurant fields (e.g. sequence/status) to the join.

### Phase 2: enable sharing
- [x] Implement attach/detach UI and endpoints.
- [x] Enforce read-only behavior for non-owner restaurants.

### Phase 3: remove old coupling (later)
- [ ] Remove reliance on `menus.restaurant_id`.
- [x] Update any queries to use restaurant attachments.

## Indexing / caching implications
- [x] Editing menu content should fan-out to all attached restaurants’ indexes.
- [x] Updating attachment settings (status/sequence/availability override) should only affect that restaurant’s index/visibility.

## Testing
- [x] Policy tests:
  - [x] Non-owner restaurant cannot edit menu content.
  - [x] Owner restaurant can edit content.
  - [x] Attached restaurant can reorder/bulk update status/availability override.
- [x] Request/system tests:
  - [x] Attach menu from A to B.
  - [x] Menu appears in B’s list.
  - [x] Reorder in B does not affect ordering in A.
  - [x] Availability override affects only restaurant B.

## Missing from spec (implemented)
- [x] `POST /restaurants/:restaurant_id/menus/:id/share` endpoint for bulk attach to one or many of the user’s other restaurants.
- [x] UI: “Shared” badge + subtle row styling in restaurant menus list to distinguish attached menus from owned menus.
- [x] Menu edit: read-only context flag is computed (`@read_only_menu_context`) and passed into 2025 section partials to hide editing controls in shared context.
- [x] `ensure_smartmenus_for_restaurant_menu!` ensures Smartmenu rows exist for attached menus per restaurant (including per tablesetting).

## Missing from spec (gaps / follow-ups)
- [x] Controller-level enforcement that attached restaurants cannot edit menu content.
  - Today, `MenusController` blocks write actions via `ensure_owner_restaurant_context!`, but other controllers (e.g. `MenusectionsController`, `MenuitemsController`, `MenuavailabilitiesController`) do not consistently enforce the same rule.
- [x] Restaurant menus list UI: availability override controls for attached restaurants.
  - The backend supports per-restaurant overrides via `RestaurantMenusController#availability`, but the menus list currently shows a badge (not an editable dropdown) for attached menus.
- [x] Tests for sharing behavior as listed in the spec.
