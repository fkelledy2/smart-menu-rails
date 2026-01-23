# Menu as Versioned Artifact (v1)

## Purpose
Make the menu **auditable, immutable-by-version, and explicitly activatable**.

This creates a moat: menus become “software” with:

- Immutable versions
- Diffs between versions
- Activation windows (time-based; A/B optional later)

## Current State (today)

- Menus/sections/items are persisted as mutable records (`Menu`, `Menusection`, `Menuitem`).
- Sorting and time-window restrictions exist.
- Localization exists (menu/section/item locale tables).
- OCR import exists.

Gaps:

- No immutable `MenuVersion` concept.
- No diffs, no audit history of *what changed and when*.
- No activation windows.

Cross references:

- `docs/features/done/MENU_SORTING_IMPLEMENTATION.md`
- `docs/features/done/MENU_TIME_RESTRICTIONS.md`

## Scope (v1)

- Introduce `MenuVersion` (immutable snapshot).
- Allow creating a new version from current menu state.
- Allow activating a specific version, optionally with a time window.
- Provide diff capability between any two versions.

## Non-goals (v1)

- AI insights or auto-optimization.
- Automatic rollout suggestions.
- Multi-restaurant shared version graphs.

## Conceptual Model

- `Menu` remains the logical container.
- `MenuVersion` is a frozen snapshot of:
  - menu metadata
  - sections
  - items
  - relevant fields (including prep time, allergens metadata references, margin hints)

Approach options:

- **Snapshot JSON** (fastest to ship): store a canonical JSON document per version.
- **Versioned tables** (more relational): `menu_versions`, `menu_section_versions`, `menu_item_versions`.

## Acceptance Criteria (GIVEN / WHEN / THEN)

### Version creation

- GIVEN a menu with sections and items
  WHEN a user creates a new menu version
  THEN a `MenuVersion` is created containing an immutable snapshot of all sections/items and menu metadata.

- GIVEN an existing `MenuVersion`
  WHEN a user attempts to edit it
  THEN the system prevents mutation (read-only).

### Diffing

- GIVEN two menu versions A and B
  WHEN the diff is requested
  THEN the system returns a deterministic diff describing:
  - added/removed sections
  - added/removed items
  - changed fields (name/price/description/availability metadata)

### Activation windows

- GIVEN a menu version with an activation window
  WHEN the current time is within the window
  THEN the smart menu displays that version.

- GIVEN a menu version with an activation window
  WHEN the current time is outside the window
  THEN the smart menu displays the default active version.

## Progress Checklist


### 0) Decisions (lock these in first)

- [ ] Decide storage strategy
  - [ ] Snapshot JSON (`menu_versions.snapshot_json`) (fastest to ship)
  - [ ] Versioned tables (`menu_versions`, `menu_section_versions`, `menu_item_versions`) (more relational)
- [ ] Decide what fields are in-scope for snapshot/diff (v1)
  - [ ] menu fields
  - [ ] section fields
  - [ ] item fields
  - [ ] locale fields (include vs exclude)
- [ ] Decide how version selection interacts with existing availability/time restrictions

### 1) Data model + migrations

- [ ] Add `menu_versions` table/model
  - [ ] `menu_id` (FK)
  - [ ] `version_number` (per-menu increment)
  - [ ] `snapshot_json` (if JSON strategy)
  - [ ] `created_by_user_id` (optional)
  - [ ] activation fields: `is_active`, `starts_at`, `ends_at`
  - [ ] indexes for `menu_id`, `(menu_id, version_number)` unique, activation queries
- [ ] Add model validations + immutability constraints (v1)
  - [ ] prevent updates to snapshot once created (application-level)
  - [ ] allow toggling activation fields only (if needed)

### 2) Snapshot creation (from current menu)

- [ ] Implement `MenuVersionSnapshotService`
  - [ ] deterministic serialization (stable sort order for sections/items)
  - [ ] include required menu/section/item fields
  - [ ] exclude transient/derived fields (timestamps, counters)
- [ ] Implement `MenuVersion.create_from_menu!(menu:, user:)`
  - [ ] allocate `version_number` with per-menu lock
  - [ ] persist snapshot

### 3) Activation (manual + optional window)

- [ ] Implement activation rules (v1)
  - [ ] “manual active” (one active version per menu)
  - [ ] optional windowed activation (`starts_at`, `ends_at`)
  - [ ] conflict resolution rules when multiple windows overlap
- [ ] Implement `MenuVersionActivationService`
  - [ ] activate version now
  - [ ] schedule activation window
  - [ ] deactivate other versions as needed

### 4) Version selection in smart menu rendering

- [ ] Implement `Menu#active_menu_version(at: Time.current)`
- [ ] Wire smartmenu rendering to use active version snapshot when present
  - [ ] ensure existing ordering + time restrictions still apply correctly
  - [ ] fallback to current mutable tables when no versions exist

### 5) Diffing

- [ ] Implement `MenuVersionDiffService`
  - [ ] deterministic diff output
  - [ ] added/removed sections
  - [ ] added/removed items
  - [ ] changed fields (name/price/description/availability metadata)
- [ ] Add a JSON endpoint to fetch diff
  - [ ] `GET /restaurants/:restaurant_id/menus/:menu_id/versions/:a_id/diff/:b_id`

### 6) UI (staff/admin)

- [ ] Versions list page (menu-level)
  - [ ] show version number, created_at, created_by, active/window info
- [ ] “Create Version” action/button
- [ ] “Activate Version” action/button
- [ ] “Schedule Activation Window” UI
- [ ] Diff view UI (A vs B)

### 7) Authorization + auditing

- [ ] Pundit policy updates
  - [ ] who can create versions
  - [ ] who can activate/schedule
  - [ ] who can view diffs
- [ ] Basic auditing fields in snapshot metadata (created_by, created_at)

### 8) Tests

- [ ] Snapshot integrity
  - [ ] snapshot includes all sections/items deterministically
  - [ ] snapshot is stable across repeated runs (same input => same JSON)
- [ ] Activation selection
  - [ ] window selects correct version in-window
  - [ ] fallback to default active version out-of-window
- [ ] Diff service
  - [ ] detects add/remove/change correctly
