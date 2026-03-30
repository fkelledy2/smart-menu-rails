# Menu Versioning System

## Status
- Priority Rank: #13.5 (built — see note below)
- Category: Already Shipped
- Effort: Complete
- Dependencies: None

> **Important**: This system is fully implemented. This document captures the as-built specification for use by Menu Experiments (#14) and any future features that build on versioning. It is NOT a pending development task.

---

## Problem Statement
Restaurant owners needed a way to save point-in-time snapshots of their menus so they could roll back changes, compare versions, and in future support experiments. Without versioning, any destructive menu edit was permanent and irreversible, creating risk for live restaurants making iterative changes during service.

## What Was Built

The MenuVersion system is live in production with the following components:

### Data Model

**`menu_versions` table** (in `db/schema.rb`):

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint | PK |
| `menu_id` | bigint | FK → menus, NOT NULL |
| `version_number` | integer | Auto-incremented per menu, NOT NULL, unique with menu_id |
| `snapshot_json` | jsonb | Complete point-in-time snapshot, default: {}, NOT NULL |
| `is_active` | boolean | Whether this is the currently active version, default: false |
| `starts_at` | datetime | Optional scheduled activation window start |
| `ends_at` | datetime | Optional scheduled activation window end |
| `created_by_user_id` | bigint | FK → users, nullable |
| `created_at` / `updated_at` | datetime | Standard Rails timestamps |

**Indexes:**
- `[menu_id, version_number]` — unique (enforces per-menu sequential numbering)
- `[menu_id, is_active]` — fast active-version lookup
- `[menu_id, starts_at, ends_at]` — windowed version queries
- `[created_by_user_id]` — audit lookups

### Model (`app/models/menu_version.rb`)

- `belongs_to :menu`
- `belongs_to :created_by_user, class_name: 'User', optional: true`
- All content columns (`menu_id`, `version_number`, `snapshot_json`, `created_by_user_id`) are `attr_readonly` — versions are immutable once created
- `version_number` is unique scoped to `menu_id`
- Class method `MenuVersion.create_from_menu!(menu:, user: nil)` — acquires advisory lock on menu, increments version number, calls `MenuVersionSnapshotService`, creates record

### Menu Model Integration (`app/models/menu.rb`)

- `has_many :menu_versions, -> { reorder(version_number: :desc) }, dependent: :destroy`
- `Menu#active_menu_version(at: Time.current)` — resolution logic:
  1. Returns the highest-versioned windowed version whose `starts_at`/`ends_at` window contains `at`
  2. Falls back to any version with `is_active: true`
  3. Falls back to the highest version number overall

### Snapshot Content

`MenuVersionSnapshotService.snapshot_for(menu)` captures a complete denormalised snapshot at `SCHEMA_VERSION = 1`:

```json
{
  "schema_version": 1,
  "menu": { "id", "name", "description", "status", "sequence", "displayImages",
            "allowOrdering", "inventoryTracking", "archived", "covercharge", "voiceOrderingEnabled" },
  "menuavailabilities": [ { "id", "dayofweek", "starthour", "startmin", "endhour", "endmin", "status" } ],
  "menusections": [
    {
      "id", "name", "description", "status", "sequence", "archived", "restricted",
      "fromhour", "frommin", "tohour", "tomin", "tasting_menu", "tasting_price_cents",
      "tasting_currency", "price_per", "min_party_size", "max_party_size",
      "includes_description", "allow_substitutions", "allow_pairing",
      "pairing_price_cents", "pairing_currency",
      "menuitems": [ { "id", "name", "description", "status", "sequence", "calories",
                       "price", "preptime", "archived", "itemtype", "hidden",
                       "tasting_carrier", "tasting_optional", "tasting_supplement_cents",
                       "tasting_supplement_currency", "course_order", "abv",
                       "alcohol_classification", "alcohol_notes", "sommelier_parsed_fields",
                       "sommelier_needs_review", "image_prompt" } ]
    }
  ]
}
```

Only `active` (non-archived) sections and items are included in the snapshot.

### Services

| Service | Location | Purpose |
|---------|----------|---------|
| `MenuVersionSnapshotService` | `app/services/menu_version_snapshot_service.rb` | Produces the `snapshot_json` payload from a live Menu |
| `MenuVersionDiffService` | `app/services/menu_version_diff_service.rb` | Compares two versions; returns added/removed/changed sections and items |
| `MenuVersionActivationService` | `app/services/menu_version_activation_service.rb` | Activates a version (immediate or windowed); deactivates all others for the same menu |
| `MenuVersionApplyService` | `app/services/menu_version_apply_service.rb` | Projects a snapshot back onto live Menu/MenuSection/MenuItem records in memory (for rollback preview or apply) |

### Controller (`app/controllers/menus/versions_controller.rb`)

Mounted inside `Menus::BaseController`. All actions require `authenticate_user!`.

| Route | Method | Action | Pundit |
|-------|--------|--------|--------|
| `GET /restaurants/:restaurant_id/menus/:id/versions` | `versions` | List all versions for a menu | `authorize @menu, :update?` |
| `GET /restaurants/:restaurant_id/menus/:id/versions/diff` | `versions_diff` | Diff two versions (JSON + HTML/Turbo Frame) | `authorize @menu, :update?` |
| `GET /restaurants/:restaurant_id/menus/:id/versions/:from/diff/:to` | `version_diff` | Diff two specific versions (JSON) | `authorize @menu, :update?` |
| `POST /restaurants/:restaurant_id/menus/:id/create_version` | `create_version` | Snapshot current menu state | `authorize @menu, :update?` — owner restaurant context only |
| `POST /restaurants/:restaurant_id/menus/:id/activate_version` | `activate_version` | Activate a version (with optional `starts_at`/`ends_at`) | `authorize @menu, :update?` — owner restaurant context only |

Activation respects the restaurant's timezone when parsing `starts_at`/`ends_at` parameters. Supports both JSON and HTML (`Turbo Frame: menu_versions_diff`) response formats.

### Tests

- `spec/models/menu_version_spec.rb` — model validations, `create_from_menu!`
- `spec/services/menu_version_diff_service_spec.rb` — diff logic
- `spec/requests/menu_versions_ui_spec.rb` — controller/request specs
- `spec/factories/menu_versions.rb` — FactoryBot factory
- `test/models/menu_version_test.rb` — Minitest model tests
- `test/services/menu_version_apply_service_test.rb` — apply service tests

---

## Interface Contract for Menu Experiments (#14)

Menu Experiments needs the following from this system — all of which are already available:

| Requirement from #14 | Available via |
|---------------------|--------------|
| FK `control_version_id` → MenuVersion | `MenuVersion` model with numeric PK |
| FK `variant_version_id` → MenuVersion | Same |
| "Menu must have at least two versions" validation | `menu.menu_versions.count >= 2` |
| Serve a specific version's content at render time | `MenuVersionApplyService.apply_snapshot!` or read `snapshot_json` directly |
| Revert to default version after experiment ends | `menu.active_menu_version` resolution already handles this |

Menu Experiments does NOT need to create, modify, or own the versioning infrastructure. It only needs to reference existing `MenuVersion` records by ID and read their `snapshot_json`.

---

## Known Limitations and Open Questions

1. **`snapshot_json` does not include localised content** — `MenuItemLocale`, `MenuSectionLocale`, `MenuLocale` records are not captured in the snapshot. A menu version served during an experiment will use the live (current) localised text, not the localised text at snapshot time. This is acceptable for v1 experiments but should be documented as a known gap.

2. **`MenuVersionApplyService` operates in-memory only** — it projects snapshot data onto ActiveRecord objects without persisting. For experiment serving, callers should read `snapshot_json` directly rather than calling `apply_snapshot!`, which is designed for rollback preview flows.

3. **No Pundit policy for `MenuVersion` itself** — access is gated via the parent `Menu` policy (`authorize @menu, :update?`). This is sufficient for current use. If direct `MenuVersion` authorisation is ever needed, create `app/policies/menu_version_policy.rb`.

4. **`SCHEMA_VERSION = 1`** — future changes to the snapshot schema should increment this constant and add a migration path. Menu Experiments v1 should hardcode awareness that it is reading schema version 1 snapshots.

---

## Out of Scope (Already Decided)

- Automatic version creation on every menu save — versions are created explicitly by the restaurant owner
- Binary/patch-style delta storage — full JSON snapshots are used (simpler, more resilient to schema changes)
- Version retention limits or archiving — no maximum version count enforced

---

## Impact on Priority Index

The discovery that MenuVersion is fully built removes the hard dependency blocker from Menu Experiments (#14). See `PRIORITY_INDEX.md` for updated ranking.
