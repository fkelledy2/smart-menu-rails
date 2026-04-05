---
name: AgentWorkbench preview projection section_reorder wrong ID space
description: build_preview_projection used section_reorder target_id (menusection ID) to look up item_map (keyed by menuitem ID) — section reorder changes never shown in preview (FIXED)
type: project
---

`section_reorder` actions have `target_id` = menusection ID, but `item_map` is keyed by menuitem ID. The preview silently skipped all section reorder actions.

**Fix:** Added `section_sequence_overrides` hash, keyed by menusection ID. After processing actions, applied overrides to all items belonging to the affected sections and sorted by projected `section_sequence`.

**How to apply:** Whenever a preview projection handles heterogeneous action types (some target items, some target sections), use separate lookup maps for each entity type.
