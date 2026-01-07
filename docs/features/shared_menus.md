# Shared Menus (Restaurant Chains)

## Goal
Support menus that can be shared across multiple restaurants (restaurant chains), while keeping each restaurant’s operational configuration separate.

### Not shared (restaurant-specific)
- Taxes
- Tips
- Tables
- Staff
- Languages
- Other restaurant settings

### Shared (common)
- Menu definition and content (menu, sections, items, etc.)

## Product constraints
- Restaurants cannot override prices.
- Restaurants can override menu availability.
- A non-owner restaurant (Restaurant B) is read-only for menu content.
- Taxes and tips are not part of shared menus.
- Chain/org model will be added later; initial sharing is limited to restaurants owned by the same user.

## Chosen approach
### Option A
Treat `Menu` as the canonical shared object. Attach menus to restaurants using a join model.

### Availability override: Option 2
Menu-level-only overrides per restaurant using:
- `availability_override_enabled` (boolean)
- `availability_state` (enum)

Semantics:
- If `availability_override_enabled = false`, the restaurant does not override availability (falls back to menu default behavior).
- If `availability_override_enabled = true`, the restaurant’s effective availability is forced by `availability_state`.

## Data model
### New join model: `RestaurantMenu`
Create a join table between restaurants and menus.

`restaurant_menus`
- `restaurant_id` (FK)
- `menu_id` (FK)
- `sequence` (int, nullable) — ordering in that restaurant’s UI
- `status` (enum) — per restaurant: `active`, `inactive`, `archived`
- `availability_override_enabled` (boolean, default: false)
- `availability_state` (enum, default: available)
- timestamps

Indexes:
- Unique: `[:restaurant_id, :menu_id]`

### Menu ownership
Add to `menus`:
- `owner_restaurant_id` (FK)

Ownership semantics:
- The owner restaurant controls edits to shared menu content.
- Attached restaurants cannot edit content.

## Authorization (Pundit)
### `MenuPolicy`
- `update?`: allowed only if the current user owns `menu.owner_restaurant`.

### `RestaurantMenuPolicy` (new)
- `update?` (sequence/status/availability override): allowed if current user owns `restaurant_menu.restaurant`.
- `attach?` / `detach?`: allowed if current user owns the target restaurant AND owns the menu’s owner restaurant.

This enforces:
- Restaurant B can manage attachment settings but cannot edit menu content.

## Backend endpoints
All restaurant-scoped. Attachment settings act on `RestaurantMenu` rows.

### Attach / detach
- `POST /restaurants/:restaurant_id/menus/:menu_id/attach`
- `DELETE /restaurants/:restaurant_id/menus/:menu_id/detach`

### Reorder (sequence persistence)
- `PATCH /restaurants/:restaurant_id/restaurant_menus/reorder`
  - payload: `order: [{id, sequence}]` where `id` is `restaurant_menu.id`

### Bulk status update
- `PATCH /restaurants/:restaurant_id/restaurant_menus/bulk_update`
  - params: `restaurant_menu_ids[]`, `status`

### Availability override
- `PATCH /restaurants/:restaurant_id/restaurant_menus/:id/availability`
  - params: `availability_override_enabled`, `availability_state`

Optional bulk:
- `PATCH /restaurants/:restaurant_id/restaurant_menus/bulk_availability`
  - params: `restaurant_menu_ids[]`, `availability_override_enabled`, `availability_state`

## UI changes
### Restaurant edit → Menus section
Replace list of menus owned by restaurant with list of attached menus (`RestaurantMenu` rows).

Per row:
- Drag handle (sequence)
- Checkbox (bulk status)
- Menu name (from `Menu`)
- Status (from `RestaurantMenu`)
- Availability (computed from override settings)
- Actions:
  - View menu (allowed for attached restaurants)
  - Edit menu (only if `policy(menu).update?`)
  - Detach (allowed if `RestaurantMenuPolicy.detach?`)

Sharing flow (initial):
- From owner restaurant: select another restaurant you own and attach the menu.

## Migration strategy
### Phase 1: additive (safe)
- Add `restaurant_menus` and `menus.owner_restaurant_id`.
- Backfill for existing data:
  - Set `menus.owner_restaurant_id` from existing `menus.restaurant_id` (or equivalent).
  - Create a `restaurant_menus` attachment row for the original restaurant.
  - Copy existing per-restaurant fields (e.g. sequence/status) to the join.

### Phase 2: enable sharing
- Implement attach/detach UI and endpoints.
- Enforce read-only behavior for non-owner restaurants.

### Phase 3: remove old coupling (later)
- Remove reliance on `menus.restaurant_id`.
- Update any queries to use restaurant attachments.

## Indexing / caching implications
- Editing menu content should fan-out to all attached restaurants’ indexes.
- Updating attachment settings (status/sequence/availability override) should only affect that restaurant’s index/visibility.

## Testing
- Policy tests:
  - Non-owner restaurant cannot edit menu content.
  - Owner restaurant can edit content.
  - Attached restaurant can reorder/bulk update status/availability override.
- Request/system tests:
  - Attach menu from A to B.
  - Menu appears in B’s list.
  - Reorder in B does not affect ordering in A.
  - Availability override affects only restaurant B.
