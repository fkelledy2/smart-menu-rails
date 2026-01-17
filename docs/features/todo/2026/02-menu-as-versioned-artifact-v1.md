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

- [ ] Decide storage strategy: JSON snapshot vs versioned tables
- [ ] Add `menu_versions` model/table
- [ ] Implement “Create Version” action from current menu
- [ ] Implement “Activate Version” (manual)
- [ ] Implement activation window fields (`starts_at`, `ends_at`)
- [ ] Implement version selection logic in smart menu rendering
- [ ] Implement `MenuVersionDiffService`
- [ ] Add admin/staff UI for:
  - [ ] list versions
  - [ ] diff view
  - [ ] activate/schedule activation
- [ ] Add tests for snapshot integrity + activation logic
